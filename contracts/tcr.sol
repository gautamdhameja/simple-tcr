// Most of the code in this contract is derived from the generic TCR implementation from Mike Goldin and (the adChain) team
// This contract strips out most of the details and only keeps the basic TCR functionality (apply/propose, challenge, vote, resolve)
// Consider this to be the "hello world" for TCR implementation
// For real world usage, please refer to the generic TCR implementation
// https://github.com/skmgoldin/tcr

pragma solidity ^0.5.8;
pragma experimental ABIEncoderV2;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract Tcr {

    using SafeMath for uint;

    struct Listing {
        uint applicationExpiry; // Expiration date of apply stage
        bool whitelisted;       // Indicates registry status
        address owner;          // Owner of Listing
        uint deposit;           // Number of tokens in the listing
        uint challengeId;       // the challenge id of the current challenge
        string data;            // name of listing (for UI)
        uint arrIndex;          // arrayIndex of listing in listingNames array (for deletion)
    }

    // instead of using the elegant PLCR voting, we are using just a list because this is *simple-TCR*
    struct Vote {
        bool value;
        uint stake;
        bool claimed;
    }

    struct Poll {
        uint votesFor;
        uint votesAgainst;
        uint commitEndDate;
        bool passed;
        mapping(address => Vote) votes; // revealed by default; no partial locking
    }

    struct Challenge {
        address challenger;     // Owner of Challenge
        bool resolved;          // Indication of if challenge is resolved
        uint stake;             // Number of tokens at stake for either party during challenge
        uint rewardPool;        // number of tokens from losing side - winning reward
        uint totalTokens;       // number of tokens from winning side - to be returned
    }

    // Maps challengeIDs to associated challenge data
    mapping(uint => Challenge) private challenges;

    // Maps listingHashes to associated listingHash data
    mapping(bytes32 => Listing) private listings;
    string[] public listingNames;

    // Maps polls to associated challenge
    mapping(uint => Poll) private polls;

    // Global Variables
    ERC20 public token;
    string public name;
    uint public minDeposit;
    uint public applyStageLen;
    uint public commitStageLen;

    uint constant private INITIAL_POLL_NONCE = 0;
    uint public pollNonce;

    // Events
    event _Application(bytes32 indexed listingHash, uint deposit, string data, address indexed applicant);
    event _Challenge(bytes32 indexed listingHash, uint challengeId, address indexed challenger);
    event _Vote(bytes32 indexed listingHash, uint challengeId, address indexed voter);
    event _ResolveChallenge(bytes32 indexed listingHash, uint challengeId, address indexed resolver);
    event _RewardClaimed(uint indexed challengeId, uint reward, address indexed voter);

    // using the constructor to initialize the TCR parameters
    // again, to keep it simple, skipping the Parameterizer and ParameterizerFactory
    constructor(
        string memory _name,
        address _token,
        uint[] memory _parameters
    ) public {
        require(_token != address(0), "Token address should not be 0 address.");

        token = ERC20(_token);
        name = _name;

        // minimum deposit for listing to be whitelisted
        minDeposit = _parameters[0];

        // period over which applicants wait to be whitelisted
        applyStageLen = _parameters[1];

        // length of commit period for voting
        commitStageLen = _parameters[2];

        // Initialize the poll nonce
        pollNonce = INITIAL_POLL_NONCE;
    }

    // returns whether a listing is already whitelisted
    function isWhitelisted(bytes32 _listingHash) public view returns (bool whitelisted) {
        return listings[_listingHash].whitelisted;
    }

    // returns if a listing is in apply stage
    function appWasMade(bytes32 _listingHash) public view returns (bool exists) {
        return listings[_listingHash].applicationExpiry > 0;
    }

    // get all listing names (for UI)
    // not to be used in a production use case
    function getAllListings() public view returns (string[] memory) {
        string[] memory listingArr = new string[](listingNames.length);
        for (uint256 i = 0; i < listingNames.length; i++) {
            listingArr[i] = listingNames[i];
        }
        return listingArr;
    }

    // get details of this registry (for UI)
    function getDetails() public view returns (string memory, address, uint, uint, uint) {
        string memory _name = name;
        return (_name, address(token), minDeposit, applyStageLen, commitStageLen);
    }

    // get details of a listing (for UI)
    function getListingDetails(bytes32 _listingHash) public view returns (bool, address, uint, uint, string memory) {
        Listing memory listingIns = listings[_listingHash];

        // Listing must be in apply stage or already on the whitelist
        require(appWasMade(_listingHash) || listingIns.whitelisted, "Listing does not exist.");

        return (listingIns.whitelisted, listingIns.owner, listingIns.deposit, listingIns.challengeId, listingIns.data);
    }

    // proposes a listing to be whitelisted
    function propose(bytes32 _listingHash, uint _amount, string calldata _data) external {
        require(!isWhitelisted(_listingHash), "Listing is already whitelisted.");
        require(!appWasMade(_listingHash), "Listing is already in apply stage.");
        require(_amount >= minDeposit, "Not enough stake for application.");

        // Sets owner
        Listing storage listing = listings[_listingHash];
        listing.owner = msg.sender;
        listing.data = _data;
        listingNames.push(listing.data);
        listing.arrIndex = listingNames.length - 1;

        // Sets apply stage end time
        // now or block.timestamp is safe here (can live with ~15 sec approximation)
        /* solium-disable-next-line security/no-block-members */
        listing.applicationExpiry = now.add(applyStageLen);
        listing.deposit = _amount;

        // Transfer tokens from user
        require(token.transferFrom(listing.owner, address(this), _amount), "Token transfer failed.");

        emit _Application(_listingHash, _amount, _data, msg.sender);
    }

    // challenges a listing from being whitelisted
    function challenge(bytes32 _listingHash, uint _amount)
        external returns (uint challengeId) {
        Listing storage listing = listings[_listingHash];

        // Listing must be in apply stage or already on the whitelist
        require(appWasMade(_listingHash) || listing.whitelisted, "Listing does not exist.");
        
        // Prevent multiple challenges
        require(listing.challengeId == 0 || challenges[listing.challengeId].resolved, "Listing is already challenged.");

        // check if apply stage is active
        /* solium-disable-next-line security/no-block-members */
        require(listing.applicationExpiry > now, "Apply stage has passed.");

        // check if enough amount is staked for challenge
        require(_amount >= listing.deposit, "Not enough stake passed for challenge.");
        
        pollNonce = pollNonce + 1;
        challenges[pollNonce] = Challenge({
            challenger: msg.sender,
            stake: _amount,
            resolved: false,
            totalTokens: 0,
            rewardPool: 0
        });

        // create a new poll for the challenge
        polls[pollNonce] = Poll({
            votesFor: 0,
            votesAgainst: 0,
            passed: false,
            commitEndDate: now.add(commitStageLen) /* solium-disable-line security/no-block-members */
        });

        // Updates listingHash to store most recent challenge
        listing.challengeId = pollNonce;

        // Transfer tokens from challenger
        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed.");

        emit _Challenge(_listingHash, pollNonce, msg.sender);
        return pollNonce;
    }

    // commits a vote for/against a listing
    // plcr voting is not being used here
    // to keep it simple, we just store the choice as a bool - true is for and false is against
    function vote(bytes32 _listingHash, uint _amount, bool _choice) public {
        Listing storage listing = listings[_listingHash];

        // Listing must be in apply stage or already on the whitelist
        require(appWasMade(_listingHash) || listing.whitelisted, "Listing does not exist.");

        // Check if listing is challenged
        require(listing.challengeId > 0 && !challenges[listing.challengeId].resolved, "Listing is not challenged.");

        Poll storage poll = polls[listing.challengeId];

        // check if commit stage is active
        /* solium-disable-next-line security/no-block-members */
        require(poll.commitEndDate > now, "Commit period has passed.");

        // Transfer tokens from voter
        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed.");

        if(_choice) {
            poll.votesFor += _amount;
        } else {
            poll.votesAgainst += _amount;
        }

        // TODO: fix vote override when same person is voing again
        poll.votes[msg.sender] = Vote({
            value: _choice,
            stake: _amount,
            claimed: false
        });

        emit _Vote(_listingHash, listing.challengeId, msg.sender);
    }

    // check if the listing can be whitelisted
    function canBeWhitelisted(bytes32 _listingHash) public view returns (bool) {
        uint challengeId = listings[_listingHash].challengeId;

        // Ensures that the application was made,
        // the application period has ended,
        // the listingHash can be whitelisted,
        // and either: the challengeId == 0, or the challenge has been resolved.
        /* solium-disable */
        if (appWasMade(_listingHash) && 
            listings[_listingHash].applicationExpiry < now && 
            !isWhitelisted(_listingHash) &&
            (challengeId == 0 || challenges[challengeId].resolved == true)) {
            return true; 
        }

        return false;
    }

    // updates the status of a listing
    function updateStatus(bytes32 _listingHash) public {
        if (canBeWhitelisted(_listingHash)) {
            listings[_listingHash].whitelisted = true;
        } else {
            resolveChallenge(_listingHash);
        }
    }

    // ends a poll and returns if the poll passed or not
    function endPoll(uint challengeId) private returns (bool didPass) {
        require(polls[challengeId].commitEndDate > 0, "Poll does not exist.");
        Poll storage poll = polls[challengeId];

        // check if commit stage is active
        /* solium-disable-next-line security/no-block-members */
        require(poll.commitEndDate < now, "Commit period is active.");

        if (poll.votesFor >= poll.votesAgainst) {
            poll.passed = true;
        } else {
            poll.passed = false;
        }

        return poll.passed;
    }

    // resolves a challenge and calculates rewards
    function resolveChallenge(bytes32 _listingHash) private {
        // Check if listing is challenged
        Listing memory listing = listings[_listingHash];
        require(listing.challengeId > 0 && !challenges[listing.challengeId].resolved, "Listing is not challenged.");

        uint challengeId = listing.challengeId;

        // end the poll
        bool pollPassed = endPoll(challengeId);

        // updated challenge status
        challenges[challengeId].resolved = true;

        address challenger = challenges[challengeId].challenger;

        // Case: challenge failed
        if (pollPassed) {
            challenges[challengeId].totalTokens = polls[challengeId].votesFor;
            challenges[challengeId].rewardPool = challenges[challengeId].stake + polls[challengeId].votesAgainst;
            listings[_listingHash].whitelisted = true;
        } else { // Case: challenge succeeded
            // give back the challenge stake to the challenger
            require(token.transfer(challenger, challenges[challengeId].stake), "Challenge stake return failed.");
            challenges[challengeId].totalTokens = polls[challengeId].votesAgainst;
            challenges[challengeId].rewardPool = listing.deposit + polls[challengeId].votesFor;
            delete listings[_listingHash];
            delete listingNames[listing.arrIndex];
        }

        emit _ResolveChallenge(_listingHash, challengeId, msg.sender);
    }

    // claim rewards for a vote
    function claimRewards(uint challengeId) public {
        // check if challenge is resolved
        require(challenges[challengeId].resolved == true, "Challenge is not resolved.");
        
        Poll storage poll = polls[challengeId];
        Vote storage voteInstance = poll.votes[msg.sender];
        
        // check if vote reward is already claimed
        require(voteInstance.claimed == false, "Vote reward is already claimed.");

        // if winning party, calculate reward and transfer
        if((poll.passed && voteInstance.value) || (!poll.passed && !voteInstance.value)) {
            uint reward = (challenges[challengeId].rewardPool.div(challenges[challengeId].totalTokens)).mul(voteInstance.stake);
            uint total = voteInstance.stake.add(reward);
            require(token.transfer(msg.sender, total), "Voting reward transfer failed.");
            emit _RewardClaimed(challengeId, total, msg.sender);
        }

        voteInstance.claimed = true;
    }
}
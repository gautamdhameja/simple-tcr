// Most of the code in thic contract is derived from the generic TCR implementation from Mike Goldin
// This contract strips out most of the details and only keeps the basic TCR functionality
// Consider this to be the "hello world" for TCR implementation
// For real world usage, please refer to the generic TCR implementation
// https://github.com/skmgoldin/tcr

pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract Tcr {

    using SafeMath for uint;

    struct Listing {
        uint applicationExpiry; // Expiration date of apply stage
        bool whitelisted;       // Indicates registry status
        address owner;          // Owner of Listing
        uint unstakedDeposit;   // Number of tokens in the listing not locked in a challenge
        uint challengeId;       // the challenge id of the current challenge
    }

    // instead of using the elegant PLCR voting, we are using just a list because this is *simple-TCR*
    struct Vote {
        uint pollId;
        bool voteValue;
        uint stake;
        bool claimed;
    }
    
    struct Poll {
        uint challengeId;
        uint votesFor;
        uint votesAgainst;
        uint commitEndDate;
        mapping(address => Vote) votes; // revealed by default; no partial locking
    }

    struct Challenge {
        bytes32 listingHash;    // hash of the listing being challenged
        address challenger;     // Owner of Challenge
        bool resolved;          // Indication of if challenge is resolved
        uint stake;             // Number of tokens at stake for either party during challenge
    }

    // Maps challengeIDs to associated challenge data
    mapping(uint => Challenge) public challenges;

    // Maps listingHashes to associated listingHash data
    mapping(bytes32 => Listing) public listings;

    // Maps polls to associated challenge
    mapping(uint => Poll) public polls;

    // Global Variables
    ERC20 public token;
    string public name;
    uint minDeposit;
    uint applyStageLen;
    uint commitStageLen;

    uint constant public INITIAL_POLL_NONCE = 0;
    uint public pollNonce;

    // Events
    event _Application(bytes32 indexed listingHash, uint deposit, string data, address indexed applicant);
    event _Challenge(bytes32 indexed listingHash, uint challengeID, address indexed challenger);
    event _Vote(bytes32 indexed listingHash, uint challengeID, address indexed voter);
    event _ResolveChallenge(bytes32 indexed listingHash, uint challengeID, address indexed resolver);
    event _RewardClaimed(uint indexed challengeID, uint reward, address indexed voter);

    // using the constructor to initialize the TCR parameters
    // again, to make it simple, skipping the Parameterizer and ParameterizerFactory
    constructor(
        string _name,
        address _token,
        uint[] _parameters
    ) public {
        require(_token != 0 && address(token) == 0, "Token address should not be 0 address.");

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

    // propose a listing to be whitelisted
    function apply(bytes32 _listingHash, uint _amount, string _data) external {
        require(!isWhitelisted(_listingHash), "Listing is already whitelisted.");
        require(!appWasMade(_listingHash), "Listing is already in apply stage.");
        require(_amount >= minDeposit, "Not enough stake for application.");

        // Sets owner
        Listing storage listing = listings[_listingHash];
        listing.owner = msg.sender;

        // Sets apply stage end time
        // now or block.timestamp is safe here (can live with ~15 sec approximation)
        /* solium-disable-next-line security/no-block-members */
        listing.applicationExpiry = now.add(applyStageLen);
        listing.unstakedDeposit = _amount;

        // Transfers tokens from user to Registry contract
        require(token.transferFrom(listing.owner, this, _amount), "Token transfer failed.");

        emit _Application(_listingHash, _amount, _data, msg.sender);
    }

    // challenge a listing from being whitelisted
    function challenge(bytes32 _listingHash, uint _amount) 
        external returns (uint challengeId) {
        Listing storage listing = listings[_listingHash];

        // Listing must be in apply stage or already on the whitelist
        require(appWasMade(_listingHash) || listing.whitelisted, "Listing does not exist.");
        
        // Prevent multiple challenges
        require(listing.challengeId == 0 || challenges[listing.challengeId].resolved, "Listing is already challenged.");

        pollNonce = pollNonce + 1;
        challenges[pollNonce] = Challenge({
            listingHash: _listingHash,
            challenger: msg.sender,
            stake: _amount,
            resolved: false
        });

        polls[pollNonce] = Poll({
            challengeId: pollNonce,
            votesFor: 0,
            votesAgainst: 0,
            commitEndDate: now.add(commitStageLen) /* solium-disable-line security/no-block-members */
        });

        // Updates listingHash to store most recent challenge
        listing.challengeId = pollNonce;

        // Takes tokens from challenger
        require(token.transferFrom(msg.sender, this, minDeposit), "Token transfer failed.");

        emit _Challenge(_listingHash, pollNonce, msg.sender);
        return pollNonce;
    }

    function vote() public {
        // TODO
    }

    function resolve() public {
        // TODO
    }
}
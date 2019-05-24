var tcr = artifacts.require("Tcr");
var token = artifacts.require("Token");

async function increaseTime(duration) {
    const id = Date.now()
    return new Promise((resolve, reject) => {
        web3.currentProvider.send({
            jsonrpc: '2.0',
            method: 'evm_increaseTime',
            params: [duration],
            id: id,
        }, err1 => {
            if (err1) return reject(err1)

            web3.currentProvider.send({
                jsonrpc: '2.0',
                method: 'evm_mine',
                id: id + 1,
            }, (err2, res) => {
                return err2 ? reject(err2) : resolve(res)
            })
        })
    })
}

contract('Tcr', async function (accounts) {
    let tcrInstance;
    let tokenInstance;
    before(async () => {
        tcrInstance = await tcr.deployed();
        const tokenAddress = await tcrInstance.token();
        tokenInstance = await token.at(tokenAddress);
    });

    it("should init name", async function () {
        const name = await tcrInstance.name();
        assert.equal(name, "DemoTcr", "name didnt initialize");
    });

    it("should init token", async function () {
        const name = await tokenInstance.name();
        assert.equal(name, "DemoToken", "token name didnt initialize");
    });

    it("should init minDeposit", async function () {
        const minDeposit = await tcrInstance.minDeposit();
        assert.equal(minDeposit, 100, "minDeposit didnt initialize");
    });

    it("should init commitStageLen", async function () {
        const commitStageLen = await tcrInstance.commitStageLen();
        assert.equal(commitStageLen, 60, "commitStageLen didnt initialize");
    });

    const listingName = "DemoListing";

    it("should apply", async function () {
        await tokenInstance.approve(tcrInstance.address, 100, {
            from: accounts[0]
        });
        const applyListing = await tcrInstance.propose(web3.utils.fromAscii(listingName), 100, listingName, {
            from: accounts[0]
        });
        assert.equal(applyListing.logs[0].event, "_Application", "apply listing failed");
    });

    it("should challenge", async function () {
        await tokenInstance.transfer(accounts[1], 100000, {
            from: accounts[0]
        });
        await tokenInstance.approve(tcrInstance.address, 100, {
            from: accounts[1]
        });
        const challengeListing = await tcrInstance.challenge(web3.utils.fromAscii(listingName), 100, {
            from: accounts[1]
        });

        assert.equal(challengeListing.logs[0].event, "_Challenge", "challenge listing failed");
    });

    it("should fail challenge", async function () {
        await tokenInstance.transfer(accounts[3], 100000, {
            from: accounts[0]
        });
        await tokenInstance.approve(tcrInstance.address, 100, {
            from: accounts[3]
        });
        try {
            await tcrInstance.challenge(web3.utils.fromAscii("abcd"), 100, {
                from: accounts[3]
            });
        } catch (err) {
            assert(err.message.includes("Listing does not exist."), "challenge should have failed");
        }
    });

    it("should vote", async function () {
        await tokenInstance.transfer(accounts[2], 100000, {
            from: accounts[0]
        });
        await tokenInstance.approve(tcrInstance.address, 10, {
            from: accounts[2]
        });
        const voteAcc2 = await tcrInstance.vote(web3.utils.fromAscii(listingName), 10, true, {
            from: accounts[2]
        });

        await tokenInstance.approve(tcrInstance.address, 5, {
            from: accounts[1]
        });
        const voteAcc1 = await tcrInstance.vote(web3.utils.fromAscii(listingName), 5, false, {
            from: accounts[1]
        });

        assert.equal(voteAcc2.logs[0].event, "_Vote", "vote failed");
        assert.equal(voteAcc1.logs[0].event, "_Vote", "vote failed");
    });

    it("should update listing status", async function () {
        await increaseTime(100);
        const resolveListing = await tcrInstance.updateStatus(web3.utils.fromAscii(listingName));
        assert.equal(resolveListing.logs[0].event, "_ResolveChallenge", "update status failed");
        const isWhitelisted = await tcrInstance.isWhitelisted(web3.utils.fromAscii(listingName));
        assert.equal(isWhitelisted, true, "whitelisting failed");
    });

    let challengeId;
    it("should get listing details", async function () {
        const listingDetails = await tcrInstance.getListingDetails(web3.utils.fromAscii(listingName));
        challengeId = listingDetails[3].toNumber();
        assert.equal(listingDetails[4], listingName, "listing details don't match");
    });

    it("should claim rewards for winner", async function () {
        const claimRewards = await tcrInstance.claimRewards(challengeId, {
            from: accounts[2]
        });
        assert.equal(claimRewards.logs[0].event, "_RewardClaimed", "claim rewards failed");

        const balanceAcc2 = await tokenInstance.balanceOf(accounts[2]);
        assert.isAbove(balanceAcc2.toNumber(), 100000, "winning voter should have more balance than before");
    });

    it("should claim rewards for loser", async function () {
        await tcrInstance.claimRewards(challengeId, {
            from: accounts[1]
        });
        const balanceAcc1 = await tokenInstance.balanceOf(accounts[1]);
        assert.isBelow(balanceAcc1.toNumber(), 100000, "losing voter should have less balance than before");
    });
});
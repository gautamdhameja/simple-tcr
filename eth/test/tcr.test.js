var tcr = artifacts.require("./tcr.sol");
var token = artifacts.require("./token.sol");

contract('Tcr', async function (accounts) {
    let tcrInstance;
    let tokenInstance;
    beforeEach(async () => {
        tcrInstance = await tcr.deployed();
        const tokenAddress = await tcrInstance.token();
        tokenInstance = await token.at(tokenAddress);
    });

    it("should init name", async function () {
        const name = await tcrInstance.name();
        assert.equal(name, "demotcr", "name didnt initialize");
    });

    it("should init token", async function () {
        const name = await tokenInstance.name();
        assert.equal(name, "DemoToken", "name didnt initialize");
    });

    it("should init minDeposit", async function () {
        const minDeposit = await tcrInstance.minDeposit();
        assert.equal(minDeposit, 100, "minDeposit didnt initialize");
    });

    it("should init commitStageLen", async function () {
        const commitStageLen = await tcrInstance.commitStageLen();
        assert.equal(commitStageLen, 60, "commitStageLen didnt initialize");
    });

    it("should apply", async function () {
        const name = "DemoListing";
        await tokenInstance.approve(tcrInstance.address, 100, { from: accounts[0] });
        const applyListing = await tcrInstance.apply(web3.fromAscii(name), 100, name, { from: accounts[0] });
        assert.equal(applyListing.logs[0].event, "_Application", "apply listing failed");
    });

    it("should challenge", async function () {
        const name = "DemoListing1";

        // step 1 - apply
        await tokenInstance.approve(tcrInstance.address, 100, { from: accounts[0] });
        await tcrInstance.apply(web3.fromAscii(name), 100, name, { from: accounts[0] });

        // step 2 - challenge
        await tokenInstance.transfer(accounts[1], 100000, { from: accounts[0] });
        await tokenInstance.approve(tcrInstance.address, 100, { from: accounts[1] });
        const challengeListing = await tcrInstance.challenge(web3.fromAscii(name), 100, { from: accounts[1] });
        
        assert.equal(challengeListing.logs[0].event, "_Challenge", "challenge listing failed");
    });
});
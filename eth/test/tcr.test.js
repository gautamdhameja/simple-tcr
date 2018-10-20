var tcr = artifacts.require("./tcr.sol");

contract('Tcr', async function () {
    let tcrInstance;
    beforeEach(async () => {
        tcrInstance = await tcr.deployed();
    });

    it("should init name", async function () {
        const name = await tcrInstance.name();
        assert.equal(name, "demotcr", "name didnt initialize");
    });

    it("should init minDeposit", async function () {
        const minDeposit = await tcrInstance.minDeposit();
        assert.equal(minDeposit, 100, "minDeposit didnt initialize");
    });

    it("should init commitStageLen", async function () {
        const commitStageLen = await tcrInstance.commitStageLen();
        assert.equal(commitStageLen, 60, "commitStageLen didnt initialize");
    });
});
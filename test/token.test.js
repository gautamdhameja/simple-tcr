var token = artifacts.require("Token");

contract('Token', async function (accounts) {
    let tokenInstance;
    before(async () => {
        tokenInstance = await token.deployed();
    });

    it("should init", async function () {
        const name = await tokenInstance.name();
        assert.equal(name, "DemoToken", "name didnt initialize");
    });

    it("should get total supply", async function () {
        const totalSupply = await tokenInstance.totalSupply();
        assert.equal(totalSupply, 21000000, "couldn't get total supply");
    });

    it("should approve", async function () {
        await tokenInstance.approve(accounts[1], 100000, { from: accounts[0] });
        const allowance = await tokenInstance.allowance(accounts[0], accounts[1]);
        assert.equal(allowance, 100000, "couldn't get balance");
    });
});
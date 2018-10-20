var tcr = artifacts.require("./tcr.sol");

contract('Tcr', function (accounts) {
    it("should init name", function () {
        return tcr.deployed().then(function (instance) {
            return instance.name();
        }).then(function(result){
            assert.equal(result, "demotcr", "name didnt initialize");
        });
    });

    it("should init minDeposit", function () {
        return tcr.deployed().then(function (instance) {
            return instance.minDeposit();
        }).then(function(result){
            assert.equal(result, 100, "minDeposit didnt initialize");
        });
    });

    it("should init commitStageLen", function () {
        return tcr.deployed().then(function (instance) {
            return instance.commitStageLen();
        }).then(function(result){
            assert.equal(result, 60, "commitStageLen didnt initialize");
        });
    });
});
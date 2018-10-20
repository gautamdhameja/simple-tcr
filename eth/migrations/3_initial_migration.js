var tcr = artifacts.require("./tcr.sol");
var token = artifacts.require("./token.sol");

module.exports = function(deployer) {
  deployer.deploy(tcr, "demotcr", token.address, [100, 60, 60]);
};

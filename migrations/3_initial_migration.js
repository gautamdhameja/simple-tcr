var tcr = artifacts.require("Tcr");
var token = artifacts.require("Token");

module.exports = function(deployer) {
  deployer.deploy(tcr, "DemoTcr", token.address, [100, 60, 60]);
};

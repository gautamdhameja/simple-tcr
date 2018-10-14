var token = artifacts.require("./token.sol");

module.exports = function(deployer) {
  deployer.deploy(token);
};

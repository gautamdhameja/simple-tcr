var token = artifacts.require("Token");

module.exports = function(deployer) {
  deployer.deploy(token);
};

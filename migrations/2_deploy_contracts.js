// var ConvertLib = artifacts.require("./ConvertLib.sol");
var Committee = artifacts.require("./Committee.sol");

module.exports = function(deployer) {
  // deployer.deploy(ConvertLib);
  // deployer.link(ConvertLib, MetaCoin);
  deployer.deploy(Committee);
};

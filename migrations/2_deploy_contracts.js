var Base = artifacts.require("./Base.sol");
var Committee = artifacts.require("./Committee.sol");
var Ballot = artifacts.require("./Ballot.sol");

module.exports = function(deployer) {
  // deployer.deploy(ConvertLib);
  // deployer.link(ConvertLib, MetaCoin);
  deployer.deploy(Base);
  deployer.deploy(Committee);
  deployer.deploy(Ballot);
};

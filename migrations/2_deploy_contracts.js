const Land = artifacts.require("Land");
const LandFactory = artifacts.require("LandFactory");
const LandLootBox = artifacts.require("LandLootBox");

module.exports = function(deployer) {
  deployer.deploy(Land);
  // deployer.link(ConvertLib, MetaCoin);
  // deployer.deploy(LandFactory);
  // deployer.deploy(LandLootBox);
};

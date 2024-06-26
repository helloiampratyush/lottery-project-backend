const { network } = require("hardhat");
const { verify } = require("../utils/verify");

module.exports = async ({ deployments, getNamedAccounts }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const subscriptionId=2506;
  const args=[subscriptionId];
  const contractName = await deploy("RandomLottery", {
    from: deployer,
    log: true,
    args: args,
    waitConfirmations: network.config.blockConfirmations || 1,
  });
  console.log("deployments done");
  const chainId =network.config.chainId;
  if (chainId != 31337) {
    console.log("here we are going to verify");
    await verify(contractName.address, [subscriptionId]);
  }
};
module.exports.tags = ["all", "nftMarketPlace"];
const { ethers, network } = require("hardhat");

const timeinterval=15400;
const entranceFee=ethers.utils.parseEther("0.1");
const minplayers=4;
async function announceMent(){
    const mainContract=await ethers.getContract("RandomLottery");
   const tx=await mainContract.lotteryStart(timeinterval,entranceFee,minplayers);
   await tx.wait(1);
console.log("lottery Announced")

}

announceMent()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
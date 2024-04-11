const {ethers}=require("hardhat");
const counter=6;

async function lotteryWinnerAnnounced(){
const mainContract=await ethers.getContract("RandomLottery");
const lotteryThings=await mainContract.makeThingsWinner(counter);
await lotteryThings.wait(1);
console.log("lottery proceeded")
}
lotteryWinnerAnnounced()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
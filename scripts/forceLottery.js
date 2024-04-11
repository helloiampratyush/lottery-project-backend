const {ethers,network}=require("hardhat");

const counter=3;

async function setStatusInActive(){
    const mainContract=await ethers.getContract("RandomLottery");
    const request1=await mainContract.forceLotteryClosed(counter);
    await request1.wait(1);
    console.log("lottery UnActivated");

}
setStatusInActive()
.then(()=>process.exit(0))
 .catch((error)=>
 {console.log(error);
      process.exit(1);
 }
    )

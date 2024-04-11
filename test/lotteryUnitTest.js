const {getNamedAccounts,deployments,ethers, network}=require("hardhat");
const{assert,expect}=require("chai");


describe("ContractTest", function () {
    let deployer, mainContract;
  
    beforeEach(async function () {
      deployer = (await getNamedAccounts()).deployer;
      const prob = await deployments.fixture(["all"]);
      
      mainContract = await ethers.getContract("RandomLottery", deployer);
      
    });
    describe("start lottery",function(){
        const entaranceFee=ethers.utils.parseEther("0.01");
        const minPlayer=3;
        const timeInterval=800;
        it("will check fee same",async function(){
    const accounts = await ethers.getSigners();
    const account2ConnectedContract = await mainContract.connect(accounts[2]);

     await expect (account2ConnectedContract.lotteryStart(timeInterval,entaranceFee,minPlayer)).to.be.revertedWith("lottery__notOwner");

     await expect( mainContract.lotteryStart(timeInterval,entaranceFee,minPlayer)).to.emit(mainContract,"lotteryAnnounceMent");
             
         
        })
    it("it will check and let join particiants to lottery",async function(){
        const accounts = await ethers.getSigners();
        const lotteryStart=await mainContract.lotteryStart(timeInterval,entaranceFee,minPlayer);
        await lotteryStart.wait(1);
        const feeToPaid=ethers.utils.parseEther("0.01");
        mainContract.enterLottery(1,{value:feeToPaid});
        const p1Contract=await mainContract.connect(accounts[1]);
        p1Contract.enterLottery(1,{value:feeToPaid});
        const remainingminPlayer=await mainContract.minplayerRequiredToJoin(1);
        assert.equal("1",remainingminPlayer.toString());
        const p2Contract=await mainContract.connect(accounts[2]);
        p2Contract.enterLottery(1,{value:feeToPaid});
        const p3Contract=await mainContract.connect(accounts[3]);
        p3Contract.enterLottery(1,{value:feeToPaid});
 const var1= await mainContract.checkThings(1);
 assert.equal("false",var1.toString());
 
    })
    
        it("it will allot winner", async function() {
            const accounts = await ethers.getSigners();
            const lotteryStart = await mainContract.lotteryStart(timeInterval, entaranceFee, minPlayer);
            await lotteryStart.wait(1);
        
            const feeToPaid = ethers.utils.parseEther("0.01");
            await mainContract.enterLottery(1, {value: feeToPaid});
            const p1Contract = await mainContract.connect(accounts[1]);
            await p1Contract.enterLottery(1, {value: feeToPaid});
            const p2Contract = await mainContract.connect(accounts[2]);
            await p2Contract.enterLottery(1, {value: feeToPaid});
            const p3Contract = await mainContract.connect(accounts[3]);
            await p3Contract.enterLottery(1, {value: feeToPaid});
        
            // Increase time by the specified interval
            await network.provider.send("evm_increaseTime", [timeInterval]);
            await network.provider.send("evm_mine");
        
            //check the checkthings
            const tx=await mainContract.checkThings(1);
            assert.equal("true",tx.toString());
            // Ensure the function to determine the winner is called
            await mainContract.makeThingsWinner(1);
            const tx2=await mainContract.checkLotteryStatus(1);
            assert.equal("false",tx2.toString());
            const balance = await ethers.provider.getBalance(mainContract.address);
           const balanceInEth = ethers.utils.formatEther(balance);
           assert.equal("0.008",balanceInEth.toString());
           //checking token balance
     
         const tokenBalance= await mainContract.getTokenBalance();
          assert.equal("4",tokenBalance.toString());
     
        });
        it("it will addup login newbie and keep streak count and also provide exchange",async function(){
              
        })
    })
    })
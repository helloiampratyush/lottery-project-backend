// SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;
error lottery__NotEnoughEth();
error Lottery_TransferFailed();
error lottery__notOpen();
error  lottery__notEnoughToken();
error lottery__notnewBie();
error lottery__newBie();
error lottery__notEnoughLotterytime();
error lottery__notOwner();
/**
 * @title a sample lottery contract
 * @author helloiampratyush
 * @notice this contract is for creating  untamperable decentralized smart contract
 */

//one of the player should be paid

contract RandomLottery {
    address private randomAddress;
    enum lotteryState {
        OPEN,
     CLOSED
    }
    struct lotteryThings
    {
         uint256 s_entranceFee;
         uint256 s_latestTimeStamp;
         uint256 s_interval;
         lotteryState s_lotteryState;
         uint256 MinPlayers;
    }
    struct login{
        uint256 streak;
        uint256 s_lastTimeStamp;
        uint256 check_reset;
    }

    // uint256 0=OPEN,uint256 1=CALCULATING
    //state variable
    uint256 private lotteryCounter=1;
    uint256 private lotteryCompletionOwnerTime=0;
 
    //lottery variable
    address payable i_owner;
    address private s_recentWinner;
   //mapping (uint256=>uint256) private WinnerIndex;
   mapping(uint256=>lotteryThings) private lotteryMap;
   mapping(uint256=>address payable[] ) private  s_players;
   mapping(address=>uint256) private tokenBalance;
   mapping(address=>login) private loginManagement;
    //events
    event lotteryAnnounceMent(uint256 counterNo,uint256 entranceFee,uint256 timeStamp,uint256 endTime,uint256 indexed minplayers);
    //event enterlottery(uint256 counterNo,address participants,uint256 time);
    //event RequestedLotteryWinner(uint256 indexed requestId,uint256 lotteryCounter);
    event winnerPicked(address indexed winner,uint256 lotteryCounter);
    event lotteryForceEnded(uint256 lotteryCounter);
   
    //consructor
    constructor(){
        i_owner=payable(msg.sender);
    }
 
         
       function lotteryStart(uint16 _timeInterval,uint256 _entranceFee,uint256 _minplayers) public 
       {
        if(msg.sender!=i_owner)

        {
            revert lottery__notOwner();
        }
       lotteryMap[lotteryCounter]=lotteryThings(_entranceFee,block.timestamp,_timeInterval,lotteryState.OPEN,_minplayers);
     
       emit lotteryAnnounceMent(lotteryCounter,_entranceFee,block.timestamp, block.timestamp+_timeInterval,_minplayers);

         lotteryCounter+=1;

       }
    function enterLottery(uint256 _lotteryCounter) public payable {
        if (msg.value < lotteryMap[_lotteryCounter].s_entranceFee) {
            revert lottery__NotEnoughEth();
        }
        if (lotteryMap[_lotteryCounter].s_lotteryState != lotteryState.OPEN) {
            revert lottery__notOpen();
        }
       if(block.timestamp>lotteryMap[_lotteryCounter].s_latestTimeStamp+lotteryMap[_lotteryCounter].s_interval){
        revert lottery__notOpen();
       }
        s_players[_lotteryCounter].push(payable(msg.sender));
        randomAddress=msg.sender;
     
    }
//condition checking variable
   function checkThings(uint256 _lotteryCounter) public view returns(bool) 
   {
    bool isDeadinePassed=(block.timestamp>=(lotteryMap[_lotteryCounter].s_latestTimeStamp+lotteryMap[_lotteryCounter].s_interval));
    bool isPlayerAll=(s_players[_lotteryCounter].length>=lotteryMap[_lotteryCounter].MinPlayers);
    bool islotteryStillOn=checkLotteryStatus(_lotteryCounter);
    bool res=(isDeadinePassed&&isPlayerAll&&islotteryStillOn);
    return res;
    
   }
    //winnerPicking

        function makeThingsWinner(uint256 _lotteryCounter) public  {
           
            require(checkThings(_lotteryCounter)==true,"you cant enter here");
            require(msg.sender==i_owner,"owner have given privillages due to security issues");
             uint256 indexofWinner;

           if(checkThings(_lotteryCounter)){
            indexofWinner=uint256(keccak256(abi.encodePacked(randomAddress,block.number,s_players[_lotteryCounter].length)))%(s_players[_lotteryCounter].length);  
              
           }
           address payable recentWinner= payable (s_players[_lotteryCounter][indexofWinner]);
             uint256 amount=(4*(s_players[_lotteryCounter].length)*(lotteryMap[_lotteryCounter].s_entranceFee))/5;
              lotteryMap[_lotteryCounter].s_lotteryState=lotteryState.CLOSED;
             (bool success, ) = recentWinner.call{value: amount}("");
             require(success,"transaction Failed");
            
             //token distribution
            for(uint256 i=0;i<s_players[_lotteryCounter].length;i++){
                address participants=s_players[_lotteryCounter][i];
                tokenBalance[participants]+=4;

             }
             delete s_players[_lotteryCounter];
             lotteryCompletionOwnerTime+=1;
             emit winnerPicked(recentWinner,_lotteryCounter);
        }
           //token exchanging
function exchangeTokenToeth() public returns(bool){
    if(getTokenBalance()<100){
        revert lottery__notEnoughToken();
    }
    require(address(this).balance>=0.1*1e18,"can not exchange now,low contract balance ");
    require(getOverAllLotteryStatus(),"all lottery should be in closed state");
      tokenBalance[msg.sender]-=100;
      (bool success,)=(msg.sender).call{value:0.1*1e18}("");
      require(success,"transaction Failed");
      return true;
      }
    function newBieBonus() public {
    
        if(loginManagement[msg.sender].check_reset==0){
            loginManagement[msg.sender]=login(1,block.timestamp,1);
            tokenBalance[msg.sender]+=5;

        }
        else {
                revert lottery__notnewBie(); 
        }
    }
    //login token distribution
    function loginManagement1() public {
          require(loginManagement[msg.sender].check_reset>0,"you are new bie");
          require((block.timestamp)-(loginManagement[msg.sender].s_lastTimeStamp)>=(24*3600),"not 24 hours past");
           if(block.timestamp-(loginManagement[msg.sender].s_lastTimeStamp)>(2*24*3600)){
                       loginManagement[msg.sender].streak=1;
                     
                       loginManagement[msg.sender].s_lastTimeStamp=block.timestamp;
                       tokenBalance[msg.sender]+=1;
           }
           else {
            uint256 streakDay=loginManagement[msg.sender].streak;
                 if(streakDay>=1&&streakDay<6){
                     loginManagement[msg.sender].streak+=1;
                
                       loginManagement[msg.sender].s_lastTimeStamp=block.timestamp;
                       tokenBalance[msg.sender]+=1;
                 }
                 else{
                     loginManagement[msg.sender].streak+=1;
                    
                       loginManagement[msg.sender].s_lastTimeStamp=block.timestamp;
                       tokenBalance[msg.sender]+=2;
                 }
           }
    }
    //owner cashout
    function ownerCashout() public {
        require(msg.sender==i_owner,"you are not eligible for commercial fund");
         require(getOverAllLotteryStatus(),"all lottery should be in closed state");
        if(lotteryCompletionOwnerTime>10){
             require(address(this).balance>=0.8*1e18,"sorry you can not cash out now,low balance");
                         lotteryCompletionOwnerTime-=10;
        (bool success,)= i_owner.call{value:0.8*1e18}("");
      require(success,"transaction failed");
      
        }
        else {
            revert lottery__notEnoughLotterytime();
        }       
    }
    //some getter
    
        
    
    function getOverAllLotteryStatus() public view returns(bool){
        bool totalStatus=true;
        for(uint256 i=1;i<=lotteryCounter;i++){
            bool status=(lotteryMap[i].s_lotteryState==lotteryState.CLOSED);
            totalStatus=totalStatus&&status;
        }
        return totalStatus;
    }
    //refund function
    function getYourRefund(uint256 _lotteryCounter) public {
        uint256 lotteryEnded=lotteryMap[_lotteryCounter].s_interval+lotteryMap[_lotteryCounter].s_latestTimeStamp;
        require(block.timestamp-lotteryEnded>3600*24,"wait for sometime");
        bool varCheck=false;
        uint256 counter;
        for(uint256 i=0;i<s_players[_lotteryCounter].length;i++){
            if(s_players[_lotteryCounter][i]==msg.sender){
                counter=i;
                varCheck=true;
            }
        }
        require(varCheck==true,"you are not in this list");
        uint256 getRefund=lotteryMap[_lotteryCounter].s_entranceFee;
        delete s_players[_lotteryCounter][counter];
          (bool success,)=(msg.sender).call{value:getRefund}("");
          require(success,"transaction failed");
        
         if(s_players[_lotteryCounter].length==0){
            lotteryMap[_lotteryCounter].s_lotteryState=lotteryState.CLOSED;

         }
    }
    //still refund is active
    function forceLotteryClosed(uint256 _lotteryCounter) public {

             require(msg.sender==i_owner,"owner required for shutdown lottery");
             uint256 lotteryEnded=lotteryMap[_lotteryCounter].s_interval+lotteryMap[_lotteryCounter].s_latestTimeStamp;
              require(block.timestamp-lotteryEnded>3600*24*2,"wait for sometime");
    lotteryMap[_lotteryCounter].s_lotteryState=lotteryState.CLOSED;
    emit lotteryForceEnded(_lotteryCounter);

    }
   function getYourStreak() public view returns(uint256){
    return(loginManagement[msg.sender].streak);
   }      
    function getTokenBalance() public view returns(uint256){
        return (tokenBalance[msg.sender]);
    }
   
     function minplayerRequiredToJoin(uint256 _lotteryCounter) public view returns(uint256){
        require((lotteryMap[_lotteryCounter].MinPlayers-s_players[_lotteryCounter].length)>0);
        return (lotteryMap[_lotteryCounter].MinPlayers-s_players[_lotteryCounter].length);
     }
    function checkLotteryStatus(uint256 _lotteryCounter) public view returns(bool){
        return(lotteryMap[_lotteryCounter].s_lotteryState==lotteryState.OPEN);
    }
    function getlatestLoginTime() public view returns(uint256){
        return (loginManagement[msg.sender].s_lastTimeStamp);
    }
}
// SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;
//import
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
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
 * @notice this contract is for creating  untamperable decentralized lottery smart contract
 */


contract RandomLottery is VRFConsumerBaseV2{
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
    uint256 public lotteryCounter=1;
    uint256 public lotteryCompletionOwnerTime=0;
 
    //lottery variable
    address payable i_owner;
   //mapping (uint256=>uint256) private WinnerIndex;
   mapping(uint256=>lotteryThings) public lotteryMap;
   mapping(uint256=>address payable[] ) public  s_players;
   mapping(address=>uint256) public tokenBalance;
   mapping(address=>login) public loginManagement;
   mapping(uint256=>RequestStatus) public s_requests;
   mapping(uint256=>uint256) public relationId;
    //events
    event lotteryAnnounceMent(uint256 counterNo,uint256 entranceFee,uint256 timeStamp,uint256 endTime,uint256 indexed minplayers);
    event winnerPicked(address indexed winner,uint256 lotteryCounter);
    event lotteryForceEnded(uint256 lotteryCounter);
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
 

    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 public s_subscriptionId;

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;
    uint256[] public lastRandomWords;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
    bytes32 keyHash =
        0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
    uint32 callbackGasLimit = 2500000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;
    //consructor
   constructor(uint64 subscriptionId)
  VRFConsumerBaseV2(0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625)
    {
          i_owner=payable(msg.sender);
        COORDINATOR = VRFCoordinatorV2Interface(
            0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625
        );
        s_subscriptionId = subscriptionId;
   }  

   //function
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

       function checkThings(uint256 _lotteryCounter) public  returns(uint256 requestId) 
    {
    require(msg.sender==i_owner,"you are not eligible");
    bool isDeadinePassed=(block.timestamp>=(lotteryMap[_lotteryCounter].s_latestTimeStamp+lotteryMap[_lotteryCounter].s_interval));
    bool isPlayerAll=(s_players[_lotteryCounter].length>=lotteryMap[_lotteryCounter].MinPlayers);
    bool isLotteryActive=(lotteryMap[lotteryCounter].s_lotteryState==lotteryState.OPEN);
    bool res=(isDeadinePassed&&isPlayerAll&&isLotteryActive);
    if(res){

          requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
          relationId[requestId]=_lotteryCounter;
    }
    else{
        return 0;
    }
    
   }
        function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
           lastRandomWords=_randomWords;
           lastRequestId=_requestId;
        uint256 _lotteryCounter=relationId[lastRequestId];
         uint256 indexofWinner;
         indexofWinner=lastRandomWords[0]%s_players[_lotteryCounter].length;
         address payable s_recentWinner= payable (s_players[_lotteryCounter][indexofWinner]);
          uint256 amount=(4*lotteryMap[_lotteryCounter].s_entranceFee)*(s_players[_lotteryCounter].length)/5;
          lotteryMap[_lotteryCounter].s_lotteryState=lotteryState.CLOSED;
          (bool success,)=(s_recentWinner).call{value:amount}("");
          require(success,"failed");

             //token distribution
            for(uint256 i=0;i<s_players[_lotteryCounter].length;i++){
                address participants=s_players[_lotteryCounter][i];
                tokenBalance[participants]+=4;

             }
             lotteryCompletionOwnerTime+=1;
             emit winnerPicked(s_recentWinner, _lotteryCounter);
             emit RequestFulfilled(_requestId, _randomWords);
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
        if(lotteryCompletionOwnerTime>5){
             require(address(this).balance>=0.8*1e18,"sorry you can not cash out now,low balance");
                         lotteryCompletionOwnerTime-=5;
        (bool success,)= i_owner.call{value:0.8*1e18}("");
      require(success,"transaction failed");
      
        }
        else {
            revert lottery__notEnoughLotterytime();
        }       
    }
    //refund function
    function getYourRefund(uint256 _lotteryCounter) public {
        uint256 lotteryEnded=lotteryMap[_lotteryCounter].s_interval+lotteryMap[_lotteryCounter].s_latestTimeStamp;
        require(lotteryMap[_lotteryCounter].s_lotteryState==lotteryState.OPEN,"successFully completed lottery");
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

     function forceLotteryClosed(uint256 _lotteryCounter) public {

             require(msg.sender==i_owner,"owner required for shutdown lottery");
             require(lotteryMap[_lotteryCounter].s_lotteryState==lotteryState.OPEN,"no need to approve lottery was successful");
             uint256 lotteryEnded=lotteryMap[_lotteryCounter].s_interval+lotteryMap[_lotteryCounter].s_latestTimeStamp;
              require(block.timestamp-lotteryEnded>3600*24*2,"wait for sometime");
    lotteryMap[_lotteryCounter].s_lotteryState=lotteryState.CLOSED;
    emit lotteryForceEnded(_lotteryCounter);
    }
    //some getter
    function getOverAllLotteryStatus() public view returns(bool){
        bool totalStatus=true;
        for(uint256 i=1;i<lotteryCounter;i++){
            bool status=(lotteryMap[i].s_lotteryState==lotteryState.CLOSED);
            totalStatus=totalStatus&&status;
        }
        return totalStatus;
    }
    
    //still refund is active
   
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
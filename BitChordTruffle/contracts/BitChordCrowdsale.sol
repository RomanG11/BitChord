pragma solidity ^0.4.20;

//standart library for uint
library SafeMath { 
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0){
        return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function pow(uint256 a, uint256 b) internal pure returns (uint256){ //power function
    if (b == 0){
      return 1;
    }
    uint256 c = a**b;
    assert (c >= a);
    return c;
  }
}

//standart contract to identify owner
contract Ownable {

  address public owner;

  address public newOwner;

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function Ownable() public {
    owner = msg.sender;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    newOwner = _newOwner;
  }

  function acceptOwnership() public {
    if (msg.sender == newOwner) {
      owner = newOwner;
    }
  }
}

//Abstract Token contract
contract TokenContract{
  function transfer(address,uint256) public;
  function balanceOf(address) public returns(uint);    
}

//Crowdsale contract
contract BitChordCrowdsale is Ownable{

  using SafeMath for uint;

  uint decimals = 18;

  // Token contract address
  TokenContract public token;

  address public distributionAddress;

  // Constructor
  function BitChordCrowdsale(address _tokenAddress, address _distribution) public {
    token = TokenContract(_tokenAddress);
    owner = msg.sender;

    distributionAddress = _distribution;
    
  }

  uint public constant STAGE_1_START = 0; //1523404860 
  uint public constant STAGE_1_FINISH = 1525132740;

  uint public constant STAGE_1_PRICE = 6500;
  uint public constant STAGE_1_MAXCAP = 8000 ether;// 3100000 ether; 

  uint public constant STAGE_2_START = 1525132860; 
  uint public constant STAGE_2_FINISH = 1526687940; 

  uint public constant STAGE_2_PRICE = 4700;
  uint public STAGE_2_MAXCAP = 9000000 ether;


  uint public constant STAGE_3_START = 1526688060; 
  uint public constant STAGE_3_FINISH = 1535414340;

  uint public constant STAGE_3_PRICE = 3800;
  uint public constant STAGE_3_MAXCAP = 67100000 ether;


  uint public constant MIN_IVESTMENT = 0.1 ether;


  function getPhase(uint _time) public view returns(uint8) {
    if(_time == 0){
      _time = now;
    }
    if (STAGE_1_START <= _time && _time < STAGE_1_FINISH){
      return 1;
    }
    if (STAGE_2_START <= _time && _time < STAGE_2_FINISH){
      return 2;
    }
    if (STAGE_3_START <= _time && _time < STAGE_3_FINISH){
      return 3;
    }
    return 0;
  }

  function getTimeBasedBonus (uint _time) public view returns(uint) {
    if (_time == 0){
      _time = now;
    }
    if (getPhase(_time) != 3){
      return 0;
    }
    if (STAGE_3_START + 20 days >= _time){
      return 10;
    }
    if (STAGE_3_START + 38 days >= _time){
      return 5;
    }
    return 0;
  }

  uint public ethCollected = 0;
  uint public stage_1_TokensSold = 0;
  uint public stage_2_TokensSold = 0;
  uint public stage_3_TokensSold = 0;


  function () public payable {
    require (buy(msg.sender, msg.value, now));
    require (msg.value >= MIN_IVESTMENT);
  }

  function buy (address _address, uint _value, uint _time) internal returns(bool)  {
    uint8 currentPhase = getPhase(_time);


    if (currentPhase == 1){
      uint tokensToSend = _value.mul(STAGE_1_PRICE);
      if(stage_1_TokensSold.add(tokensToSend) <= STAGE_1_MAXCAP){
        ethCollected = ethCollected.add(_value);
        token.transfer(_address,tokensToSend);
        distributionAddress.transfer(address(this).balance);

        stage_1_TokensSold = stage_1_TokensSold.add(tokensToSend);

        return true;
      }else{
        if(stage_1_TokensSold == STAGE_1_MAXCAP){
          return false;
        }

        uint availableTokens = STAGE_1_MAXCAP.sub(stage_1_TokensSold);
        uint ethRequire = availableTokens/STAGE_1_PRICE;
        token.transfer(_address,availableTokens);
        msg.sender.transfer(_value.sub(ethRequire));
        distributionAddress.transfer(address(this).balance);

        ethCollected = ethCollected.add(ethRequire);
        stage_1_TokensSold = STAGE_1_MAXCAP;

        return true;
      }
    }

    if(currentPhase == 2){
      if(stage_1_TokensSold != STAGE_1_MAXCAP){
        STAGE_2_MAXCAP = STAGE_2_MAXCAP.add(STAGE_1_MAXCAP.sub(stage_1_TokensSold));
      }
      tokensToSend = _value.mul(STAGE_2_PRICE);
      if(stage_2_TokensSold.add(tokensToSend) <= STAGE_2_MAXCAP){
        ethCollected = ethCollected.add(_value);
        token.transfer(_address,tokensToSend);
        distributionAddress.transfer(address(this).balance);

        stage_2_TokensSold = stage_2_TokensSold.add(tokensToSend);

        return true;
      }else{
        if(stage_2_TokensSold == STAGE_2_MAXCAP){
          return false;
        }
        availableTokens = STAGE_2_MAXCAP.sub(stage_2_TokensSold);
        ethRequire = availableTokens/STAGE_2_PRICE;
        token.transfer(_address,availableTokens);
        msg.sender.transfer(_value.sub(ethRequire));
        distributionAddress.transfer(address(this).balance);

        ethCollected = ethCollected.add(ethRequire);
        stage_2_TokensSold = STAGE_2_MAXCAP;

        return true;
      }
    }
    if(currentPhase == 3){
      tokensToSend = _value.mul(STAGE_3_PRICE);
      uint bonusPercent = getTimeBasedBonus(_time);
      tokensToSend = tokensToSend.add(tokensToSend.mul(bonusPercent)/100);

      if(stage_3_TokensSold.add(tokensToSend) <= STAGE_3_MAXCAP){
        ethCollected = ethCollected.add(_value);
        token.transfer(_address,tokensToSend);
        distributionAddress.transfer(address(this).balance);

        stage_3_TokensSold = stage_3_TokensSold.add(tokensToSend);

        return true;
      }else{
        if(stage_3_TokensSold == STAGE_3_MAXCAP){
          return false;
        }

        availableTokens = STAGE_3_MAXCAP.sub(stage_2_TokensSold);
        ethRequire = availableTokens/STAGE_3_PRICE;
        token.transfer(_address,availableTokens);
        msg.sender.transfer(_value.sub(ethRequire));
        distributionAddress.transfer(address(this).balance);

        ethCollected = ethCollected.add(ethRequire);
        stage_3_TokensSold = STAGE_3_MAXCAP;

        return true;
      }
    }    

    return false;
  }


  function tokenCalculate (uint _value, uint _time) public view returns(uint)  {
    uint bonusPercent;
    uint8 currentPhase = getPhase(_time);

    if (currentPhase == 1){
      return _value.mul(STAGE_1_PRICE);
    }
    if(currentPhase == 2){
      return _value.mul(STAGE_2_PRICE);
    }
    if(currentPhase == 3){
      uint tokensToSend = _value.mul(STAGE_3_PRICE);
      bonusPercent = getTimeBasedBonus(_time);
      return tokensToSend.add(tokensToSend.mul(bonusPercent)/100);
    }
    return 0;
  }
  
  function requestRemainingTokens () public onlyOwner {
    // require (now > STAGE_3_FINISH);
    token.transfer(owner,token.balanceOf(address(this)));
  }
  
}
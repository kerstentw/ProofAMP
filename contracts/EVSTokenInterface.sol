pragma solidity ^0.4.11;


contract EVSTokenInterface {

struct DateTime {
    uint16 year;
    uint8 month;
    uint8 day;
    uint8 hour;
    uint8 minute;
    uint8 second;
    uint8 weekday;
  }

  struct Payout {
    Datetime date;
    uint256 amount;
  }

  struct PayoutInterval {
    Datetime start;
    Datetime end;
    Datetime interval;
    uint256 amount;
  }

  mapping(address => uint256) public balances;
  mapping(address => uint256) public forSale;
  mapping(address => uint256) public insured;
  mapping(address => uint256) public prices;
  mapping(address => uint256) public lastPayoutPoints;
  mapping(address => uint256) public compensations;
  mapping(address => mapping (address => uint)) allowed; //not sure what this is anymore?


  uint256[] public constant payoutList;
  uint256[] public constant payoutIntervalList;

  string public constant name;
  string public constant symbol;
  uint8 public constant decimals = 18;
  bool public mintingFinished = false;
  
  uint256 public reserve;
  uint256 public pointMultiplier;
  uint256 public payoutNumber;

  address public issuer;
  EVS public evs;
  TokenLedger public tokenLedger;

  function balanceOf(address _owner) public constant returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
  function approve(address _spender, uint256 _value) public returns (bool);
  function allowance(address _owner, address _spender) public returns (uint256);
  function setPrice(uint256 _price) public returns (bool);
  function setForSale(uint256 _amount) public returns (bool);
  function addPayoutDate(uint256 _date, uint256 _amount) public returns (bool);
  function addPayoutInterval(uint256 _start, uint256 _end, uint256 _interval, uint256 _amount) public returns (bool);
  function purchase(address _seller, uint256 _maxPrice) payable public constant returns (bool);


}
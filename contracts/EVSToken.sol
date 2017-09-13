pragma solidity ^0.4.11;

import './SafeMath.sol';
import './ERC20.sol';
import './Ownable.sol';
import './EVS.sol';
import './TokenLedger.sol';
import './Datetime.sol';

/**
 * @title EVSToken 
 * Standard Mintable ERC20 Token
 */
contract EVSToken is ERC20, Ownable {

  using SafeMath for uint256;

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


  mapping(uint256 => Payouts) public payouts; //mapping of payout timestamps to payouts structures
  PayoutInterval public payoutInterval; //currently only one interval per token is supported
  bool public payoutIntervalIsSet; //cannot modify the payout interval once it is set

  enum Intervals { DAILY, WEEKLY, MONTHLY, BIANNUALLY, YEARLY }

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


  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  event Payout(address indexed to, uint256 amount);
  event UpdatePayout(address indexed to, uint256 amount);
  event SendInsurance(address indexed to, uint256 amount);
  event SetPrice(address indexed owner, uint256 price);
  event SetForSale(address indexed owner, uint256 amount);


  function EVSToken(address _issuer, string _name, string _symbol) {
    issuer = _issuer;
    name = _name;
    symbol = _symbol;
  }


  function() payable {
    revert();
  }
  
  function balanceOf(address _owner) constant returns (uint256) {
    return balances[_owner];
  }

  function transfer(address _to, uint _value) returns (bool) {

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);

    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);

    Transfer(_from, _to, _value);
    return true;
  }


  /** 
   * @description Approve spending of ether on behalf of another user
   * @param _spender
   * @param _value
   */
  function approve(address _spender, uint _value) returns (bool) {
    allowed[msg.sender][_spender] = _value;

    Approval(msg.sender, _spender, _value);
    return true;
  }


  /** 
   * @description 
   * @param _owner
   * @param _spender
   */
  function allowance(address _owner, address _spender) constant returns (uint256) {

    return allowed[_owner][_spender];
  }


  /** 
   * @description setPrice allows any account with positive token balance can set the price of their tokens
   * @param _price
   * @return success
   */
  function setPrice(uint256 _price) returns (bool) {
    require(balanceOf(msg.sender) > 0);

    price[msg.sender] = _price;

    SetPrice(msg.sender, _price);
    return true;
  }

  /** 
   * @description setForSale allows any account with positive token balance to set a certain amount of tokens for sale
   * @param _amount
   * @return success
   */
  function setForSale(uint256 _amount) returns (bool success) {
    require(balanceOf(msg.sender) > 0);
    require(balanceOf(msg.sender) < _amount);

    forSale[msg.sender] = _amount;
    
    SetForSale(msg.sender, _amount);
    return true;
  }

  /** 
   * @description The owner of the EVS token adds a arbitrary payout date
   * @param _year
   * @param _month
   * @param _day
   * @param _amount
   * @returns success
   */
  function addPayoutDate(uint256 _date, uint256 _amount) returns (bool success) {
    
    Datetime payoutDate = parseTimestamp(_date);
    
    payouts[timestamp] = Payout({
      date: payoutDate,
      amount: _amount
    });

    payoutList.push(timestamp);
    
    return true;
  }


  /** 
   * @description The owner of the EVS token adds a arbitrary payout interval
   * @dev Currently considering if the input date parameters should be represented as timestamps or year/month/day
   * @dev I currently chose to allow only one timestamp
   * @param _start
   * @param _end
   * @param _interval
   * @param _amount
   */
  function addPayoutInterval(uint256 _start, uint256 _end, uint256 _interval, uint256 _amount) returns (bool success) {
    require(payoutInterval.amount == 0);

    Datetime payoutStart = parseTimestamp(_start);
    Datetime payoutEnd = parseTimestamp(_end);
    Datetime payoutInterval = parseTimestamp(_interval);

    payoutInterval = PayoutInterval({
      start: payoutStart,
      end: payoutEnd,
      interval: payoutInterval,
      amount: _amount
    });

    return true;
  }


  /**
   * @dev might need to account for the gas cost of the transaction - probably not?
   * @param _seller Token holder receives ether in exchange for a certain number of tokens
   * @params _maxPrice Highest price the buyer is willing to buy 
   */
  function purchase(address _seller, uint256 _maxPrice) payable constant returns (bool) {
    uint256 price = prices[_seller];

    require(msg.value);
    require(prices[_seller] < _maxPrice);
    require(balances[_seller] > 0);
    
    uint256 amount = (msg.value) / price;

    assert(forSale[_seller] > amount);

    balances[_seller] = balances[_seller].sub(amount);
    balances[msg.sender] = balances[msg.sender].add(amount);

    _seller.transfer(msg.value);

    Purchase(msg.sender);
    return true;
  }


  /**
   * @dev might need to account for the gas cost of the transaction - probably not?
   * @param _seller Token holder receives ether in exchange for a certain number of tokens
   */
  function insure() payable public returns (bool) {
    insured[msg.sender] = insured[msg.sender].add(msg.value);
    reserve = reserve.add(msg.value);

    Insure(msg.sender);
    return true;
  }


  /**
   * @dev might need to account for the gas cost of the transaction - probably not?
   * @param _seller Token holder receives ether in exchange for a certain number of tokens
   */
  function EVSVerification() {
    assert(evs.verify());
  }


  /**
   * @dev might need to account for the gas cost of the transaction - probably not?
   * @param _seller Token holder receives ether in exchange for a certain number of tokens
   */
  function payout(uint _amount) onlyIssuer payable returns (bool) {

    payouts = payouts.add(_amount);
    uint256 payoutPoints = (payoutPoints.mul(pointMultiplier)) / tokenSupply;
    totalPayoutPoints = totalPayoutPoints.add(dividendPoints);

    evs.payoutNotification(_amount);

    Payout(msg.sender, _amount);
    return true;
  }

  /**
   * @dev might need to account for the gas cost of the transaction - probably not?
   * @param _seller Token holder receives ether in exchange for a certain number of tokens
   */
  function withdrawPayout() returns (bool) {
    uint256 tokenBalance = balanceOf(msg.sender);
    uint256 newPayoutPoints = totalPayoutDividendPoints.sub(lastPayoutPoints[msg.sender]);
    uint256 owing = (tokenBalance.mul(newPayoutPoints)) / pointMultiplier;

    assert(owing > 0);
    
    lastPayoutPoints[msg.sender] = totalPayoutPoints;
    dividends = dividends.sub(owing);
    msg.sender.transfer(owing);

    WithdrawPayout(msg.sender, owing);
    return true;
  }

  /**
   * @description EVSToken Holders (asset investors) call this function to receive compensation
   * @returns success
   */
  function withdrawCompensation() returns (bool) {
    require(msg.sender != 0x0);
    uint256 amount = compensation[msg.sender];

    assert(amount > 0);
    
    reserve = reserve.sub(compensation);
    compensation[msg.sender] = compensation[msg.sender].sub(compensation);
    msg.sender.transfer(compensation);

    Compensation(msg.sender, amount);
    return true;
  }

  /**
   * @dev might need to account for the gas cost of the transaction - probably not?
   * @param _to 
   * @param _seller Token holder receives ether in exchange for a certain number of tokens
   */
  function compensate(uint256 _to, uint256 _amount) onlyEVS returns (bool) {
    require(_to != 0x0);
    require(_amount > 0);

    reserve = reserve.add(_amount);
    compensation[msg.sender] = compensation[msg.sender].add(_amount);


    CompensationReceived(msg.sender, _to, _amount);
    return true;
  }
  
  modifier onlyIssuer() {
    require(msg.sender == issuer);
    _;
  }
  
  modifier onlyEVS() {
    require(msg.sender == evs);
    _;
  }
    
  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * Function to mint tokens
   * @dev minting is not protected - just for testing conveniently
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

  /**
   * Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
  
}
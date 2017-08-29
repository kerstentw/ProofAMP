pragma solidity ^0.4.11;

import './SafeMath.sol';
import './ERC20.sol';
import './Ownable.sol';
import './TokenLedger.sol';
import './EVSInterface.sol';

/**
 * @title EVSToken 
 * Standard Mintable ERC20 Token
 */
contract EVSToken is ERC20, Ownable {

  using SafeMath for uint256;

  mapping(address => uint256) balances;
  mapping(address => uint256) forSale;
  mapping(address => uint256) insured;
  mapping(address => uint256) prices;
  mapping(address => uint256) lastPayoutPoints;
  mapping(address => uint256) compensations;
  mapping(address => mapping (address => uint)) allowed;
  mapping(uint256 => Payouts) public payouts;

  struct Payout {
    uint16 year,
    uint8 month,
    uint8 day,
    uint256 amount
  }

  uint256[] public constant payoutList;

  string public constant name;
  string public constant symbol;
  uint8 public constant decimals = 18;
  bool public mintingFinished = false;
  
  uint256 public reserve;
  uint256 public pointMultiplier;
  uint256 public payoutNumber;

  address public issuer;
  EVSInterface public evs;
  TokenLedgerInterface public tokenLedger;

  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  event Payout(address indexed to, uint256 amount);
  event UpdatePayout(address indexed to, uint256 amount);
  event SendInsurance(address indexed to, uint256 amount);

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

  function setPrice(uint256 _price) returns (bool) {
    require(balanceOf(msg.sender) > 0);

    price[msg.sender] = _price;

    SetPrice(msg.sender, _price);
    return true;
  }

  function setForSale(uint256 _amount) returns (bool) {
    require(balanceOf(msg.sender) > 0);
    require(balanceOf(msg.sender) < _amount);

    forSale[msg.sender] = _amount;
    
    SetForSale(msg.sender, _amount);
    return true;
  }



  function addPayoutDate(uint16 _year, uint8 _month, uint8 _day, uint256 _amount) {

    numberId = numberId.add(1);
    payoutList = numberId;
    timestamp = toTimestamp(_year,_month,_day);
    
    payouts[timestamp] = Payout({
      year: _year,
      month: _month,
      day: _day,
      amount: _amount
    });

    payoutList.push(timestamp);
    
    return true;
  }
  
  
  function getPayouts() external constant returns (uint256[] ) {
    
    return 
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
   * @dev might need to account for the gas cost of the transaction - probably not?
   * @param _seller Token holder receives ether in exchange for a certain number of tokens
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
   * @description 
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
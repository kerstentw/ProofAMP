pragma solidity ^0.4.11;

import './SafeMath.sol';
import './ERC20.sol';
import './Ownable.sol';
import './TokenLedgerInterface.sol';
import './EVSInterface.sol';

/**
 * @title ProofToken (PROOFP) 
 * Standard Mintable ERC20 Token
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */

contract EVSToken is ERC20, Ownable {

  using SafeMath for uint256;


  mapping(address => uint) balances;
  mapping(address => uint256) forSale;
  mapping(address => uint256) insured;
  mapping(address => uint256) prices;
  mapping(address => uint256) lastPayoutPoints;
  mapping(address => mapping (address => uint)) allowed;
  

  string public constant name;
  string public constant symbol;
  uint8 public constant decimals = 18;
  bool public mintingFinished = false;
  
  uint256 public reserve;
  uint256 public pointMultiplier;

  address public issuer;
  EVSInterface public evs;
  TokenLedgerInterface public tokenLedger;

  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  event Payout(address indexed to, uint256 amount);
  event UpdatePayout(address indexed to, uint256 amount);
  event SendInsurance(address indexed to, uint256 amount);

  function EVSToken(string _name, string _symbol) {
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

  function approve(address _spender, uint _value) returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

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



  function insure() payable public returns (bool) {
    insured[msg.sender] = insured[msg.sender].add(msg.value);
    reserve = reserve.add(msg.value);

    Insure(msg.sender);
    return true;
  }

  function EVSVerification() {
    assert(evs.verify());
  }

  function depositPayout(uint _amount) onlyIssuer payable returns (bool) {

    payouts = payouts.add(_amount);
    uint256 payoutPoints = (payoutPoints.mul(pointMultiplier)) / tokenSupply;
    totalPayoutPoints = totalPayoutPoints.add(dividendPoints);

    evs.payoutNotification(_amount);

    DepositPayout(msg.sender, _amount);
    return true;
  }



  function withdrawPayout() returns (bool) {
    uint256 tokenBalance = balanceOf(msg.sender);
    uint256 newPayoutPoints = totalPayoutDividendPoints.sub(lastPayoutPoints[msg.sender]);
    uint256 owing = (tokenBalance.mul(newPayoutPoints)) / pointMultiplier;

    if (owing > 0) {
      lastPayoutPoints[msg.sender] = totalPayoutPoints;
      dividends = dividends.sub(owing);
      msg.sender.transfer(owing);
    }

    Payout(msg.sender, owing);
    return true;
  }

  /**
  * @dev Might need to validate that the address the EVS is sending is authorized
  * Otherwise do the check in the EVS contract
  */
  function sendInsurance(address _to, uint256 _amount) onlyEVS {
    msg.sender.transfer(_amount);
    reserve.sub(_amount);

    sendInsurance(msg.sender, _amount);
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
  function mint(address _to, uint256 _amount) canMint returns (bool) {
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
pragma solidity ^0.4.11;

import './SafeMath.sol';
import './TokenLedger.sol';
import './PredictionMarket.sol';
import './EVSToken.sol';

/**
 * @title EVS Interface
 */
contract EVS {

  TokenLedger public tokenLedger;
  PredictionMarket public predictionMarket;


  /**
   * @description 
   */
  function EVS(address _tokenLedgerAddress, address _predictionMarketAddress) {
      
      tokenLedger = new TokenLedger(_tokenLedgerAddress);
      predictionMarket = new PredictionMarket(_predictionMarketAddress);

  }


  /**
   * @description Request settlement verification
   */
  function requestSettlementVerification(address _token) constant returns (bool) {

      tokenData = TokenLedger.tokenData(_token);

      if valid(_token) {
          notifyPredictionMarket(_token);
          notifyTokenLedger(_token);
      } else {
          notifyPredictionMarket(_token);
          notifyTokenLedger(_token);
      }

  }

  /**
   * @description Notifies the prediction market upon completion of a token payout cycle 
   */
  function notifyPredictionMarket() constant returns (bool) {


  }

  /**
   * @description Notifies the token ledger upon completion of a token payout cycle
   */
  function notifyTokenLedger() constant returns (bool) {
      
  }

  /** 
   * @description transferTokenFunds is called upon completion of a token payout cycle
   */
  function orderCompensation(address _token, address _to, uint256 _amount) internal returns (bool) {
      require(_amount > 0);
      evsToken = new EVSToken(_token);
      evsToken.compensate.value(_amount)(_to, _amount);
      return true;
  }

  /**
   * @description Verifies the 
   */
  function verify() constant returns (bool) {

  }

  event VerifyToken(address indexed contract);
  event PredictionMarketNotification(address indexed contract, bool indexed success, string message);
  event TokenLedgerNotification(address indexed contract, bool indexed success, string message);

}

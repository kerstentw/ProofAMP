pragma solidity ^0.4.11;

/** 
 * @title TokenLedger interface
 * 
 */
 contract TokenLedgerInterface {


   struct PayoutRecord {
     uint256 amount;
     bool paid;
     uint256 index;
     uint256 timestamp;
   }

   struct Review {
     uint256 rating;
     address reviewer;
     string description;
     uint256 timestamp;
   }

   mapping (address => PayoutRecord[]) public payoutRecords;
   mapping (address => Review[]) public reviews;
   mapping (address => string) public tokens;
   address[] public tokenLists;

   EVS public evs;

   function addReview(address _token, uint256 _timestamp, address _reviewer, string _message, uint256 _rating) returns (bool);
   function addPayoutRecord(address _token, uint256 _amount, bool _paid, uint256 _timestamp) returns (bool);
   function createEVStoken(string _name, string _symbol) returns (address);

}
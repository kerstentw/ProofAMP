pragma solidity ^0.4.11;

import './SafeMath.sol';
import './ERC20.sol';
import './Ownable.sol';
import './Token.sol';
import './EVS.sol';

/**
 * @title EVSToken 
 * Standard Mintable ERC20 Token
 */
contract TokenLedger {
    
    using SafeMath for uint256;

    mapping (address => PayoutRecord[]) public payoutRecords;
    mapping (address => Review[]) public reviews;
    mapping (address => string) public tokens;
    address[] public tokenLists;

    struct PayoutRecord {
        uint amount;
        bool paid;
        uint index;
        uint timestamp;
    }

    struct Review {
        uint rating;
        address reviewer;
        string description;
        uint timestamp;
    }

    function TokenLedger() {
        
    }

    function isToken(address _token) {

    }

    function addReview(address _token, uint _timestamp, address _reviewer, string _message, uint _rating) {

        newReview = Review({
            reviewer: _reviewer,
            timestamp: _timestamp,
            message: _message,
            rating: _rating
        });

        reviews[_token].push(newReview);
        tokenAddresses.push()
        
    }

    function addPayoutRecord(address _token, uint _amount, bool _paid, uint _timestamp) {

        newPayout = PayoutRecord({
            amount: _amount,
            paid: _paid,
            timestamp: _timestamp
        });

        payoutRecords[_token].push(newPayout);

    }


    function createEVSToken(string _name, string _symbol) {
        
        address tokenAddress = address(new Token(msg.sender, _name, _symbol));

        tokenList.push(tokenAddress);
        tokens[tokenAddress] = _name;

    }

}

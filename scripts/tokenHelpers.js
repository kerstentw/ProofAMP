const h = require('../scripts/helper.js');
import { gas, gasPrice, ether } from '../scripts/testConfig.js';



/**
 * @description Total Supply of an ERC20 token. Calls the totalSupply function of the smart-contract
 * @param token ERC20 truffe contract object
 * @returns total supply
 */
const getTotalSupply = async (token) => { 
    let tokenSupply = await token.totalSupply.call();
    return tokenSupply.toNumber();
}

/**
 * @description Token holder balance of an ERC20 token. Calls the balanceOf function of the smart-contract
 * @param token ERC20 truffle contract object
 * @param owner 
 * @returns token balance
 */
const getTokenBalance = async (token, owner) => {
    let balance = await token.balanceOf(owner);
    return balance.toNumber();
}



/**
 * @description Transfers an ERC20 token. Calls the transfer function of the smart-contract
 * @param token ERC truffle contract object 
 * @param sender 
 * @param receiver 
 * @param amount 
 * @returns transactionReceipt (you can query different gasUsed, gasPrice etc.)
 */
const transferToken = async(token, sender, receiver, amount) => {
    let params = {from: sender, gas: gas, gasPrice: gasPrice };
    let txn = await token.transfer(receiver, amount, params);
    let txnReceipt = await h.waitUntilTransactionsMined(txn.tx);
    return txnReceipt;
}

/**
 * @description Transfer several tokens from one sender to one receiver. Requires handling more cases
 * @param token
 * @param sender 
 * @param receiver 
 * @param amount
 * @returns Transaction receipts (you can query different gasUsed)
 */
const transferTokens = async(token, sender, receiver, amount) => {
    let params = {from: sender, gas: gas, gasPrice: gasPrice};
    let promises = token.map(function(oneToken) { transferToken(oneToken, sender, receiver, amount)});
    let txnReceipts = await Promise.all(promises);

    return txnReceipts;
}

/**
 * @description Mint and standard mintable token. Requires ownership depending on the token implementation
 * @param token
 * @param minter 
 * @param amount
 * @returns Transaction receipt (you can query gasUsed, gasPrice etc.)
 */
const mintToken = async(token, minter, amount) => {
    let params = {from: minter, gas: gas, gasPrice: gasPrice };
    let txn = await token.mint(minter, amount, params);
    let txnReceipt = await h.waitUntilTransactionsMined(txn.tx);
    return txnReceipt;
}

module.exports = {
    getTotalSupply,
    getTokenBalance,
    transferToken,
    transferTokens,
    mintToken
}

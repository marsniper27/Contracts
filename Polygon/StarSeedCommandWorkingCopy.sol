/*
SPDX-License-Identifier: MIT

─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
─██████████████─██████████████─██████████████─████████████████───██████████████─██████████████─██████████████─████████████───
─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░░░██───██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░████─
─██░░██████████─██████░░██████─██░░██████░░██─██░░████████░░██───██░░██████████─██░░██████████─██░░██████████─██░░████░░░░██─
─██░░██─────────────██░░██─────██░░██──██░░██─██░░██────██░░██───██░░██─────────██░░██─────────██░░██─────────██░░██──██░░██─
─██░░██████████─────██░░██─────██░░██████░░██─██░░████████░░██───██░░██████████─██░░██████████─██░░██████████─██░░██──██░░██─
─██░░░░░░░░░░██─────██░░██─────██░░░░░░░░░░██─██░░░░░░░░░░░░██───██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░██──██░░██─
─██████████░░██─────██░░██─────██░░██████░░██─██░░██████░░████───██████████░░██─██░░██████████─██░░██████████─██░░██──██░░██─
─────────██░░██─────██░░██─────██░░██──██░░██─██░░██──██░░██─────────────██░░██─██░░██─────────██░░██─────────██░░██──██░░██─
─██████████░░██─────██░░██─────██░░██──██░░██─██░░██──██░░██████─██████████░░██─██░░██████████─██░░██████████─██░░████░░░░██─
─██░░░░░░░░░░██─────██░░██─────██░░██──██░░██─██░░██──██░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░████─
─██████████████─────██████─────██████──██████─██████──██████████─██████████████─██████████████─██████████████─████████████───
─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

                                        Copyright (c) 2021 Kyle Marshall
*/

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract starSeed is Ownable{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Token{
        string name; //Tokens name
        IERC20 tokenAddress;//ERC20 interface for the token
        uint depositFee;// the current deposit fee *1000 to allow for more granularity ie. 5000 = 5%, 190 = .019%
        uint collectedFee;//Total fees collected by a token
        uint withdrawLimit;//max wihtdraw wihtout approval
    }

    struct UserInfo{
        uint allowance; //users current allowance
        uint amountStaked;//users current staked balance
        uint totalBalance;// users current total token balance
    }

    struct PendingWithdraw{
        address user; //address of user who requested a withdraw
        uint tokenPid;//the index of the token they are tryng to withdraw
        uint amount; //the amount they want to withdraw
    }

    Token[] tokens;
    PendingWithdraw[] pendingWithdraws;
    Uint public remainingReward; //the Star int he contract available to be paid out

    // Info of each user that stakes tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    //events emited to the blockchain
    event depositFeeChange(string name,uint oldFee, uint newFee); //emit a event if the deposit fees for the contract are changed.
    event fundRewards(uint amountAdded, uint newBalance); //emit event when rewards are added to the reward pool from owner
    

     constructor() {
         //fill the tokens array with the tokens supported on launch
         tokens.push(Token({
            name : "STAR-Matic",
            tokenAddress : IERC20(0xFbfe7C5c437eFFD9730913804e4CD8B890D62A9c),
            depositFee:5000,
            collectedFee:0,
            withdrawLimit:5000 *10**18
         }));
         tokens.push(Token({
            name : "STAR-ETH",
            tokenAddress : IERC20(0x5D36360798BaC73c3Fb14A3D6EA5550023a224A6),
            depositFee:5,
            collectedFee:0,
            withdrawLimit:5000 *10**18
         }));
         tokens.push(Token({
            name : "STAR-DHV",
            tokenAddress : IERC20(0xe3874712E1569a4Fe332B609667e21bb1B2a7a2b),
            depositFee:5,
            collectedFee:0,
            withdrawLimit:5000 *10**18
         }));
         tokens.push(Token({
            name : "STAR-USDC",
            tokenAddress : IERC20(0x1083c85029bf1728636a7fE7A6f3a5B9aBa7B4b9),
            depositFee:5,
            collectedFee:0,
            withdrawLimit:5000 *10**18
         }));
         tokens.push(Token({
            name : "STAR-WBTC",
            tokenAddress : IERC20(0xe1146dA6E36729903366397bDAaA2781F3707Ff4),
            depositFee:5,
            collectedFee:0,
            withdrawLimit:5000 *10**18
         }));
         tokens.push(Token({
            name : "WBTC",
            tokenAddress : IERC20(0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6),
            depositFee:5,
            collectedFee:0,
            withdrawLimit:5000 *10**18
         }));
         tokens.push(Token({
            name : "STAR",
            tokenAddress : IERC20(0xC6e2e8395A671eE3f6f55177F8Fe5984D5dA7741),
            depositFee:5,
            collectedFee:0,
            withdrawLimit:5000 *10**18
         }));
         tokens.push(Token({
            name : "WETH",
            tokenAddress : IERC20(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619),
            depositFee:5,
            collectedFee:0,
            withdrawLimit:5000 *10**18
         }));
    }

///////////// User Functions ////////////////////////////////////////////////////////////////////////////////

    //allow users to deposit Star Tokens to the Game account to increase their allowance.
    function depositToken(uint _pid,uint _amount) public returns(uint,uint){
        Token storage token = tokens[_pid]; //get the instance of the token being used
        UserInfo storage User = userInfo[_pid][msg.sender]; //get the userinfo table for the user
        bool success;
        require (token.tokenAddress.balanceOf(msg.sender) >= _amount, "Deposit amount is greater then your balance."); //check the user has atleast the amount of Token they are trying to deposit.
        (success) = token.tokenAddress.transferFrom(msg.sender, address(this), _amount); //transfer the funds from the user to the game.
        require(success, "Transfer failed."); //ensure transfer completed successfully 

        uint fee = _amount.mul(depositFee).div(100); //calculate the value of the transfer fee
        uint newAllowance = _amount.sub(fee); //calcualte the value remaining after the deposit fee.
        token.collectedFee = token.collectedFee.add(fee);// ad the fee to the collected fees tracker for the Token
        User.allowance = User.allowance.add(newAllowance); //add the transfered amount to the users Token Allowance
        User.totalBalance = User.totalBalance.add(newAllowance); //add the transfered amount to the users total tokens

        return(newAllowance,User.allowance);// return the amoutn added and the total allowance of the user.
    }

    //allow users to withdraw Star Tokens from the Game account to decrease their allowance.
    function withdrawTokens(uint _pid, uint _amount) public returns(uint){
        Token storage token = tokens[_pid];//get the instance of the token being used
        UserInfo storage User = userInfo[_pid][msg.sender];//get the userinfo table for the user
        require (User.allowance >= _amount, "Withdraw amount is greater then your current token Allowance"); //check the user has atleast the amount of Star allowance they are trying to withdraw.
        bool success;
        if(_amount > token.withdrawLimit){
            pendingWithdraws.push(PendingWithdraw({
                user: msg.sender,
                tokenPid: _pid,
                amount: _amount
            }));
            return(User.allowance);
        }
        (success) = token.tokenAddress.transferFrom(address(this),msg.sender,_amount); //transfer the funds from the game to the user.
        require(success, "Transfer failed."); //ensure transfer completed successfully 

        User.allowance = User.allowance.sub(_amount); //remove the transfered amount from the users token allowance
        User.totalBalance = User.totalBalance.sub(amount); // remove the trasnfered amount from the users total balance

        return(User.allowance);//return the users remaining balance
    }

    //Stake tokens to a rift
    function stakeTokens(uint _pid, uint_amount) public returns (unit){
        Token storage token = tokens[_pid];//get the instance of the token being used
        require(token.allowance >= _amount,"Token Allowance is to low");
        token.amountStaked = token.amountStaked.add(_amount);
        token.allowance = token.allowance.sub(_amount);
        return(token.amountStaked);
    }

    //Buy item
    function purchase(uint _pid, uint _amount) public returns (uint){
        Token storage token = tokens[_pid];//get the instance of the token being used
        UserInfo storage User = userInfo[_pid][msg.sender];//get the userinfo table for the user
        require(User.allowance >= _amount, "Allowance is to low.");
        User.allowance = User.allowance.sub(amount); //Remove spent amount from allowance
        User.totalBalance = User.totalBalance.sub(amount); //Remove spent amount from allowance
        remainingReward = remainingReward.add(_amount);//add the spent amount to the games reward pool.
    }

  ////////User View Functions////////////////////////////////////////////////////////

    // users check thier current Token allowance
    function userGetAllowance(uint _pid) external view returns(uint){
        return (userInfo[_pid][msg.sender].allowance);
    }
    
    // users check thier total Token balance
    function userGetBalance(uint _pid) external view returns(uint){
        return (userInfo[_pid][msg.sender].totalBalance);
    }

    // users check thier current staked Token amount
    function userGetStaked(uint _pid) external view returns(uint){
        return(userInfo[_pid][msg.sender].amountStaked);
    }

/////////////////// Owner Funcitons /////////////////////////////////////////////////////////////////////////////////////////////

    //Add Rewards to contract
    function fund(uint _amount) external onlyOwner returns(uint){
        Token storage token = tokens[6];//get the instance of the Star token
        (bool success) = token.tokenAddress.transferFrom(address(owner),address.this,_amount); //trasnfer amount from owner to contract
        require(success, "Trasnfer Failed");//Ensure transfer was successful
        remainingReward = remainingReward.add(_amount); //increase the current reward pool by the added amount

        emit fundRewards(_amount, remainingReward);//emit event for funding reward pool
    }
/******************************************************************************************************************************************************
********************************************************************************************************* finish function ****************************/
    //Payout Rewards to users
    function payReward(uint _pid,address _user, uint _rewardAmount, uint _returnedAmount) external onlyOwner{
        UserInfo storage User = userInfo[_pid][_user];//get the userinfo table for the user return token
        UserInfo storage starUser = userInfo[6][_user];//get the userinfo table for the user return token
        require(remainingReward >= _rewardAmount,"Not enough Star available for rewards");
        starUser.allowance = starUser.allowance.add(_rewardAmount); //add the reward to the users allowance
        starUser.totalBalance = starUser.totalBalance.add(_rewardAmount); //add the reward to the users total balance
        remainingReward = remainingReward.sub(_rewardAmount);//remove the rewarded value fromt he remaining reward pool
        User.allowance = user.allowance.add(_returnedAmount);//add the returned staked value to the users allowance.
        User.amountStaked = User.amountStaked.sub(_returnedAmount);//remove the reutnred value from the currently staked amount.
    }

    //Approve a withdraw request greater thent he withdraw limit of the token
    function approveWithdraw(uint _withdrawPid) external onlyOwner returns(uint){
        PendingWithdraw storage pending = pendingWithdraws[_withdrawPid];//get instance of the withdraw being approved
        Token storage token = tokens[pending.tokenPid];//get the instance of the token being used
        UserInfo storage User = userInfo[pending.tokenPid][pending.user];//get the userinfo table for the user
        bool success;
        require (User.allowance >= pending.amount, "Withdraw amount is greater then your current Star Allowance"); //check the user has atleast the amount of Star allowance they are trying to withdraw.
        (success) = token.tokenAddress.transferFrom(address(this),pending.user,pending.amount); //transfer the funds from the game to the user.
        require(success, "Transfer failed."); //ensure transfer completed successfully 

        User.allowance = User.allowance.sub(pending.amount); //remove the transfered amount from the users token Allowance
        User.totalBalance = User.totalBalance.sub(pending.amount); //remove the transfered amount from the users token Allowance

        pendingWithdraws[_withdrawPid] = pendingWithdraws[pendingWithdraws.length-1];
        pendingWithdraws.pop();

        return(User.allowance);//return the users remaining balance
    }

    //Deny a withdraw request greater thent he withdraw limit of the token
    function denyWithdraw(uint _withdrawPid) external onlyOwner returns (uint){
        PendingWithdraw storage pending = pendingWithdraws[_withdrawPid]; //get instance of the withdraw being denied
        UserInfo storage User = userInfo[pending.tokenPid][pending.user];//get the userinfo table for the user

        pendingWithdraws[_withdrawPid] = pendingWithdraws[pendingWithdraws.length-1];
        pendingWithdraws.pop();

        return(User.allowance);//return the users remaining balance
    }

    //allow owner to update the deposit fee
    function setDepositFee(uint _pid,uint _newFee) external onlyOwner returns(uint,uint) {
        Token storage token = tokens[_pid];//get the instance of the token being used
        uint prevDepositFee = token.depositFee;
        token.depositFee = _newFee; // updatre teh deposit fee with the new value.

        emit depositFeeChange(prevDepositFee,token.depositFee); //emit an event with the old and new fees.
        return(prevDepositFee,token.depositFee);// return the old and new fees.
    }

    //set the max withdrawlimit per transaction
    function setwithdrawLimit(uint _pid, uint _amount) external onlyOwner {
        Token storage token = tokens[_pid];//get the instance of the token being used
        token.withdrawLimit = _amount;
    }

    //Add token to supported token array
    function addToken(string memory _name, address _address, uint _depositFee, uint _withdrawLimit) external onlyOwner{
        tokens.push(Token({
            name : _name,
            tokenAddress : IERC20(_address),
            depositFee:_depositFee,
            collectedFee:0,
            withdrawLimt: _withdrawLimit
         }));
    }

    //Collect fees
    function collectFee(uint _pid) external onlyOwner(){
        Token storage token = tokens[_pid];//get the instance of the token being used
        require(token.collectedFee > 0,"No fees to collect");//check that there is a balance to collect
        uint collectedAmount = token.collectedFee; //get current collected amount
        (bool success) = token.tokenAddress.tranfer(address(Owner), collectedAmount); //transfer the collected fees to the owner
        require(success,"transfer was not succesful"); //ensure the transfer was successful
        token.collectedFee = token.collectedFee.sub(collectedAmount); //Remove the collected amount from the collect fee tracker.
    }

  ////////Owner View Functions////////////////////////////////////////////////////////

    // get a users Token allowance.
    function getAllowance(uint _pid, address _user) external view onlyOwner returns(uint){
        return (userInfo[_pid][_user].allowance);
    }
    
    // get a users totaL Token balance.
    function getBalance(uint _pid, address _user) external view onlyOwner returns(uint){
        return (userInfo[_pid][_user].totalBalance);
    }
    
    // get a users staked Token balance.
    function getStakedAmount(uint _pid, address _user) external view onlyOwner returns(uint){
        return (userInfo[_pid][_user].amountStaked);
    }

    //get supported tokens
    function getTokens() external view onlyOwner returns(Token[] memory) {
        return(tokens);
    }
}
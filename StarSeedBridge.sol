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

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

//Interface with the Star Token contract functions
abstract contract StarInterface {
    function balanceOf(address account)virtual  public view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount)virtual  public returns (bool);
}

contract starSeed is Ownable{
    using SafeMath for uint256;

    uint private depositFee = 5; // the current deposit fee
    uint private prevDepositFee = 0; // the previous deposit fee
    uint private collectedFees = 0; // the previous deposit fee
    uint private withdrawLimit = 5000; //max wihtdraw wihtout approval
    address starAddress = 0x07999F927Ce5bFC882eD409c054c52B1fA50c0a6;
    address prevStarAddress = 0x0000000000000000000000000000000000000000;

    //map variables for tracking users deposits.
    mapping (address => uint) starAllowance; // user Star allowance
    mapping (address => uint) pendingWithdraw; // user pending withdraw

    //events emited to the blockchain
    event depositFeeChange(uint oldFee, uint newFee); //emit a event if the deposit fees for the contract are changed.
    event starContractChange(address oldAddress, address newAddress); //emit a event if the Star token address is changed.
    
    //Create an interface to Star Token contract
    StarInterface starContract;

     constructor() {   
         starContract = StarInterface(starAddress); //set the contract addresss for the Star token.
    }

    //Set the contract address for Star Token
    function setStarContractAddress(address _address) external onlyOwner {
        address oldAddress = prevStarAddress;
        prevStarAddress = starAddress;
        starAddress = _address;
        starContract = StarInterface(_address); //set the contract addresss for the Star token.
        emit starContractChange(oldAddress,_address);
    }

    //allow users to deposit Star Tokens to the Game account to increase their allowance.
    function depositStar(uint _amount) public returns(uint,uint){
        bool success;
        require (starContract.balanceOf(msg.sender) >= _amount, "Deposit amount is greater then your balance."); //check the user has atleast the amount of Star they are trying to deposit.
        (success) = starContract.transferFrom(msg.sender, address(this), _amount); //transfer the funds from the user to the game.
        require(success, "Transfer failed."); //ensure transfer completed successfully 

        uint fee = _amount.mul(depositFee).div(100); //calculate the value of the transfer fee
        uint newAllowance = _amount - fee; //calcualte the value remaining after the deposit fee.
        starAllowance[msg.sender] += newAllowance; //add the transfered amount to the users starAllowance

        return(newAllowance,starAllowance[msg.sender]);// return the amoutn added and the total allowance of the user.
    }
    //allow users to withdraw Star Tokens from the Game account to decrease their allowance.
    function withdrawStar(uint _amount) public returns(uint){
        bool success;
        if(_amount > withdrawLimit){
            pendingWithdraw[msg.sender] = _amount;
            return(pendingWithdraw[msg.sender]);
        }
        require (starAllowance[msg.sender] >= _amount, "Withdraw amount is greater then your current Star Allowance"); //check the user has atleast the amount of Star allowance they are trying to withdraw.
        (success) = starContract.transferFrom(address(this),msg.sender,_amount); //transfer the funds from the game to the user.
        require(success, "Transfer failed."); //ensure transfer completed successfully 

        starAllowance[msg.sender] -= _amount; //remoce the transfered amount from the users starAllowance

        return(starAllowance[msg.sender]);//return the users remaining balance
    }

    //allow owner to update the deposit fee
    function setDepositFee(uint _newFee) external onlyOwner returns(uint,uint) {
        prevDepositFee = depositFee; // set the previouse deposit fee equal to the current fee.
        depositFee = _newFee; // updatre teh deposit fee with the new value.

        emit depositFeeChange(prevDepositFee,depositFee); //emit an event with the old and new fees.
        return(prevDepositFee,depositFee);// return the old and new fees.
    }

    function setwithdrawLimit(uint _amount) external onlyOwner {
        withdrawLimit = _amount;
    }

    // get a users star allowance.
    function getAllowance(address user) external view onlyOwner returns(uint){
        return (starAllowance[user]);
    }

    // users check thier current allowance
    function userGetAllowance() external view returns(uint){
        return (starAllowance[msg.sender]);
    }

    function approveWithdraw(address user) external onlyOwner returns(uint){
        bool success;
        require (starAllowance[user] >= pendingWithdraw[user], "Withdraw amount is greater then your current Star Allowance"); //check the user has atleast the amount of Star allowance they are trying to withdraw.
        (success) = starContract.transferFrom(address(this),user,pendingWithdraw[user]); //transfer the funds from the game to the user.
        require(success, "Transfer failed."); //ensure transfer completed successfully 

        starAllowance[user] -= pendingWithdraw[user]; //remoce the transfered amount from the users starAllowance
        pendingWithdraw[user] = 0;

        return(starAllowance[user]);//return the users remaining balance
    }

    function denyWithdraw(address user) external onlyOwner returns (uint){
        pendingWithdraw[user] = 0;

        return(starAllowance[user]);
    }
}
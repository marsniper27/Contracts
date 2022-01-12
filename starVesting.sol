/*

─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
─██████████████─██████████████─██████████████─████████████████──────██████──██████─██████████████─██████████████─██████████████─██████████─██████──────────██████─██████████████─
─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░░░██──────██░░██──██░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░██─██░░██████████──██░░██─██░░░░░░░░░░██─
─██░░██████████─██████░░██████─██░░██████░░██─██░░████████░░██──────██░░██──██░░██─██░░██████████─██░░██████████─██████░░██████─████░░████─██░░░░░░░░░░██──██░░██─██░░██████████─
─██░░██─────────────██░░██─────██░░██──██░░██─██░░██────██░░██──────██░░██──██░░██─██░░██─────────██░░██─────────────██░░██───────██░░██───██░░██████░░██──██░░██─██░░██─────────
─██░░██████████─────██░░██─────██░░██████░░██─██░░████████░░██──────██░░██──██░░██─██░░██████████─██░░██████████─────██░░██───────██░░██───██░░██──██░░██──██░░██─██░░██─────────
─██░░░░░░░░░░██─────██░░██─────██░░░░░░░░░░██─██░░░░░░░░░░░░██──────██░░██──██░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─────██░░██───────██░░██───██░░██──██░░██──██░░██─██░░██──██████─
─██████████░░██─────██░░██─────██░░██████░░██─██░░██████░░████──────██░░██──██░░██─██░░██████████─██████████░░██─────██░░██───────██░░██───██░░██──██░░██──██░░██─██░░██──██░░██─
─────────██░░██─────██░░██─────██░░██──██░░██─██░░██──██░░██────────██░░░░██░░░░██─██░░██─────────────────██░░██─────██░░██───────██░░██───██░░██──██░░██████░░██─██░░██──██░░██─
─██████████░░██─────██░░██─────██░░██──██░░██─██░░██──██░░██████────████░░░░░░████─██░░██████████─██████████░░██─────██░░██─────████░░████─██░░██──██░░░░░░░░░░██─██░░██████░░██─
─██░░░░░░░░░░██─────██░░██─────██░░██──██░░██─██░░██──██░░░░░░██──────████░░████───██░░░░░░░░░░██─██░░░░░░░░░░██─────██░░██─────██░░░░░░██─██░░██──██████████░░██─██░░░░░░░░░░██─
─██████████████─────██████─────██████──██████─██████──██████████────────██████─────██████████████─██████████████─────██████─────██████████─██████──────────██████─██████████████─
─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

SPDX-License-Identifier: MIT

*/

pragma solidity ^0.8.11;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract starVesting is Ownable{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address immutable starCompany = 0xF60De76791c2F09995df52Aa1c6e2E7DcF1E75d7;
    address immutable second = 0xF826Bc629d859af67736671274BFbF0967E36729;
    address immutable starAddress = 0xC6e2e8395A671eE3f6f55177F8Fe5984D5dA7741;

    IERC20 Star;

    uint256 public starCompanyLockedStar = 0;   // Track locked star for the company address
    uint256 public secondLockedStar = 0;        // Track the locked star for the second address
    uint256 public starCompanyStarPerBlock = 0; // Number of star to release per block to star company, calculated when star locked
    uint256 public secondStarPerBlock = 0;      // Number of star to release per block to second, calculated when star locked
    uint256 public starCompanyLastEmit = 0;     // Track date of last emit
    uint256 public secondLastEmit = 0;          // Track date of last emit seperate trackers incase a transfer fails
    uint256 public unlockDate = 0;              // Date when all star will have been unlocked.
    uint256 public emitInterval = 259200;       // How often an emission of Star happens - every 3 days
    uint256 public avgTimePerBlock = 2250;       //number of ms/block on average

    modifier onlyCompany{
        require(starCompany == msg.sender || owner() == msg.sender, "Company: caller is not the owner or the Company wallet");
        _;
    }

    event lockedStar(uint256 totalLocked, uint256 starCompanyLocked, uint256 secondLocked, uint256 unlockDate);
    event updateBlockTime(uint256 newBlockTime);

    constructor(){
        Star = IERC20(starAdress); // set the Star interface
    }

    function lockStar(uint256 _starCompanyAmount, uint256 _secondAmount, uint _unlockDate) external onlyCompany{
        uint256 currentTime = block.timestamp;                                                      // get the current time.
        require(_unlockDate > currentTime && _unlockDate >= unlockDate, "Unlock date must be after current time and previous unlock date"); // ensure the unlock date is after the current date and atleast as far as previous unlock date
        uint256 totalAmount = _starCompanyAmount.add(_secondAmount);                                // the total amount being trasnfered and locked
        (bool success) = Star.transferFrom(msg.sender,address(this), totalAmount);                  //transfer Star tokens to the contract
        require(success, "Transfer of star failled ensure balance and allowance is high enough");   // check that the transfer was successfull
        uint256 timeTillUnlock = _unlockDate.sub(currentTime);                                      // calculate the number of second until unlock date
        uint256 blocksTillUnlock = timeTillUnlock.div(avgTimePerBlock.div(1000));                   // calculate the number of blocks until unlock date division by 1000 to convert form milliseconds to secconds
        starCompanyLockedStar = starCompanyLockedStar.add(_starCompanyAmount);                      // add the newly locked amount of star to the companies total
        starCompanyStarPerBlock = starCompanyLockedStar.div(blocksTillUnlock);                      // update the star released per block to the company based on new total and unlock date
        secondLockedStar = secondLockedStar.add(_secondAmount);                                     // add the newly locked amount of star to the second total
        secondStarPerBlock = secondLockedStar.div(blocksTillUnlock);                                // update the star released per block to second based on new total and unlock date

        emit lockedStar(totalAmount, _starCompanyAmount, _secondAmount, _unlockDate);               // emit an event with the locked star details
    }

    function emitStar() external onlyOwner{
        uint256 currentTime = block.timestamp;                                      // get the current time.
        if((starCompanyLastEmit.add(emitInterval)) >= currentTime){                 // check that emit interval has passed since last emit to company
            uint256 timepassed = currentTime.sub(starCompanyLastEmit);              // get number of seconds since last emission 
            uint256 blocksPassed = timepassed.div(avgTimePerBlock.div(1000));       // get number of blocks since last emission
            uint256 starToEmit = starCompanyStarPerBlock.mul(blocksPassed);         // get amount of star to emit
            (bool success) = Star.trasnfer(starCompany,starToEmit);                 // trasfer the amount of star to emit to the star company
            require(success, "Emission to Star Company Failed");                    // ensure the trasnfer was successfull
            starCompanyLockedStar = starCompanyLockedStar.sub(starToEmit);          // remove the emitted star from the companies locked star tracker
            starCompanyLastEmit = currentTime;                                      // update the last emitted time to the current time.
        }
        if((secondLastEmit.add(emitInterval)) >= currentTime){                      // check that emit interval has passed since last emit to second
            uint256 timepassed = currentTime.sub(secondLastEmit);                   // get number of seconds since last emission 
            uint256 blocksPassed = timepassed.div(avgTimePerBlock.div(1000));       // get number of blocks since last emission
            uint256 starToEmit = secondStarPerBlock.mul(blocksPassed);              // get amount of star to emit
            (bool success) = Star.trasnfer(second,starToEmit);                      // trasfer the amount of star to emit to the second
            require(success, "Emission to second Failed");                          // ensure the trasnfer was successfull
            secondLockedStar = secondLockedStar.sub(starToEmit);                    // remove the emitted star from the second locked star tracker
            secondLastEmit = currentTime;                                           // update the last emitted time to the current time.
        }
    }

    //update the average time per block incase network time changes significantly
    function setBlockTime(uint256 _ms) external onlyOwner{
        avgTimePerBlock = _ms;                                                      // update the aver time per blocks witht he new number of milliseconds
        uint256 currentTime = block.timestamp;                                      // get the current time.
        uint256 timeTillUnlock = unlockDate.sub(currentTime);                       // calculate the number of second until unlock date
        uint256 blocksTillUnlock = timeTillUnlock.div(avgTimePerBlock.div(1000));   // calculate the number of blocks until unlock date division by 1000 to convert form milliseconds to secconds
        starCompanyStarPerBlock = starCompanyLockedStar.div(blocksTillUnlock);      // update the star released per block to the company based on new total and unlock date
        secondStarPerBlock = secondLockedStar.div(blocksTillUnlock);                // update the star released per block to second based on new total and unlock date

        emit updateBlockTime(_ms);w
    }

}
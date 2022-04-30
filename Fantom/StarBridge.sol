// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract StarBridge is Ownable{
    using SafeMath for uint256;

    function toFantom(address to, uint256 amount)external onlyOwner{

    }
}
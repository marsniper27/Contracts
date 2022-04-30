// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Interface with the SpaceStation NFT contracts functions
abstract contract maiInterface {
    function transferFrom(address from, address to, uint256 amount) virtual external returns (bool);
}

contract MyToken is ERC20, ERC20Burnable, Ownable {
    using SafeMath for uint256;

    ERC20 mai;

    address constant maiAddress =  0xfB98B335551a418cD0737375a2ea0ded62Ea213b;

    constructor() ERC20("Star Dollar", "STARD") {
        _mint(msg.sender, 100000 * 10 ** decimals());
        mai = ERC20(maiAddress);
    }

    function swapIn(address to, uint256 amount)external nonReentrant {
        require(amount!=0, "swapIn: invalid amount");        
        require(maiInterface.trasnferFrom(to,address(this),amount),"Mai Transfer failed");
        uint256 mintAmount = (amount.mul(997)).div(1000);
        _mint(to, mintAmount);
    }
 
    function swapOut(uint256 amount) external nonReentrant{
        require(amount!=0, "swapOut: invalid amount");
        require(mai.balanceOf(address(this))>=amount, "swapOut: Not enough miMatic in reserves");

        burnFrom(msg.sender,address(this),amount);
        mai.transfer(msg.sender,amount);
        
    }

    function withdraw(uint256 amount)external onlyOwner{
        require(amount!=0, "swapOut: invalid amount");
        uint256 maiBalance = mai.balanceOf(address(this));
        require(maiBalance >= amount, "withdraw: Not enough miMatic in reserves");
        require(maiblance.sub(totalSupply())>=amount, "withdraw: Not enough miMatic in reserves");
        mai.transfer(owner(),amount);
    }
}
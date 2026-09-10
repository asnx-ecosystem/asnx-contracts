// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ASNX is ERC20, Ownable {
    
    // Token Parameters
    uint256 private constant _maxSupply = 100000000 * 10**18; // 100,000,000 Max Supply
    uint256 private constant _circulatingSupply = 80000000 * 10**18; // 80,000,000 Initial Circulating
    uint256 private constant _totalLockAmount = 20000000 * 10**18; // 20,000,000 Total Locked Tokens
    
    // Vesting / Lock Parameters
    uint256 public lockStartTime;
    uint256 public constant cliffDuration = 365 days;
    uint256 public constant releaseInterval = 365 days;
    uint256 public constant totalSlices = 10;
    
    uint256 public tokensWithdrawn;
    address public lockBeneficiary;

    constructor(address initialOwner) 
        ERC20("ASNX", "ASX") 
        Ownable(initialOwner) 
    {
        lockBeneficiary = initialOwner;
        lockStartTime = block.timestamp;

        // 80% Supply Owner ke paas (Circulating)
        _mint(initialOwner, _circulatingSupply);
        
        // 20% Supply Contract me Lock
        _mint(address(this), _totalLockAmount);
    }

    function maxSupply() public pure returns (uint256) {
        return _maxSupply;
    }

    function getVestedAmount() public view returns (uint256) {
        if (block.timestamp < lockStartTime + cliffDuration) {
            return 0;
        }

        uint256 timePassedAfterCliff = block.timestamp - (lockStartTime + cliffDuration);
        
        uint256 currentSlice = (timePassedAfterCliff / releaseInterval) + 1;

        if (currentSlice >= totalSlices) {
            return _totalLockAmount;
        }

        return (_totalLockAmount * currentSlice) / totalSlices;
    }

    function releaseLockedTokens() external onlyOwner {
        uint256 totalVested = getVestedAmount();
        
        uint256 claimableAmount = totalVested - tokensWithdrawn;
        
        require(claimableAmount > 0, "No tokens available for release at this time!");

        tokensWithdrawn += claimableAmount;
        _transfer(address(this), lockBeneficiary, claimableAmount);
    }
}

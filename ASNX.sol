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
    uint256 public constant cliffDuration = 365 days; // 1 Year Cliff (Pehle saal 0% unlock)
    uint256 public constant releaseInterval = 365 days; // Har 1 saal baad unlock hoga
    uint256 public constant totalSlices = 10; // 10 saal me poora 100% (Har saal 10%)
    
    uint256 public tokensWithdrawn; // Ab tak kitne tokens nikaale ja chuke hain
    address public lockBeneficiary;

    constructor(address initialOwner) 
        ERC20("ASNX", "ASX") 
        Ownable(initialOwner) 
    {
        lockBeneficiary = initialOwner;
        lockStartTime = block.timestamp; // Deployment ka samay hi start time hai

        // 80% Supply Owner ke paas (Circulating)
        _mint(initialOwner, _circulatingSupply);
        
        // 20% Supply Contract me Lock (Vesting ke liye)
        _mint(address(this), _totalLockAmount);
    }

    function maxSupply() public pure returns (uint256) {
        return _maxSupply;
    }

    // Yeh function hisaab lagayega ki aaj ki date tak kitne % tokens unlock ho chuke hain
    function getVestedAmount() public view returns (uint256) {
        // Agar 1 saal (Cliff period) poora nahi hua hai toh 0 tokens unlock honge
        if (block.timestamp < lockStartTime + cliffDuration) {
            return 0;
        }

        // Cliff ke baad kitna samay beeta hai
        uint256 timePassedAfterCliff = block.timestamp - (lockStartTime + cliffDuration);
        
        // Kitne saal beete hain (1 saal ka interval)
        // +1 isliye kyunki 1 saal khatam hote hi pehla 10% turant mil jayega
        uint256 currentSlice = (timePassedAfterCliff / releaseInterval) + 1;

        // Agar 10 saal se upar ho chuka hai, toh poora amount unlock
        if (currentSlice >= totalSlices) {
            return _totalLockAmount;
        }

        // Har saal 10% ke hisaab se amount calculate karna
        return (_totalLockAmount * currentSlice) / totalSlices;
    }

    // Lock tokens ko withdraw karne ka function
    function releaseLockedTokens() external onlyOwner {
        uint256 totalVested = getVestedAmount();
        
        // Kitne tokens abhi nikalne ke liye available hain
        uint256 claimableAmount = totalVested - tokensWithdrawn;
        
        require(claimableAmount > 0, "No tokens available for release at this time!");

        tokensWithdrawn += claimableAmount;
        _transfer(address(this), lockBeneficiary, claimableAmount);
    }
}
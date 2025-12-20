# EtherGame - Force ETH Balance Manipulation Vulnerability

## Overview

This document explains a critical security vulnerability in the `EtherGame` contract where an attacker can manipulate the contract's ETH balance using the `selfdestruct()` function, breaking the game's logic and preventing anyone from winning.

## Vulnerability Type

**Force ETH via selfdestruct Balance Manipulation**

## The Core Concept

The `selfdestruct()` function in Solidity has a unique capability:
1. It deletes a contract from the blockchain (pre-Cancun) or transfers its ETH (post-Cancun)
2. It **forces** any ETH in that contract to be sent to a specified address

**The Critical Point:** `selfdestruct()` bypasses normal ETH transfer rules. Even if a contract doesn't have a `receive()` or `fallback()` function, `selfdestruct()` can force ETH into it.

## The Vulnerability in EtherGame

### How the Game Should Work

The `EtherGame` contract implements a simple game:
- Players deposit exactly 1 ETH at a time
- The goal is to be the 7th player to deposit (when balance reaches 7 ETH)
- The winner can claim all ETH in the contract

### The Flawed Logic

```solidity
function deposit() public payable {
    require(msg.value == 1 ether, "You can only send 1 Ether");
    
    uint balance = address(this).balance;
    require(balance <= targetAmount, "Game is over");
    
    if (balance == targetAmount) {
        winner = msg.sender;
    }
}
```

The contract relies on `address(this).balance` to determine:
- If the game is still active (`balance <= targetAmount`)
- If a winner should be declared (`balance == targetAmount`)

**This is the vulnerability:** The contract assumes balance can only increase through legitimate `deposit()` calls.

## The Attack

### Step-by-Step Exploitation

1. **Setup:** Two players deposit 1 ETH each (balance = 2 ETH)
2. **Deploy Attack Contract:** Attacker deploys the `Attack` contract with `EtherGame` address
3. **Execute Attack:** Attacker calls `attack()` with 5 ETH
4. **Force ETH:** The `Attack` contract self-destructs, forcing 5 ETH into `EtherGame`
5. **Game Broken:** `EtherGame` now has 7 ETH, but **no winner was ever set**

### Why It Works

```solidity
function attack() public payable {
    address payable addr = payable(address(etherGame));
    selfdestruct(addr);
}
```

When `selfdestruct(addr)` executes:
- 5 ETH is forced into `EtherGame` **without calling `deposit()`**
- The balance check `if (balance == targetAmount)` in deposit never triggers
- Now `balance = 7 ether`, so `require(balance <= targetAmount)` fails
- **No one can deposit anymore, and no winner exists**

### Impact

- Game is permanently broken
- All deposited ETH is locked (winner can't be set, so `claimReward()` always fails)
- Denial of Service attack succeeds

## Code Analysis

### Vulnerable Contract
```solidity
contract EtherGame {
    uint public targetAmount = 7 ether;
    address public winner;

    function deposit() public payable {
        require(msg.value == 1 ether, "You can only send 1 Ether");
        
        uint balance = address(this).balance;  // ❌ Vulnerable line
        require(balance <= targetAmount, "Game is over");
        
        if (balance == targetAmount) {         // ❌ Never triggers after attack
            winner = msg.sender;
        }
    }
}
```

### Attack Contract
```solidity
contract Attack {
    EtherGame etherGame;

    constructor(EtherGame _etherGame) {
        etherGame = EtherGame(_etherGame);
    }

    function attack() public payable {
        address payable addr = payable(address(etherGame));
        selfdestruct(addr);  // Forces ETH into EtherGame
    }
}
```

## Prevention

### ❌ Don't Do This
```solidity
// Never rely on address(this).balance for critical logic
uint balance = address(this).balance;
if (balance == targetAmount) {
    // Critical logic here
}
```

### ✅ Do This Instead
```solidity
// Track balance internally with a state variable
uint public depositedBalance;

function deposit() public payable {
    require(msg.value == 1 ether, "You can only send 1 Ether");
    
    depositedBalance += msg.value;  // Track deposits ourselves
    require(depositedBalance <= targetAmount, "Game is over");
    
    if (depositedBalance == targetAmount) {
        winner = msg.sender;
    }
}
```

## Key Takeaways

1. **Never rely on `address(this).balance`** for critical contract logic
2. **Track balances internally** using state variables that you control
3. **Assume attackers can force ETH** into your contract via `selfdestruct()`
4. **Design defensively** - consider all possible ways contract state can change

## ⚠️ Deprecation Notice

As of the **Cancun hard fork (EIP-6780)**, `selfdestruct()` behavior has changed:

**Old Behavior (Pre-Cancun):**
- Deleted contract code and data
- Sent all ETH to specified address

**New Behavior (Post-Cancun):**
- Does **NOT** delete contract code/data anymore
- Only transfers ETH to beneficiary
- Exception: Still deletes if called in the **same transaction** the contract was created

**Important:** The force ETH vulnerability demonstrated here **still applies** in post-Cancun, but `selfdestruct()` is deprecated and discouraged in new contracts.

## References

- [Solidity by Example - Self Destruct](https://solidity-by-example.org/hacks/self-destruct/)
- [EIP-6780: SELFDESTRUCT only in same transaction](https://eips.ethereum.org/EIPS/eip-6780)
- Solidity Warning: `selfdestruct has been deprecated (solidity(5159))`

## Disclaimer

This code is for **educational purposes only** to demonstrate historical vulnerabilities and security best practices in smart contract development. Do not use `selfdestruct()` in production contracts.
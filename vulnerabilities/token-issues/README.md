# Token Issues and ERC-20 Vulnerabilities

Token standards like ERC-20 provide a common interface for fungible tokens on Ethereum. However, not all tokens follow the standard strictly, and some have unexpected behaviors that can break integrations and DeFi protocols.

## The ERC-20 Standard

The ERC-20 standard defines:
- `transfer(address to, uint256 amount)` → returns bool
- `transferFrom(address from, address to, uint256 amount)` → returns bool
- `approve(address spender, uint256 amount)` → returns bool
- `balanceOf(address account)` → returns uint256
- `allowance(address owner, address spender)` → returns uint256

However, many tokens deviate from this standard in practice.

## What are "Weird" ERC-20 Tokens?

"Weird" ERC-20 tokens are tokens that:
1. Don't strictly follow the ERC-20 standard
2. Have non-standard behaviors
3. Can break protocols that assume standard compliance
4. May have security implications for integrators

## Types of Token Issues

This directory contains examples and explanations of problematic token behaviors:

### [Weird ERC-20s](./weird-erc20/)
Collection of non-standard ERC-20 token behaviors and how they can break integrations.

## Common Weird Token Behaviors

### Missing Return Values
Some tokens (like USDT) don't return a boolean from `transfer()` and `approve()`, causing reverts when strict compliance is expected.

### False Return Values
Tokens that return `false` instead of reverting on failure. Many protocols don't check return values.

### Fee-on-Transfer Tokens
Tokens that deduct a fee on every transfer, meaning received amount ≠ sent amount.

### Rebasing Tokens
Tokens where balances automatically change (e.g., stETH, AMPL), breaking assumptions about fixed balances.

### Blacklist Mechanisms
Tokens with blacklist functionality that can freeze specific addresses.

### Pausable Tokens
Tokens that can be paused, stopping all transfers.

### Multiple Entry Points
Tokens with multiple transfer functions beyond the standard interface.

### Decimals Variations
Most tokens use 18 decimals, but some use different values (USDC uses 6), requiring careful handling.

### Proxy Tokens
Upgradeable tokens where implementation can change, altering behavior.

### Deflationary/Inflationary Tokens
Tokens that burn or mint automatically, changing total supply.

## Prevention Strategies

1. **SafeERC20**: Use OpenZeppelin's SafeERC20 library
2. **Balance Checks**: Compare balances before/after transfers instead of trusting amounts
3. **Whitelist Approach**: Support only vetted, standard-compliant tokens
4. **Handle Edge Cases**: Test with known weird tokens (USDT, USDC, etc.)
5. **Return Value Checks**: Always check return values from token operations
6. **Reentrancy Guards**: Protect against tokens with callbacks
7. **Documentation**: Clearly state which token types are supported

## Testing with Weird Tokens

Known tokens to test compatibility:
- **USDT**: Missing return value
- **BNB**: Non-standard implementation
- **OMG**: transfer() returns boolean but transfers can fail
- **Ampleforth (AMPL)**: Rebasing token
- **stETH**: Balance changes over time
- **USDC**: 6 decimals, blacklist, pausable

## Impact

Token incompatibility can lead to:
- Locked funds in protocols
- Incorrect accounting
- Failed transactions
- Unexpected reverts
- Economic exploits
- Protocol insolvency

## Real-World Issues

Many DeFi protocols have suffered from weird token behaviors:
- Protocols locking fee-on-transfer tokens
- Rebasing tokens breaking AMM invariants
- Missing return values causing integration failures

## Resources

- [Weird ERC-20 Tokens Repository](https://github.com/d-xo/weird-erc20)
- [OpenZeppelin: SafeERC20](https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#SafeERC20)
- [Token Integration Checklist](https://github.com/crytic/building-secure-contracts/blob/master/development-guidelines/token_integration.md)

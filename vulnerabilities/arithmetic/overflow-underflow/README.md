# Integer Overflow and Underflow

## Introduction
Integer overflow and underflow occur when an arithmetic operation attempts to create a numeric value that is outside of the range that can be represented with a given number of bits.

- **Overflow**: Adding to the maximum value wraps around to zero.
    - Example (`uint8`): `255 + 1 = 0`
- **Underflow**: Subtracting from the minimum value (zero for unsigned) wraps around to the maximum value.
    - Example (`uint8`): `0 - 1 = 255`

## Solidity 0.8.0+ Behavior
Prior to Solidity 0.8.0, arithmetic operations would silently wrap. Developers had to use libraries like **SafeMath** to prevent this.

**Solidity 0.8.0 and later automatically revert on overflow/underflow.**

However, vulnerabilities still exist in two main cases:
1. **`unchecked` blocks**: Developers use `unchecked { ... }` to save gas by skipping these validation checks. If the math is not actually safe, overflows return.
2. **Casting**: Explicitly casting larger types to smaller types (e.g., `uint256` to `uint64`) truncates the higher bits, which effectively acts like an overflow/modulo operation.

## Code Example

[OverflowUnderflow.sol](../src/OverflowUnderflow.sol)

```solidity
// Casting a large fee to uint64 can truncate it (data loss)
// Inside unchecked, addition can wrap around
function addFee(uint256 fee) external {
    unchecked {
        //@Audit: overflow possible here
        totalFees = totalFees + uint64(fee);
    }
}
```

If `totalFees` is close to `type(uint64).max`, adding even a small fee can cause it to reset to a small number, effectively erasing the accumulated fees.

## Risk Assessment
- **Likelihood**: Medium (Common in gas-optimized code or complex math).
- **Impact**: High (Incorrect balances, broken logic, locked funds).

## Prevention
1. **Rely on Solidity 0.8.0+ defaults**: Do not use `unchecked` unless you are mathematically certain overflow is impossible.
2. **Avoid dangerous casting**: Be careful when casting from larger to smaller types. Check that `value <= type(smallType).max` before casting.
3. **Use SafeMath (Legacy)**: If working with Solidity versions < 0.8.0, always use OpenZeppelin's `SafeMath`.

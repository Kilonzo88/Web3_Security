# Denial of Service (DoS) Attack

## Vulnerability Explanation
In the `DOS.sol` contract, the `enter()` function contains a Denial of Service (DoS) vulnerability caused by an unbounded loop. The function iterates through the entire `entrants` array to check if the `msg.sender` has already entered:

```solidity
for (uint256 i; i < entrants.length; i++) {
    if (entrants[i] == msg.sender) {
        revert("You've already entered!");
    }
}
```

As the number of `entrants` increases, the gas cost to execute this loop grows linearly. The Ethereum block gas limit restricts the amount of computation that can happen in a single transaction.

## Attack Scenario
1. An attacker (or multiple users) calls `enter()` many times.
2. The `entrants` array grows large.
3. Eventually, the gas required to iterate through the array exceeds the block gas limit.
4. New legitimate users attempting to call `enter()` will have their transactions revert due to "Out of Gas" errors, effectively locking them out of the contract.

## Mitigation
To prevent this, use a `mapping` to track entered addresses. Mappings provide constant time O(1) lookups, ensuring the gas cost does not increase with the number of entrants.

```solidity
mapping(address => bool) public entered;

function enter() public {
    require(!entered[msg.sender], "You've already entered!");
    entered[msg.sender] = true;
    entrants.push(msg.sender);
}
```

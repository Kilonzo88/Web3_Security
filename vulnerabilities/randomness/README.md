# Randomness Vulnerabilities

Generating truly random numbers on a deterministic blockchain is fundamentally challenging. Randomness vulnerabilities occur when contracts use predictable or manipulable sources of randomness for critical operations like lotteries, NFT minting, or game outcomes.

## The Problem with On-Chain Randomness

Blockchains are deterministic systems by design:
1. All nodes must reach consensus on the same state
2. Transaction outcomes must be reproducible
3. All on-chain data is public and accessible
4. Miners/validators can influence certain blockchain parameters

This makes generating secure randomness extremely difficult.

## What are Randomness Vulnerabilities?

Randomness vulnerabilities occur when:
1. Contracts use predictable sources like `block.timestamp` or `blockhash`
2. Miners can manipulate the source of randomness
3. Users can predict outcomes before committing
4. Random values can be extracted from on-chain data

## Types of Randomness Vulnerabilities

This directory contains examples and explanations of randomness vulnerabilities:

### [Weak Randomness](./weak-randomness/)
Examples of commonly used but insecure randomness sources in smart contracts and how they can be exploited.

## Common Weak Random Sources

### ❌ Block Timestamp
```solidity
uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp)));
```
- Miners can manipulate timestamps within limits
- Predictable once block is mined
- Can be front-run

### ❌ Block Hash
```solidity
uint256 random = uint256(blockhash(block.number - 1));
```
- Only accessible for last 256 blocks
- Returns 0 for older blocks
- Miners can influence by withholding blocks

### ❌ Block Difficulty
```solidity
uint256 random = block.difficulty;
```
- Predictable for upcoming blocks
- Validators can influence

### ❌ Combining Multiple Sources
Even combining weak sources doesn't make them secure - if each component is predictable, the combination remains predictable.

## Secure Randomness Solutions

### ✅ Chainlink VRF (Verifiable Random Function)
The gold standard for on-chain randomness:
- Cryptographically secure
- Verifiable on-chain
- Tamper-proof
- Industry standard

### ✅ Commit-Reveal Schemes
Two-phase approach:
1. **Commit**: Users submit hash of their choice
2. **Reveal**: After commit period, reveal actual value
3. **Combine**: Use revealed values to generate randomness

Limitations: Requires multi-transaction flow, vulnerable to last-revealer attack

### ✅ VDF (Verifiable Delay Functions)
Functions that take a precise amount of time to compute, making them difficult to manipulate.

### ✅ Off-Chain Randomness with Proofs
Generate randomness off-chain and prove its validity on-chain using zero-knowledge proofs or MPC.

## Prevention Strategies

1. **Use Chainlink VRF**: For production applications requiring secure randomness
2. **Commit-Reveal**: For simple use cases where multi-step is acceptable
3. **Avoid Native Sources**: Never use `block.timestamp`, `blockhash`, etc. for critical randomness
4. **Economic Security**: Ensure manipulation cost exceeds potential gain
5. **Time Delays**: Separate randomness generation from its usage

## Impact

Weak randomness can lead to:
- Predictable lottery outcomes
- Unfair NFT distributions
- Exploitable game mechanics
- Rigged gambling results
- Front-running attacks

## Real-World Exploits

- **Meebits NFT**: Exploited block hash randomness for rare traits
- **Various Lotteries**: Predicted outcomes using block data
- **PvP Games**: Players predicting outcomes before committing

## Resources

- [Chainlink VRF Documentation](https://docs.chain.link/vrf/v2/introduction)
- [SWC-120: Weak Sources of Randomness](https://swcregistry.io/docs/SWC-120)
- [Paradigm: On-Chain Random Number Generation](https://www.paradigm.xyz/2020/10/a-guide-to-designing-effective-nft-launches)

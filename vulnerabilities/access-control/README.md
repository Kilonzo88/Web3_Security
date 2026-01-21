# Access Control Vulnerabilities

Access control vulnerabilities occur when smart contracts fail to properly restrict who can call certain functions or access specific functionality. These vulnerabilities can lead to unauthorized actions, fund theft, and complete protocol compromise.

## What is Access Control?

Access control in smart contracts involves:
1. Defining who can execute privileged functions
2. Implementing proper authorization checks
3. Managing roles and permissions
4. Protecting critical state-changing operations

## Common Access Control Issues

### Missing Access Control
Functions that should be restricted are left public, allowing anyone to call them.

### Incorrect Modifiers
Using wrong modifiers or implementing custom checks incorrectly.

### Front-Running Admin Functions
Public functions that can be called by anyone before proper initialization.

### Default Visibility
Relying on default function visibility instead of explicitly declaring it.

## Types of Access Control Vulnerabilities

This directory contains examples and explanations of access control vulnerabilities:

### [Missing Access Control](./missing-access-control/)
Functions that lack proper authorization checks, allowing unauthorized users to execute privileged operations.

## Prevention Strategies

1. **Explicit Visibility**: Always explicitly declare function visibility
2. **Use Modifiers**: Implement and use access control modifiers (e.g., `onlyOwner`)
3. **Role-Based Access Control (RBAC)**: Use battle-tested libraries like OpenZeppelin's `AccessControl`
4. **Principle of Least Privilege**: Grant minimum necessary permissions
5. **Multi-Sig for Critical Operations**: Require multiple approvals for sensitive actions
6. **Time-Locks**: Add delays for admin operations to allow community review

## Impact

Access control vulnerabilities can result in:
- Unauthorized fund withdrawals
- Contract ownership takeover
- Manipulation of critical parameters
- Protocol governance bypass
- Complete loss of funds

## Best Practices

- **OpenZeppelin Contracts**: Use proven access control libraries
- **Constructor Checks**: Ensure proper initialization with correct owners
- **Events**: Emit events for all privileged operations
- **Testing**: Thoroughly test authorization logic
- **Audit**: Have access control logic professionally audited

## Resources

- [OpenZeppelin: Access Control](https://docs.openzeppelin.com/contracts/4.x/access-control)
- [SWC-105: Unprotected Ether Withdrawal](https://swcregistry.io/docs/SWC-105)
- [SWC-106: Unprotected SELFDESTRUCT](https://swcregistry.io/docs/SWC-106)

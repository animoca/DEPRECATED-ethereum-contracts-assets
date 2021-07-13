# Changelog

## 1.1.3

### Improvements
 * `ERC20ReceiverMock.sol` now has an approved token address and reverts if the call originates from another address.
 ## 1.1.2

### Fixes
 * Updated dependencies for fixing yarn audit warnings and warning messages during tests.

## 1.1.1

### Fixes
 * Updated artifacts.

## 1.1.0

### Improvements
 * Updated dependency version `@animoca/ethereum-contracts-core@1.1.0`.
 * Increased tests coverage for the bridging setup and the function `batchBurnFrom`.
 * Removed the possibility to update the manager's address in the ERC20 predicates and ERC20 child tokens to improve decentralisation.

### Fixes
 * Usage of `ERC20Wrapper` in `ERC20EscrowPredicate.sol`.
 * Fixed and optimised the implementation of `batchBurnFrom` to correctly update the supply.
 * Verify who is the caller of `onERC20Received` in the ERC20 predicates.

## 1.0.2

### Fixes
* Added missing artifacts folder.
* Fixed ABIs exports.

## 1.0.0

* Initial commit.

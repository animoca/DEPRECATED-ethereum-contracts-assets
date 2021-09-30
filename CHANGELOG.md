# Changelog

## 2.0.0

### Breaking Changes

- Removed unused contract `IERC721Enumerable.sol`, `IERC721Exists.sol` and `PausableCollections.sol`.
- Extracted out events from `IERC721.sol` to `IERC721Events.sol` to allow proper interface inheritance between `IERC721` and `IERC1155`.
- Extracted out inventory functions from `IERC1155Inventory.sol` to new file `IERC1155InventoryFunctions.sol`.
- Added inherited `IERC1155` functions which carry documentation changes in `IERC1155Inventory.sol` to properly use `@inheritdoc`.
- Removed `IERC1155721.sol` and `IERC1155721BatchTransfer.sol`.
- Changed `IERC1155721Inventory.sol` inheritance so that it contains functions which carry documentation changes to properly use `@inheritdoc`.
- Extracted out `ERC1155InventoryIdentifiersLib` from `ERC1155InventoryBase.sol`  to be new file `ERC1155InventoryIdentifiersLib.sol`.
- Removed the `tokenURI` argument from the `ERC20` constructor to avoid "stack too deep" errors in the constructor when building a full-featured contract.
- Added `Recoverable` and `UsingUniversalForwarding` features to mocks based on ERC721 and ERC1155.
- Added `MinterRole` feature to mocks based on ERC20.
- Removed obsolete ERC165 interfaces and abis and added missing ones in javascript module exports. Renamed some of them to remove `_experimental`.
- Removed ERC165 interfaces from `constants` javascript module exports.

### New Features

- Added GitHub scripts for CI tests and coverage, with codecov integration.
- Added markdown linting.

### Bug Fixes

- `ERC721.sol`, `ERC1155721Inventory.sol`: correctly removed the approval bit when calling `approve(address,bool)` with the zero address.

### Improvements

- Used the `@inheritdoc` tag where applicable. Standardised and improved overall documentation.
- Added missing tests to bring coverage to 100%. Reorganised some tests for clarity.
- Organised functions in solidity contracts based on the interface they implement.
- `IERC1155InventoryFunctions.sol` and `IERC1155Inentory.sol`: visibility for functions `isFungible(uint256)` and `collectionOf(uint256)` has been changed to `view` to give more flexbility to the implementer.
- `ERC721ReceiverMock.sol`, `ERC1155TokenReceiverMock.sol`: added a sender check in the receiving functions.
- `ERC721.sol`: Removed unused `values` array in `batchTransferFrom(address,uint256[])`.
- `ERC20.sol`, `ERC20Burnable.sol`, `ChildERC20.sol` and `ChildERC20Burnable.sol`: removed unnecessary `abstract` keyword.

## 1.1.5

### Improvements

- Updated dependencies to the latest versions.

## 1.1.4

### Fixes

- Fixed the decoding of the Withdrawn event log in the ERC20 bridging predicates.

## 1.1.3

### Improvements

- `ERC20ReceiverMock.sol` now has an approved token address and reverts if the call originates from another address.

## 1.1.2

### Fixes

- Updated dependencies for fixing yarn audit warnings and warning messages during tests.

## 1.1.1

### Fixes

- Updated artifacts.

## 1.1.0

### Improvements

- Updated dependency version `@animoca/ethereum-contracts-core@1.1.0`.
- Increased tests coverage for the bridging setup and the function `batchBurnFrom`.
- Removed the possibility to update the manager's address in the ERC20 predicates and ERC20 child tokens to improve decentralisation.

### Fixes

- Usage of `ERC20Wrapper` in `ERC20EscrowPredicate.sol`.
- Fixed and optimised the implementation of `batchBurnFrom` to correctly update the supply.
- Verify who is the caller of `onERC20Received` in the ERC20 predicates.

## 1.0.2

### Fixes

- Added missing artifacts folder.
- Fixed ABIs exports.

## 1.0.0

- Initial commit.

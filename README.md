# Solidity Assets

[![Coverage Status](https://codecov.io/gh/animoca/ethereum-contracts-assets/graph/badge.svg)](https://codecov.io/gh/animoca/ethereum-contracts-assets)

This project serves as a base dependency for Solidity-based assets contract projects by providing related base contracts, constants, and interfaces.
The standards supported are ERC20, ERC721 and ERC1155. Different standard extensions are also available in order to easily build robust implementations.

## Overview

### Installation

Install as a module dependency in your host NodeJS project:

```bash
npm install --save-dev @animoca/ethereum-contracts-assets
```

or

```bash
yarn add -D @animoca/ethereum-contracts-assets
```

The `peerDependencies` from `package.json` also need to be installed and to follow the same naming convention.

### Usage

#### Solidity Contracts

This project contains base implementations and mocks for assets standards such as ERC20 (Fungible Token), ERC721 (Non-Fungible Token) and ERC1155 (Multi Token).
Some utility contracts such as the necessary for Polygon bridging or vouchers redemption mechanics are also provided.

Import dependency contracts into your Solidity contracts and derive as needed:

```solidity
import "@animoca/ethereum-contracts-assets/contracts/{{Contract Group}}/{{Contract}}.sol"
```

Please refer to inline documentation of each contract to get a glimpse of its purpose.
The mocks are examples of how to implement fully-featured contracts.

#### Javascript Modules

A set of Javascript modules are also provided.

Require the NodeJS module dependency in your test and migration scripts as needed:

```javascript
const { constants, interfaces, abis, behaviors } = require("@animoca/ethereum-contracts-assets");
```

- `constants`: project-specific constants.
- `interfaces`: ERC165 interfaces for supported standards.
- `abis`: the ABIs for the supported interfaces.
- `behaviors`: re-usable behavior functions which can be used to test contracts with a full coverage. Refer to mock test files for a guideline on how to test asset contracts using these behaviors.

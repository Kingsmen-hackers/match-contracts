# Match on Hedera

## Overview

Match is a decentralized platform built on the Hedera blockchain that seamlessly connects buyers and sellers, enabling a secure and efficient exchange of goods and services. Using smart contracts, Marketplace ensures transparency, reduces fraud, and provides immutable records for all transactions.

## Features

1. **User Registration**: Easily create profiles as a Buyer or Seller.
2. **Store Creation**: Sellers can create stores with custom information, including contact details and location.
3. **Request Management**: Buyers can post requests for services or products, specifying details and location.
4. **Offer Creation**: Sellers can respond to buyer requests by creating offers with pricing and images.
5. **Real-time Hedera Token Payments**: Secure and transparent payment process with USDC and HBAR.
6. **Price Feeds**: Integrates Chainlink for accurate conversion rates between HBAR and USD.
7. **Token Association**: Includes Hedera Token Service for USDC association to enable in-platform payments.
8. **Lifecycle Events**: Requests and Offers go through stages to provide clarity on transaction status.

## Architecture

The Marketplace is developed in Solidity, utilizing:

- **Hedera Token Service (HTS)** for associating the USDC token.
- **Chainlink Price Feeds** for HBAR/USD conversion rates.
- **Smart Contract Modules** to manage user profiles, stores, requests, and offers.

## Smart Contracts

- **Marketplace Contract**: Handles the core functionalities, including user and store creation, request and offer management, and payment handling.
- **Interfaces**:
  - `AggregatorV3Interface`: Fetches HBAR/USD price data.
  - `IERC20`: For token transfers and allowances.
  - `IHederaTokenService`: Allows token association with the contract.

## Getting Started

### Prerequisites

- **Node.js**: Recommended version >= 14.x
- **Hardhat**: For local testing and deployment.
- **Solidity**: Compiler version ^0.8.0
- **Chainlink**: To enable real-time price feeds.
- **Hedera Token Service**: For token management.

### Installation

1. **Clone the repository**:

   ```bash
   git clone https://github.com/Kingsmen-hackers/match-contracts
   cd match-contracts
   ```

2. **Install dependencies**:

   ```bash
   npm install
   ```

3. **Configure environment variables**:
   Set up your `.env` file with the following:

   - `OPERATOR_ID`: Your account id for Hedera network
   - `OPERATOR_KEY`: Your private key for the Hedera network.

4. **Compile and Deploy**:
   ```bash
   npx hardhat compile
   node index.js
   ```

### Usage

1. **Create a Buyer/Seller Profile**:
   Call the `createUser` function with relevant user details and account type.

2. **Create a Store (Sellers only)**:
   Sellers can call `createStore` to add a store with location data.

3. **Submit a Request (Buyers only)**:
   Buyers can submit a request by calling `createRequest` with required information.

4. **Respond with an Offer (Sellers)**:
   Sellers can respond to a request by calling `createOffer`, linking it to a request.

5. **Token Association**:
   Call `associateToken` with the USDC token address to ensure token compatibility.

### Events

- **UserCreated**: Triggered when a new user is registered.
- **StoreCreated**: Triggered upon new store creation.
- **RequestCreated**: Triggered when a buyer submits a request.
- **OfferCreated**: Triggered when a seller submits an offer.
- **RequestPaymentTransacted**: Records each payment transaction.

### Testing

Run tests to ensure contract functionality:

```bash
npm test
```

## Challenges & Future Enhancements

- **Multichain Support**: Expanding the platform to support other blockchain networks.
- **Token Selection Flexibility**: Allow users to choose from a variety of stablecoins for payment.

## Contributors

- **David** - Blockchain Developer [Davyking](https://github.com/Imdavyking)
- **Favour** - Frontend Developer [Sire](https://github.com/favourwright)

## License

This project is licensed under the MIT License.

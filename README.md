# NFTLease

## Overview
NFTLease is a **Clarity smart contract** that enables **NFT lending and renting** on the **Stacks blockchain**. Users can **list their NFTs for rent, pay rental fees, and track rental agreements** with built-in payment handling and time-based access control.

## Features
- **Minting NFTs**: Allows users to create new NFTs.
- **Listing NFTs for Rent**: NFT owners can set rental fees and periods.
- **Renting NFTs**: Users can rent listed NFTs by paying the required fee.
- **Ownership & Payment Enforcement**: Ensures only NFT owners can list for rent and deducts rental fees from renters' balances.
- **Secure Transactions**: Uses Clarity's **error handling and validation** mechanisms to prevent invalid transactions.

## Installation
Ensure you have the [Clarity Developer Tools](https://docs.stacks.co/build/smart-contracts) installed.

```sh
# Clone the repository
git clone https://github.com/yourusername/NFTLease.git
cd NFTLease

# Run tests
clarinet test
```

## Usage
### Mint an NFT
```clarity
(contract-call? .NFTLease mint-nft u1)
```

### List an NFT for Rent
```clarity
(contract-call? .NFTLease list-nft-for-rent u1 u5000 u100)
```
- `u1` → NFT ID
- `u5000` → Rental fee
- `u100` → Rental period (in blocks)

### Rent an NFT
```clarity
(contract-call? .NFTLease rent-nft u1)
```
- If successful, the NFT is rented for the specified period.

## Smart Contract Functions
| Function | Description |
|----------|------------|
| `mint-nft (id uint)` | Mints a new NFT and assigns it to the caller. |
| `list-nft-for-rent (nft-id uint, fee uint, rental-period uint)` | Allows NFT owners to list their NFTs for rent. |
| `rent-nft (nft-id uint)` | Allows users to rent NFTs by paying the required fee. |
| `get-nft-owner (nft-id uint)` | Returns the current owner of an NFT. |

## Contribution
1. Fork the repo.
2. Create a new branch: `git checkout -b feature/new-feature`
3. Commit changes: `git commit -m "Describe changes"`
4. Push to branch: `git push origin feature/new-feature`
5. Open a pull request.

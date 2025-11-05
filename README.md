# Convexo NFTs - Soulbound Token Contracts

Soulbound (non-transferable) NFT contracts for Compliant LPs and Vault creation, built with [Foundry](https://getfoundry.sh/) and OpenZeppelin.

## Quick Start

### Prerequisites

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Verify installation
forge --version
```

### Setup

```bash
# Clone and install dependencies
git clone https://github.com/Convexo-finance/convexo_contracts.git
cd convexo_contracts
forge install

# Configure environment
cp .env.example .env
# Edit .env with your keys and RPC URLs
```

### Environment Variables

Create `.env` file with:

```bash
PRIVATE_KEY=your_deployer_private_key
MINTER_ADDRESS=0xYourMinterAddress
ETHERSCAN_API_KEY=your_etherscan_api_key

# RPC URLs
UNICHAIN_SEPOLIA_RPC_URL=https://sepolia.uniwhale.io
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
ETHEREUM_SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_KEY
```

## Contracts

- **Convexo_LPs**: NFT for compliant LPs (KYB verification required)
- **Convexo_Vaults**: NFT for vault creation (credit score > 70)

Both contracts feature:
- ✅ Soulbound (non-transferable)
- ✅ State management (Active/Non-Active)
- ✅ Private company ID storage (admin-only)
- ✅ Individual token URIs (IPFS via Pinata)

## Build

```bash
forge build
```

## Test

```bash
# Run all tests
forge test

# Verbose output
forge test -vvv

# Gas report
forge test --gas-report
```

**Expected**: 36 tests passing (18 per contract)

## Deploy

### Automated Deployment (Recommended)

```bash
# Deploy both contracts to a network
./scripts/deploy-all.sh unichain_sepolia
./scripts/deploy-all.sh base_sepolia
./scripts/deploy-all.sh ethereum_sepolia
```

The script automatically:
- Deploys contracts
- Verifies on block explorer
- Updates `addresses.json`
- Extracts ABIs

### Manual Deployment

```bash
# Load environment
source .env

# Deploy Convexo_LPs
forge script script/DeployConvexoLPs.s.sol:DeployConvexoLPs \
    --rpc-url unichain_sepolia \
    --broadcast \
    --verify \
    --verifier etherscan \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    -vvvv

# Deploy Convexo_Vaults
forge script script/DeployConvexoVaults.s.sol:DeployConvexoVaults \
    --rpc-url unichain_sepolia \
    --broadcast \
    --verify \
    --verifier etherscan \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    -vvvv
```

## Verify

### Automatic Verification

Verification happens automatically during deployment with `--verify` flag.

### Manual Verification

```bash
# Verify Convexo_LPs
forge verify-contract <CONTRACT_ADDRESS> \
    src/convexolps.sol:Convexo_LPs \
    --chain-id 1301 \
    --verifier etherscan \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --constructor-args $(cast abi-encode "constructor(address,address)" \
        0x156d3C1648ef2f50A8de590a426360Cf6a89C6f8 $MINTER_ADDRESS)

# Verify Convexo_Vaults
forge verify-contract <CONTRACT_ADDRESS> \
    src/convexovaults.sol:Convexo_Vaults \
    --chain-id 1301 \
    --verifier etherscan \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --constructor-args $(cast abi-encode "constructor(address,address)" \
        0x156d3C1648ef2f50A8de590a426360Cf6a89C6f8 $MINTER_ADDRESS)
```

**Chain IDs:**
- Unichain Sepolia: `1301`
- Base Sepolia: `84532`
- Ethereum Sepolia: `11155111`

## Extract ABIs

```bash
./scripts/extract-abis.sh
```

ABIs saved to `abis/` directory:
- `Convexo_LPs.json`
- `Convexo_Vaults.json`
- `combined.json`

## Deployed Contracts

See `addresses.json` for all deployed contract addresses.

### Current Deployments

**Unichain Sepolia (1301)**
- Convexo_LPs: `0x4ACB3B523889f437D9FfEe9F2A50BBBa9580198d`
- Convexo_Vaults: `0xc056c0Ddf959b8b63fb6Bc73b5E79e85a6bFB9b5`

**Base Sepolia (84532)**
- Convexo_LPs: `0x4ACB3B523889f437D9FfEe9F2A50BBBa9580198d`
- Convexo_Vaults: `0xc056c0Ddf959b8b63fb6Bc73b5E79e85a6bFB9b5`

**Ethereum Sepolia (11155111)**
- Convexo_LPs: `0x4ACB3B523889f437D9FfEe9F2A50BBBa9580198d`
- Convexo_Vaults: `0xc056c0Ddf959b8b63fb6Bc73b5E79e85a6bFB9b5`

## Key Functions

### Minting (Minter Role)

```solidity
function safeMint(address to, string memory companyId, string memory uri) 
    returns (uint256)
```

### State Management (Admin Only)

```solidity
function setTokenState(uint256 tokenId, bool isActive)
function getTokenState(uint256 tokenId) returns (bool)
```

### Company ID (Admin Only)

```solidity
function getCompanyId(uint256 tokenId) returns (string memory)
```

### Token URI

```solidity
function tokenURI(uint256 tokenId) returns (string memory)
```

## Frontend Integration

```javascript
import ConvexoLPsABI from './abis/Convexo_LPs.json';
import addresses from './addresses.json';

// Connect to contract
const contract = new ethers.Contract(
  addresses[1301].convexo_lps.address,
  ConvexoLPsABI,
  provider
);

// Check if user has NFT
const balance = await contract.balanceOf(userAddress);
const hasNFT = balance > 0;

// Check token state
if (hasNFT) {
  const tokenId = 0; // Get actual token ID
  const isActive = await contract.getTokenState(tokenId);
}
```

## Network Information

| Network | Chain ID | Explorer |
|---------|----------|----------|
| Unichain Sepolia | 1301 | [Uniscan](https://uniscan.uniwhale.io) |
| Base Sepolia | 84532 | [BaseScan](https://sepolia.basescan.org) |
| Ethereum Sepolia | 11155111 | [Etherscan](https://sepolia.etherscan.io) |

## IPFS Metadata

- **Convexo_LPs CID**: `bafkreib7mkjzpdm3id6st6d5vsxpn7v5h6sxeiswejjmrbcb5yoagaf4em`
- **Convexo_Vaults CID**: `bafkreignxas6gqi7it5ng6muoykujxlgxxc4g7rr6sqvwgdfwveqf2zw3e`

Use full IPFS URI when minting: `ipfs://<CID>`

## Configuration

### Admin Address

Hardcoded admin: `0x156d3C1648ef2f50A8de590a426360Cf6a89C6f8`

This address receives:
- `DEFAULT_ADMIN_ROLE` - Full administrative access
- `MINTER_ROLE` - Can mint tokens

### Roles

- **DEFAULT_ADMIN_ROLE**: Manage token states, access company IDs
- **MINTER_ROLE**: Mint new tokens

## Troubleshooting

### Build Errors

```bash
forge clean
forge install
forge build
```

### Test Failures

```bash
forge test -vvvv  # Verbose output for debugging
```

### Deployment Issues

- Verify RPC URL is accessible
- Check deployer account has sufficient balance
- Ensure `.env` is properly loaded

### Verification Fails

- Wait 5-10 blocks after deployment
- Check Etherscan API key is valid
- Verify constructor arguments are correct

## Scripts Reference

### extract-abis.sh

Extract ABIs from compiled contracts:

```bash
./scripts/extract-abis.sh
```

### deploy-all.sh

Automated deployment with verification:

```bash
./scripts/deploy-all.sh [chain] [deploy_lps] [deploy_vaults]
# Examples:
./scripts/deploy-all.sh unichain_sepolia
./scripts/deploy-all.sh base_sepolia true false  # Only LPs
```

## Security

- ✅ Soulbound tokens (non-transferable)
- ✅ Role-based access control
- ✅ Admin-only state management
- ✅ Private company ID storage
- ✅ OpenZeppelin audited contracts

## License

MIT

## Links

- [Foundry Documentation](https://book.getfoundry.sh/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts)
- [Etherscan V2 API](https://docs.etherscan.io/contract-verification/verify-with-foundry)

# Convexo On-Chain Contract Signing & Vault System

## Overview

Complete implementation of an on-chain contract signing system with NFT-based access control, Uniswap V4 hooks for compliant LP access, Chainlink price feeds for multi-currency support, and tokenized bond vaults.

## System Components

### 1. NFT Access Control (Already Deployed)
- **Convexo_LPs** (`convexolps.sol`): Soulbound NFT for compliant liquidity provider access
- **Convexo_Vaults** (`convexovaults.sol`): Soulbound NFT for vault creation privileges

### 2. Uniswap V4 Hook System (NEW)
- **CompliantLPHook** (`hooks/CompliantLPHook.sol`): Gates pool access to Convexo_LPs NFT holders
- **HookDeployer** (`hooks/HookDeployer.sol`): CREATE2 deployment for deterministic hook addresses
- **BaseHook** (`hooks/BaseHook.sol`): Base implementation for Uniswap V4 hooks
- **PoolRegistry** (`contracts/PoolRegistry.sol`): Tracks gated pools (USDC/ECOP, USDC/ARS, USDC/MXN)

### 3. Contract Signing System (NEW)
- **ContractSigner** (`contracts/ContractSigner.sol`): 
  - On-chain signature collection
  - Document hash storage (full docs on IPFS/Supabase)
  - Multi-party signing support
  - Agreement types: Loan, Credit, Invoice Factoring, Tokenized Bond Credits

### 4. Chainlink Integration (NEW)
- **PriceFeedManager** (`contracts/PriceFeedManager.sol`):
  - USDC/COP (Colombian Peso) price feed
  - USDC/CHF (Swiss Franc) price feed
  - USDC/ARS (Argentine Peso) price feed
  - USDC/MXN (Mexican Peso) price feed
  - Real-time currency conversion
  - Staleness checks for price data

### 5. Reputation System (NEW)
- **ReputationManager** (`contracts/ReputationManager.sol`):
  - **Tier 0**: No NFTs - Limited access
  - **Tier 1**: 1 NFT (Compliant) - Convexo_LPs holders can access pools
  - **Tier 2**: 2 NFTs (Creditscore) - Both NFTs for premium vault access

### 6. Product Lines (NEW)

#### A. Invoice Factoring
- **InvoiceFactoring** (`contracts/InvoiceFactoring.sol`):
  - SME signs invoice factoring agreement
  - Invoice tokenized as ERC20/NFT
  - Vault created for invoice sale
  - Investors buy invoice-backed tokens

#### B. Tokenized Bond Credits
- **TokenizedBondCredits** (`contracts/TokenizedBondCredits.sol`):
  - SME signs credit agreement
  - Credit score validation (must be > 70)
  - Loan disbursed in local currency (using price feeds)
  - Daily cash flow tracking
  - Repayment management

### 7. Vault System (NEW)
- **VaultFactory** (`contracts/VaultFactory.sol`):
  - Creates TokenizedBondVault after contract signing
  - Links signed contracts to vaults
  - Manages vault registry

- **TokenizedBondVault** (`contracts/TokenizedBondVault.sol`):
  - ERC20 share tokens
  - **12% returns** for liquidity providers
  - **2% protocol fee** for Convexo
  - **10% interest** paid by SME
  - Share purchase and redemption
  - State management (Pending → Active → Repaying → Completed)

## Data Flow

### Invoice Factoring Flow
1. SME with Tier 1+ reputation initiates agreement
2. Contract signed on-chain via ContractSigner
3. InvoiceFactoring contract tokenizes invoice
4. VaultFactory creates vault
5. Investors purchase shares
6. Vault disbursed to SME
7. Invoice repaid → Investors redeemed

### Tokenized Bond Credits Flow
1. SME with Tier 2 reputation (both NFTs) applies
2. Credit score verified (>70)
3. Multi-party contract signed
4. TokenizedBondCredits creates credit
5. VaultFactory creates vault
6. Investors fund vault
7. Loan disbursed in local currency (price feed conversion)
8. Daily cash flow tracked
9. Repayments made → Vault closes → Shares redeemed

### Compliant LP Access Flow
1. User attempts to interact with USDC/ECOP pool
2. Uniswap V4 PoolManager calls CompliantLPHook
3. Hook checks if user holds active Convexo_LPs NFT
4. If yes → Allow swap/add liquidity/remove liquidity
5. If no → Revert with "Must hold Convexo_LPs NFT"

## Technical Architecture

### Smart Contract Hierarchy
```
IHooks (interface)
  └── BaseHook (abstract)
       └── CompliantLPHook (implementation)

AccessControl
  ├── ContractSigner
  ├── PoolRegistry
  ├── PriceFeedManager
  ├── InvoiceFactoring
  ├── TokenizedBondCredits
  └── VaultFactory

ERC20 + AccessControl
  └── TokenizedBondVault

ERC721 + ERC721URIStorage + AccessControl + Soulbound
  ├── Convexo_LPs
  └── Convexo_Vaults
```

### Integration Points
- **Uniswap V4**: CompliantLPHook gates pool access
- **Chainlink**: Price feeds for multi-currency conversion
- **IPFS/Supabase**: Off-chain document storage
- **Chainlink CCIP**: Cross-chain stablecoin transfers (ECOP)

## Security Features

1. **Soulbound NFTs**: Non-transferable access tokens
2. **Multi-signature**: Required signers for contract execution
3. **Role-based Access**: Admin, Minter, Verifier, Credit Approver roles
4. **Price Feed Validation**: Staleness checks, round validation
5. **State Management**: Proper lifecycle for credits and vaults
6. **Signature Verification**: ECDSA signature recovery

## Deployment Strategy

### Testnets
- Unichain Sepolia (Chain ID: 1301)
- Base Sepolia (Chain ID: 84532)
- Ethereum Sepolia (Chain ID: 11155111)

### Configuration
- Single Etherscan API key (V2 API)
- Admin address: `0x156d3C1648ef2f50A8de590a426360Cf6a89C6f8`
- Via-IR compilation enabled (stack too deep mitigation)
- Optimizer runs: 200

## Off-Chain Components

### Supabase Schema
```sql
CREATE TABLE signed_contracts (
  id UUID PRIMARY KEY,
  contract_hash TEXT UNIQUE NOT NULL,
  document_uri TEXT, -- IPFS CID
  agreement_type TEXT,
  signer_address TEXT,
  nft_reputation_tier INTEGER,
  vault_id INTEGER,
  created_at TIMESTAMPTZ,
  signatures JSONB
);

CREATE TABLE pool_access_logs (
  id UUID PRIMARY KEY,
  pool_address TEXT,
  user_address TEXT,
  nft_token_id INTEGER,
  action_type TEXT, -- swap, addLiquidity, removeLiquidity
  timestamp TIMESTAMPTZ
);
```

## Frontend Integration

### ABIs Available
- Convexo_LPs
- Convexo_Vaults
- CompliantLPHook
- ContractSigner
- PriceFeedManager
- ReputationManager
- InvoiceFactoring
- TokenizedBondCredits
- VaultFactory
- TokenizedBondVault
- PoolRegistry

### Key Frontend Features Needed
1. **Admin Dashboard**:
   - Mint NFTs (Convexo_LPs, Convexo_Vaults)
   - Manage pool registry
   - Deploy hooks
   - Configure price feeds

2. **User Dashboard**:
   - Check NFT ownership
   - View reputation tier
   - Access compliant pools
   - View vault positions

3. **Contract Signing Interface**:
   - Upload documents to IPFS
   - Collect signatures
   - Track signing progress

4. **Vault Dashboard**:
   - Browse available vaults
   - Purchase shares
   - Track returns
   - Redeem shares

## Status

### Completed ✅
- All core smart contracts implemented
- Uniswap V4 hook system
- Contract signing infrastructure
- Chainlink price feed integration
- Reputation management
- Two product lines (Invoice Factoring + Tokenized Bond Credits)
- Vault factory and tokenized bond vault
- Compilation successful (with via-IR)

### Pending
- Comprehensive test suite
- Deployment scripts
- Contract verification
- ABI extraction
- Documentation updates
- Deployment to testnets

## Next Steps

1. Write comprehensive tests for all contracts
2. Create deployment scripts
3. Deploy to Unichain Sepolia, Base Sepolia, Ethereum Sepolia
4. Verify contracts on block explorers
5. Extract ABIs for frontend
6. Update README with usage instructions
7. Create Supabase database
8. Build frontend interfaces

## Gas Optimization Notes

- Via-IR compilation enabled for deep stack issues
- Optimizer runs set to 200 (balance between deployment and runtime)
- Consider function packing for frequently called functions
- Storage optimization in vault share calculations

## Audit Recommendations

Priority audit areas:
1. CompliantLPHook access control logic
2. TokenizedBondVault share calculations
3. ContractSigner signature verification
4. PriceFeedManager staleness checks
5. VaultFactory vault creation logic
6. Cross-contract interactions

## License

MIT License - All contracts


# Convexo Deployment Guide

## Overview

This guide provides a **precise deployment strategy** for all Convexo contracts with special focus on the **LP + Hook system** which is the core functionality.

## Deployment Priority

### 🔴 CRITICAL (Must deploy first - LP + Hook System)
1. **Convexo_LPs** - NFT for compliant LP access
2. **CompliantLPHook** - Gates Uniswap V4 pools
3. **HookDeployer** - Deploy hook with correct address
4. **PoolRegistry** - Track gated pools

### 🟡 HIGH PRIORITY (Core functionality)
5. **Convexo_Vaults** - NFT for vault creation
6. **ReputationManager** - Tier system
7. **PriceFeedManager** - Currency conversion

### 🟢 MEDIUM PRIORITY (Product features)
8. **ContractSigner** - On-chain signatures
9. **VaultFactory** - Create vaults
10. **TokenizedBondVault** - Vault implementation
11. **InvoiceFactoring** - Product line 1
12. **TokenizedBondCredits** - Product line 2

## Detailed Deployment Steps

### Phase 1: NFT Foundation (CRITICAL)

#### 1.1 Deploy Convexo_LPs
```bash
# Deploy to Unichain Sepolia
forge script script/DeployConvexoLPs.s.sol \
  --rpc-url $UNICHAIN_SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  --verifier etherscan \
  --etherscan-api-key $ETHERSCAN_API_KEY

# Deploy to Base Sepolia
forge script script/DeployConvexoLPs.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  --verifier etherscan \
  --etherscan-api-key $ETHERSCAN_API_KEY

# Deploy to Ethereum Sepolia
forge script script/DeployConvexoLPs.s.sol \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  --verifier etherscan \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

**Admin Actions After Deployment:**
- Note the contract address
- Mint first NFT to test address
- Verify NFT state is Active

#### 1.2 Deploy Convexo_Vaults
```bash
# Same deployment process as Convexo_LPs for all 3 networks
```

### Phase 2: Uniswap V4 Hook System (CRITICAL)

#### 2.1 Deploy HookDeployer
```bash
forge script script/DeployHookDeployer.s.sol \
  --rpc-url $UNICHAIN_SEPOLIA_RPC_URL \
  --broadcast \
  --verify
```

**Important Notes:**
- HookDeployer must be deployed first
- It will calculate the correct hook address with permissions

#### 2.2 Find Correct Salt for Hook Address

The hook address must have specific bits set for permissions:
- Bit 157: `beforeAddLiquidity` = 1
- Bit 155: `beforeRemoveLiquidity` = 1
- Bit 153: `beforeSwap` = 1

```solidity
// Off-chain calculation or use HookDeployer.findSalt()
(bytes32 salt, address predictedAddress) = hookDeployer.findSalt(
    poolManager,
    convexoLPs,
    bytes32(0), // starting salt
    10000 // max iterations
);
```

#### 2.3 Deploy CompliantLPHook
```bash
forge script script/DeployCompliantLPHook.s.sol \
  --rpc-url $UNICHAIN_SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  --sig "run(bytes32)" $SALT
```

**Constructor Args:**
- `poolManager`: Uniswap V4 PoolManager address
- `convexoLPs`: Convexo_LPs contract address

**Verification:**
- Check hook address has correct permission bits
- Test with mock pool interaction

#### 2.4 Deploy PoolRegistry
```bash
forge script script/DeployPoolRegistry.s.sol \
  --rpc-url $UNICHAIN_SEPOLIA_RPC_URL \
  --broadcast \
  --verify
```

**Admin Actions:**
1. Register USDC/ECOP pool
2. Register USDC/ARS pool
3. Register USDC/MXN pool

### Phase 3: Reputation & Pricing

#### 3.1 Deploy ReputationManager
```bash
forge script script/DeployReputationManager.s.sol \
  --rpc-url $UNICHAIN_SEPOLIA_RPC_URL \
  --broadcast \
  --verify
```

**Constructor Args:**
- `convexoLPs`: Convexo_LPs address
- `convexoVaults`: Convexo_Vaults address

#### 3.2 Deploy PriceFeedManager
```bash
forge script script/DeployPriceFeedManager.s.sol \
  --rpc-url $UNICHAIN_SEPOLIA_RPC_URL \
  --broadcast \
  --verify
```

**Admin Actions - Configure Price Feeds:**
```solidity
// Set USDC/COP feed
priceFeedManager.setPriceFeed(
    PriceFeedManager.CurrencyPair.USDC_COP,
    0x..., // Chainlink aggregator address
    3600  // 1 hour heartbeat
);

// Set USDC/CHF feed
priceFeedManager.setPriceFeed(
    PriceFeedManager.CurrencyPair.USDC_CHF,
    0x...,
    3600
);

// Similar for USDC/ARS and USDC/MXN
```

### Phase 4: Contract Signing & Vaults

#### 4.1 Deploy ContractSigner
```bash
forge script script/DeployContractSigner.s.sol \
  --rpc-url $UNICHAIN_SEPOLIA_RPC_URL \
  --broadcast \
  --verify
```

#### 4.2 Deploy VaultFactory
```bash
forge script script/DeployVaultFactory.s.sol \
  --rpc-url $UNICHAIN_SEPOLIA_RPC_URL \
  --broadcast \
  --verify
```

**Constructor Args:**
- `admin`: 0x156d3C1648ef2f50A8de590a426360Cf6a89C6f8
- `usdc`: USDC token address on network
- `protocolFeeCollector`: Treasury address
- `contractSigner`: ContractSigner address

#### 4.3 Deploy Product Contracts
```bash
# InvoiceFactoring
forge script script/DeployInvoiceFactoring.s.sol \
  --rpc-url $UNICHAIN_SEPOLIA_RPC_URL \
  --broadcast \
  --verify

# TokenizedBondCredits
forge script script/DeployTokenizedBondCredits.s.sol \
  --rpc-url $UNICHAIN_SEPOLIA_RPC_URL \
  --broadcast \
  --verify
```

## Testing Strategy

### Critical Tests (Must Pass)

#### 1. LP + Hook System Tests
```bash
# Test CompliantLPHook
forge test --match-contract CompliantLPHookTest -vvv
```

**Test Cases:**
- ✅ User with Convexo_LPs NFT can swap
- ✅ User with Convexo_LPs NFT can add liquidity
- ✅ User with Convexo_LPs NFT can remove liquidity
- ❌ User without NFT cannot swap (reverts)
- ❌ User without NFT cannot add liquidity (reverts)
- ❌ User without NFT cannot remove liquidity (reverts)
- ❌ User with inactive NFT cannot access (reverts)

#### 2. NFT Tests
```bash
forge test --match-contract ConvexoLPsTest -vvv
forge test --match-contract ConvexoVaultsTest -vvv
```

#### 3. Integration Tests
```bash
forge test --match-contract IntegrationTest -vvv
```

## ABI Extraction

```bash
# Extract ABIs for frontend
chmod +x scripts/extract-abis.sh
./scripts/extract-abis.sh
```

**ABIs Generated:**
- `abis/Convexo_LPs.json` ⭐ CRITICAL
- `abis/Convexo_Vaults.json`
- `abis/CompliantLPHook.json` ⭐ CRITICAL
- `abis/PoolRegistry.json` ⭐ CRITICAL
- `abis/ReputationManager.json` ⭐ CRITICAL
- `abis/PriceFeedManager.json`
- `abis/ContractSigner.json`
- `abis/VaultFactory.json`
- `abis/TokenizedBondVault.json`
- `abis/InvoiceFactoring.json`
- `abis/TokenizedBondCredits.json`
- `abis/combined.json` (All ABIs)

## Addresses Tracking

After each deployment, update `addresses.json`:

```json
{
  "1301": {
    "name": "Unichain Sepolia",
    "convexo_lps": "0x...",
    "convexo_vaults": "0x...",
    "compliant_lp_hook": "0x...",
    "hook_deployer": "0x...",
    "pool_registry": "0x...",
    "reputation_manager": "0x...",
    "price_feed_manager": "0x...",
    "contract_signer": "0x...",
    "vault_factory": "0x...",
    "invoice_factoring": "0x...",
    "tokenized_bond_credits": "0x..."
  }
}
```

## Frontend Integration Points

### Priority 1: LP + Hook System

#### Check User Access
```typescript
// Check if user can access pools
const reputationManager = new ethers.Contract(
  REPUTATION_MANAGER_ADDRESS,
  ReputationManagerABI,
  provider
);

const tier = await reputationManager.getReputationTier(userAddress);
// tier = 0 (None), 1 (Compliant), 2 (Creditscore)

const hasAccess = tier >= 1; // Must have at least Tier 1
```

#### Check Pool Registry
```typescript
const poolRegistry = new ethers.Contract(
  POOL_REGISTRY_ADDRESS,
  PoolRegistryABI,
  provider
);

// Get all registered pools
const poolCount = await poolRegistry.getPoolCount();
for (let i = 0; i < poolCount; i++) {
  const poolId = await poolRegistry.getPoolIdAtIndex(i);
  const poolInfo = await poolRegistry.getPool(poolId);
  console.log(poolInfo); // {poolAddress, token0, token1, hookAddress, isActive}
}
```

#### Swap with Hook
```typescript
// Standard Uniswap V4 swap, hook automatically enforces NFT check
const poolManager = new ethers.Contract(
  POOL_MANAGER_ADDRESS,
  PoolManagerABI,
  signer
);

// This will revert if user doesn't hold Convexo_LPs NFT
const tx = await poolManager.swap(poolKey, swapParams, hookData);
```

### Priority 2: NFT Management

#### Mint NFT (Admin Only)
```typescript
const convexoLPs = new ethers.Contract(
  CONVEXO_LPS_ADDRESS,
  ConvexoLPsABI,
  adminSigner
);

const tx = await convexoLPs.safeMint(
  recipientAddress,
  companyId, // Private company ID
  "ipfs://..." // Token URI
);

const tokenId = await tx.wait().then(r => r.events[0].args.tokenId);
```

#### Check NFT Status
```typescript
const balance = await convexoLPs.balanceOf(userAddress);
const isActive = balance > 0 ? await convexoLPs.getTokenState(tokenId) : false;
```

### Priority 3: Vault System

#### Create Vault After Signing
```typescript
const vaultFactory = new ethers.Contract(
  VAULT_FACTORY_ADDRESS,
  VaultFactoryABI,
  signer
);

const tx = await vaultFactory.createVault(
  borrower,
  contractHash,
  principalAmount,
  interestRate, // 1200 = 12%
  protocolFeeRate, // 200 = 2%
  maturityDate,
  "Vault Token Name",
  "VTK"
);

const vaultAddress = await tx.wait().then(r => r.events[0].args.vaultAddress);
```

## Verification Checklist

### For Each Network:

- [ ] Convexo_LPs deployed and verified
- [ ] Convexo_Vaults deployed and verified
- [ ] CompliantLPHook deployed with correct address
- [ ] CompliantLPHook verified on Etherscan
- [ ] Hook permissions verified (bits 157, 155, 153 set)
- [ ] PoolRegistry deployed and verified
- [ ] Test pool registered in PoolRegistry
- [ ] ReputationManager deployed and verified
- [ ] PriceFeedManager deployed and verified
- [ ] Price feeds configured
- [ ] ContractSigner deployed and verified
- [ ] VaultFactory deployed and verified
- [ ] Product contracts deployed and verified
- [ ] All ABIs extracted
- [ ] addresses.json updated
- [ ] Manual test: Mint NFT
- [ ] Manual test: User with NFT can swap
- [ ] Manual test: User without NFT cannot swap

## Troubleshooting

### Hook Address Doesn't Have Correct Permissions
**Solution:** Re-deploy with different salt using HookDeployer.findSalt()

### User Can't Access Pool Despite Having NFT
**Check:**
1. NFT state is Active (not NonActive)
2. Hook is correctly registered in pool
3. User is calling correct pool address

### Price Feed Returns Stale Data
**Solution:** Update heartbeat parameter or switch to more frequent feed

### Vault Creation Fails
**Check:**
1. Contract is fully signed
2. All required signers have signed
3. Contract is not cancelled
4. VaultFactory has VERIFIER_ROLE in ContractSigner

## Support Contracts

All contracts use:
- **Admin**: `0x156d3C1648ef2f50A8de590a426360Cf6a89C6f8`
- **Solidity**: `^0.8.27`
- **Compiler**: `via-ir` enabled, 200 optimizer runs
- **OpenZeppelin**: v5.5.0

## Next Steps After Deployment

1. **Frontend Setup:**
   - Import ABIs from `abis/` directory
   - Import addresses from `addresses.json`
   - Implement wallet connection
   - Implement NFT check before pool access

2. **Admin Dashboard:**
   - Mint NFTs interface
   - Manage pool registry
   - Configure price feeds
   - Monitor vaults

3. **User Dashboard:**
   - Check reputation tier
   - View NFT ownership
   - Access compliant pools
   - View vault positions

4. **Testing:**
   - Test on testnet with real users
   - Verify all state transitions
   - Load testing for hooks
   - Security audit

## Critical Success Factors

✅ **Hook must be deployed with correct address** - Permissions encoded in address
✅ **NFT must be Active** - Check state before allowing access
✅ **Pool must be registered** - PoolRegistry tracks valid pools
✅ **Price feeds must be configured** - Required for currency conversion
✅ **All contracts verified** - Required for frontend interaction

## Emergency Procedures

### Pause Hook
```solidity
// If critical bug found in hook
// Deploy new hook and update pool registry
poolRegistry.updatePoolStatus(poolId, false); // Deactivate
```

### Deactivate NFT
```solidity
// Admin can deactivate compromised NFT
convexoLPs.setTokenState(tokenId, false);
```

### Update Price Feed
```solidity
// If feed becomes unreliable
priceFeedManager.setPriceFeed(pair, newAggregator, heartbeat);
```

---

**Remember:** The LP + Hook system is the foundation. Everything else builds on top of it. Deploy and verify this first before proceeding to other components.


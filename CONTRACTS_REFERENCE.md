# Convexo Contracts Reference Guide

**Version 2.1** - Complete contract reference with 12 smart contracts

## Overview

This comprehensive reference guide documents all **12 Convexo Protocol smart contracts** deployed on Ethereum, Base, and Unichain (mainnet + testnets).

### 📚 What's Inside

This guide provides detailed documentation for:
- **12 Smart Contracts** with complete function signatures
- **NFT-Gated Access System** (Tier 1, Tier 2 & Tier 3)
- **Vault System** for investor staking
- **Treasury System** for multi-sig USDC management (NEW)
- **Uniswap V4 Integration** with compliant hooks
- **Dual Verification Paths** (ZKPassport + Veriff)
- **Reputation & Price Feed Management**

### 🎯 Quick Navigation

| Contract Type | Contracts | Purpose |
|---------------|-----------|---------|
| **NFT System** | Convexo_LPs, Convexo_Vaults, Convexo_Passport | Access control and compliance |
| **Vault System** | VaultFactory, TokenizedBondVault | Tokenized bond vaults for SME financing |
| **Treasury System** | TreasuryFactory, TreasuryVault | Multi-sig USDC treasury (NEW) |
| **Hook System** | CompliantLPHook, HookDeployer, PoolRegistry | Uniswap V4 integration |
| **Verification** | VeriffVerifier | Human-approved KYC/KYB (NEW) |
| **Infrastructure** | ReputationManager, PriceFeedManager, ContractSigner | Core protocol services |

### 🔑 Key Concepts

**Tier System (v2.1 - UPDATED):**

| Tier | NFT Required | User Type | Access |
|------|--------------|-----------|--------|
| **Tier 0** | None | Unverified | No access |
| **Tier 1** | Convexo_Passport | Individual | Treasury creation + Vault investments |
| **Tier 2** | Convexo_LPs | Limited Partner | LP pools + Vault investments |
| **Tier 3** | Convexo_Vaults | Vault Creator | Vault creation + All Tier 2 benefits |

**Key Change:** Tier hierarchy is now **reversed** - Passport is Tier 1 (entry-level), Vaults is Tier 3 (highest).

**Vault States:**
- **Pending**: Accepting investments from lenders
- **Funded**: Fully funded, awaiting contract signatures
- **Active**: Contract signed, borrower can withdraw funds
- **Repaying**: Funds withdrawn, borrower making repayments
- **Completed**: All debt repaid AND all funds withdrawn by protocol & investors
- **Defaulted**: Borrower failed to repay by maturity date

**New Vault Flow:**
1. **Borrower** creates vault (requires Tier 3 NFT - VaultCreator)
2. **Investors** fund the vault (requires Tier 1+ NFT) → State: `Funded`
3. **Admin** creates contract with all parties as signers
4. **All parties** sign the contract
5. **Admin** executes contract
6. **Borrower** attaches contract to vault → State: `Active`
7. **Borrower** withdraws funds → State: `Repaying` (timestamp recorded)
8. **Borrower** makes repayments (can be partial or full, anytime)
9. **Protocol Collector** withdraws fees (proportional to repayments)
10. **Investors** redeem shares (proportional to available funds)
11. When fully repaid AND all funds withdrawn → State: `Completed`

---

## 📖 Contract Documentation

---

## 💰 TOKENIZED BOND VAULT - Complete Reference

### Purpose
**Core vault contract for tokenized bonds with ERC20 share tokens**. Shows real-time returns like Aave, allows entity to withdraw and repay anytime with 12% interest.

### Vault States
```
Pending → Funded → Active → Repaying → Completed
                                    ↓
                                Defaulted
```

### For Investors: Staking & Returns

#### 1. Purchase Shares (Stake USDC)
```solidity
function purchaseShares(uint256 amount) external
```

**Requirements:**
- Investor must have **Tier 1+ NFT** (Passport, LPs, or Vaults)
- Vault must be in `Pending` state
- Amount must be > 0 and not exceed remaining funding target

**Example:**
```typescript
// Check investor can invest (Tier 1+ required)
const canInvest = await reputationManager.canInvestInVaults(userAddress);
require(canInvest, "Must have Tier 1+ NFT");

// Investor stakes 1,000 USDC
await usdc.approve(vaultAddress, 1000e6);
await vault.purchaseShares(1000e6);

// Investor receives 1,000 vault shares (1:1 initially)
```

**What Happens:**
- Investor approves USDC spend
- Calls `purchaseShares(1000 USDC)`
- Receives 1,000 vault share tokens (ERC20)
- Shares represent claim on vault returns
- When vault fully funded → State changes to `Funded`

#### 2. Check Your Investment (Like Aave Dashboard)
```solidity
function getInvestorReturn(address investor) 
    returns (
        uint256 invested,      // Amount you put in
        uint256 currentValue,  // Current worth
        uint256 profit,        // Earnings
        uint256 apy            // Current APY %
    )
```

**Example:**
```typescript
const [invested, currentValue, profit, apy] = 
    await vault.getInvestorReturn(userAddress);

console.log(`Invested: ${invested / 1e6} USDC`);
console.log(`Current Value: ${currentValue / 1e6} USDC`);
console.log(`Profit: ${profit / 1e6} USDC`);
console.log(`APY: ${apy / 100}%`);

// Output:
// Invested: 1,000 USDC
// Current Value: 1,025 USDC
// Profit: 25 USDC
// APY: 12.5%
```

#### 3. Check Vault Metrics (Dashboard View)
```solidity
function getVaultMetrics() 
    returns (
        uint256 totalShares,      // Total shares minted
        uint256 sharePrice,       // Current price per share
        uint256 totalValueLocked, // Total USDC in vault
        uint256 targetAmount,     // Funding target
        uint256 fundingProgress,  // Progress % (10000 = 100%)
        uint256 currentAPY        // Vault APY (1200 = 12%)
    )
```

**Example:**
```typescript
const [
    totalShares, 
    sharePrice, 
    tvl, 
    target, 
    progress, 
    apy
] = await vault.getVaultMetrics();

console.log(`Total Shares: ${totalShares / 1e6}`);
console.log(`Share Price: ${sharePrice / 1e6} USDC`);
console.log(`TVL: ${tvl / 1e6} USDC`);
console.log(`Target: ${target / 1e6} USDC`);
console.log(`Progress: ${progress / 100}%`);
console.log(`APY: ${apy / 100}%`);
```

#### 4. Check Accrued Interest (Real-time)
```solidity
function getAccruedInterest() 
    returns (
        uint256 accruedInterest,   // Interest earned so far
        uint256 remainingInterest  // Interest still to come
    )
```

#### 5. Redeem Shares (Withdraw)
```solidity
function redeemShares(uint256 shares) external
```

**Important (v2.1):** Redemption is only allowed when debt is fully repaid:
```typescript
// Redemption requires full repayment in Repaying state
const state = await vault.getVaultState();
if (state === VaultState.Repaying) {
    // Must wait for full repayment before redeeming
}
```

### For Borrowers: Withdraw & Repay

#### 1. Withdraw Funds (After Contract Signed)
```solidity
function withdrawFunds() external // Borrower only
```

**What Happens:**
- Vault must be fully funded (100% of target)
- Contract must be attached and fully signed
- All USDC transferred to borrower
- State changes: Active → Repaying
- `fundsWithdrawnAt` timestamp recorded

#### 2. Make Repayment (Pay Back Anytime)
```solidity
function makeRepayment(uint256 amount) external
```

**Example:**
```typescript
// Borrower can repay anytime, any amount
// Total Due = Principal + Interest + Protocol Fee
// Example: 50,000 + 6,000 (12%) + 1,000 (2%) = 57,000 USDC

await usdc.approve(vaultAddress, 5000e6);
await vault.makeRepayment(5000e6);

// Check vault info
const vaultInfo = await vault.vaultInfo();
console.log(`Total Repaid: ${vaultInfo.totalRepaid / 1e6} USDC`);
```

#### 3. Check Repayment Status
```solidity
function getRepaymentStatus() 
    returns (
        uint256 totalDue,      // Principal + 12% interest
        uint256 totalPaid,     // Amount paid so far
        uint256 remaining,     // Amount left to pay
        uint256 protocolFee    // 2% protocol fee
    )
```

### Returns Distribution Example

**Loan: $50,000 USDC**
- Interest Rate: 12%
- Protocol Fee: 2%

**Calculation:**
```
Principal: 50,000 USDC
Interest (12%): 50,000 * 12% = 6,000 USDC
Protocol Fee (2%): 50,000 * 2% = 1,000 USDC

Total Due from Borrower: 50,000 + 6,000 + 1,000 = 57,000 USDC

Distribution when fully repaid:
1. Protocol Fee: 1,000 USDC → Convexo (2% of principal)
2. Investor Returns: 56,000 USDC → Investors (principal + interest)
   - Investor net return: (56,000 - 50,000) / 50,000 = 12%

Summary:
- Borrower pays: 57,000 USDC total (14% total cost)
- Protocol receives: 1,000 USDC (2% fee)
- Investors receive: 56,000 USDC (12% return)
```

### Protocol Fee Protection

Protocol fees are protected from investor withdrawals:

```solidity
// Get funds available for investors (excluding reserved protocol fees)
function getAvailableForInvestors() public view returns (uint256)
```

**Example:**
```typescript
const availableForInvestors = await vault.getAvailableForInvestors();

// This amount EXCLUDES protocol fees that haven't been withdrawn yet
console.log(`Available for investors: ${formatUnits(availableForInvestors, 6)} USDC`);
```

### Vault Timeline & Timestamps

Track important vault milestones with timestamps:

```solidity
// Get vault timestamps
function getVaultCreatedAt() external view returns (uint256)
function getVaultFundedAt() external view returns (uint256)
function getVaultContractAttachedAt() external view returns (uint256)
function getVaultFundsWithdrawnAt() external view returns (uint256)

// Calculate actual due date based on withdrawal time
function getActualDueDate() external view returns (uint256)
```

**Why This Matters:**
- **Accurate Due Dates**: Due date calculated from when funds are withdrawn, not when vault is created
- **Timeline Tracking**: Frontend can show complete timeline of vault milestones
- **Compliance**: Timestamps provide immutable audit trail

---

## 🏦 TREASURY SYSTEM - NEW in v2.1

### TreasuryFactory

**Purpose:** Factory for creating TreasuryVault instances. Requires Tier 1+ (Passport or higher).

```solidity
// Create a new treasury (requires Tier 1+)
function createTreasury(
    address[] memory signers,      // Authorized signers (empty for single-sig)
    uint256 signaturesRequired     // Required signatures for withdrawals
) external returns (uint256 treasuryId, address treasuryAddress)

// Get treasury by ID
function getTreasury(uint256 treasuryId) external view returns (address)

// Get total number of treasuries
function getTreasuryCount() external view returns (uint256)

// Get all treasury IDs owned by an address
function getTreasuriesByOwner(address owner) external view returns (uint256[] memory)
```

**Example:**
```typescript
// Individual with Passport NFT creates a treasury
const canCreate = await reputationManager.canCreateTreasury(userAddress);
require(canCreate, "Must have Tier 1+ NFT");

// Create single-sig treasury
const [treasuryId, treasuryAddress] = await treasuryFactory.createTreasury([], 1);

// Create multi-sig treasury (2 of 3)
const signers = [signer1, signer2, signer3];
const [treasuryId, treasuryAddress] = await treasuryFactory.createTreasury(signers, 2);
```

### TreasuryVault

**Purpose:** Multi-sig USDC treasury for individuals and businesses.

```solidity
// Deposit USDC
function deposit(uint256 amount) external

// Propose a withdrawal (any signer)
function proposeWithdrawal(
    address recipient,
    uint256 amount,
    string calldata reason
) external returns (uint256 proposalId)

// Approve a withdrawal proposal (signer)
function approveWithdrawal(uint256 proposalId) external

// Execute withdrawal after enough approvals
function executeWithdrawal(uint256 proposalId) external

// Get treasury balance
function getBalance() external view returns (uint256)

// Get proposal details
function getProposal(uint256 proposalId) external view returns (Proposal memory)
```

---

## 🔐 NFT Contracts

### Convexo_LPs (Limited Partner NFT - Tier 2)

**Purpose:** Gate access to Uniswap V4 pools. Only holders can trade.

```solidity
// Mint NFT (Admin only)
function safeMint(
    address to,
    string companyId,    // Private company ID
    string uri           // IPFS metadata
) returns (uint256 tokenId)

// Change NFT state
function setTokenState(uint256 tokenId, bool isActive)

// Check if active
function getTokenState(uint256 tokenId) returns (bool)

// Get company ID (Admin only)
function getCompanyId(uint256 tokenId) returns (string)
```

### Convexo_Vaults (Vault Creator NFT - Tier 3)

**Same functions as Convexo_LPs.** Grants vault creation privileges.

### Convexo_Passport (Individual Investor NFT - Tier 1)

**Purpose:** Soulbound NFT for individual investors verified via ZKPassport. Grants Tier 1 access.

**Key Features:**
- **Soulbound**: Non-transferable NFT (cannot be sold or transferred)
- **ZKPassport Verified**: Uses zero-knowledge proofs for privacy-preserving identity verification
- **Privacy-Compliant**: Only verification traits stored, no PII
- **One Per Address**: Each address can only hold one active passport

**Stored Verification Traits (non-PII):**

| Trait | Description |
|-------|-------------|
| `kycVerified` | Overall KYC verification passed |
| `faceMatchPassed` | Face match verification result |
| `sanctionsPassed` | Sanctions check passed |
| `isOver18` | Age verification passed |

```solidity
// Self-mint with ZKPassport proof (on-chain verification)
function safeMintWithZKPassport(
    ProofVerificationParams calldata params,
    bool isIDCard  // true for ID card, false for passport
) returns (uint256 tokenId)

// Self-mint with unique identifier (off-chain verification)
function safeMintWithIdentifier(
    bytes32 uniqueIdentifier
) returns (uint256 tokenId)

// Admin mint (for special cases)
function safeMint(
    address to,
    string memory uri
) returns (uint256 tokenId)

// Revoke passport (Admin only)
function revokePassport(uint256 tokenId)

// Check if address holds active passport
function holdsActivePassport(address holder) returns (bool)

// Get verified identity details (privacy-compliant traits)
function getVerifiedIdentity(address holder) 
    returns (VerifiedIdentity memory)
    // Returns: uniqueIdentifier, verifiedAt, isActive, 
    //          kycVerified, faceMatchPassed, sanctionsPassed, isOver18

// Check if identifier already used (prevents duplicate passports)
function isIdentifierUsed(bytes32 uniqueIdentifier) returns (bool)

// Get total active passports
function getActivePassportCount() returns (uint256)
```

**Example Usage:**
```typescript
// Individual mints passport with off-chain ZKPassport verification
const uniqueIdentifier = keccak256(publicKey + scope);
const tokenId = await convexoPassport.safeMintWithIdentifier(uniqueIdentifier);

// Check if user has passport
const hasPassport = await convexoPassport.holdsActivePassport(userAddress);

// Get identity traits (privacy-compliant)
const identity = await convexoPassport.getVerifiedIdentity(userAddress);
console.log(`KYC Verified: ${identity.kycVerified}`);
console.log(`Face Match: ${identity.faceMatchPassed}`);
console.log(`Sanctions: ${identity.sanctionsPassed}`);
console.log(`Over 18: ${identity.isOver18}`);
```

---

## 🔍 VERIFF VERIFIER - NEW in v2.1

### Purpose

Human-approved KYC/KYB verification system for Limited Partner (Tier 2) access. Admin submits verification results from Veriff platform, then approves/rejects to mint Convexo_LPs NFT.

### Verification Flow

```
1. User completes Veriff verification (off-chain)
   ↓
2. Admin submits verification result (submitVerification)
   ↓
3. Admin reviews and approves/rejects
   ↓
4. If approved: Convexo_LPs NFT minted automatically
   ↓
5. User now has Tier 2 (Limited Partner) access
```

### Functions

```solidity
// Submit verification result from Veriff (Admin only)
function submitVerification(
    address user,
    string calldata sessionId
) external

// Approve verification and mint Convexo_LPs NFT
function approveVerification(address user) external

// Reject verification with reason
function rejectVerification(
    address user,
    string calldata reason
) external

// Get verification status
function getVerificationStatus(address user) 
    returns (VerificationRecord memory)

// Check if user has approved verification
function isVerified(address user) returns (bool)

// Reset rejected verification (Admin only)
function resetVerification(address user) external
```

**Example:**
```typescript
// Admin submits Veriff session result
await veriffVerifier.submitVerification(userAddress, "session_12345");

// Admin approves (automatically mints Convexo_LPs NFT)
await veriffVerifier.approveVerification(userAddress);

// Check verification status
const record = await veriffVerifier.getVerificationStatus(userAddress);
console.log(`Status: ${record.status}`); // 0=None, 1=Pending, 2=Approved, 3=Rejected
console.log(`NFT Token ID: ${record.nftTokenId}`);
```

---

## 🎣 Uniswap V4 Hook System

### CompliantLPHook

**Purpose:** Automatically checks if user holds Convexo_LPs NFT (Tier 2+) before allowing pool access.

**How It Works:**
1. User tries to swap in USDC/ECOP pool
2. Uniswap V4 calls hook's `beforeSwap()` function
3. Hook checks: `reputationManager.canAccessLPPools(user)`
4. If yes → Allow swap
5. If no → Revert with "Must have LimitedPartner tier or higher"

**Functions:**
```solidity
// Called before swap (automatic)
function beforeSwap(
    address sender,
    PoolKey key,
    SwapParams params,
    bytes hookData
) returns (bytes4, BeforeSwapDelta, uint24)

// Called before adding liquidity (automatic)
function beforeAddLiquidity(
    address sender,
    PoolKey key,
    ModifyLiquidityParams params,
    bytes hookData
) returns (bytes4)

// Called before removing liquidity (automatic)
function beforeRemoveLiquidity(
    address sender,
    PoolKey key,
    ModifyLiquidityParams params,
    bytes hookData
) returns (bytes4)
```

### PoolRegistry

**Purpose:** Track which pools are gated.

```solidity
// Register new pool (Admin)
function registerPool(
    address poolAddress,
    address token0,
    address token1,
    address hookAddress,
    string description
) returns (bytes32 poolId)

// Get pool info
function getPool(bytes32 poolId) returns (PoolInfo memory)

// Get all pools
function getPoolCount() returns (uint256)
function getPoolIdAtIndex(uint256 index) returns (bytes32)
```

---

## 🌐 Multi-Currency Support

### PriceFeedManager

**Purpose:** Convert between USDC and local currencies using Chainlink.

```solidity
// Set price feed (Admin)
function setPriceFeed(
    CurrencyPair pair,      // USDC_COP
    address aggregator,     // Chainlink feed
    uint256 heartbeat       // Max staleness (3600 = 1 hour)
)

// Get latest price
function getLatestPrice(CurrencyPair pair) 
    returns (int256 price, uint8 decimals)

// Convert USDC to local currency
function convertUSDCToLocal(
    CurrencyPair pair,
    uint256 usdcAmount
) returns (uint256 localAmount)

// Convert local currency to USDC
function convertLocalToUSDC(
    CurrencyPair pair,
    uint256 localAmount
) returns (uint256 usdcAmount)
```

---

## 📝 Contract Signing System

### ContractSigner

**Purpose:** Multi-party signing of agreements on-chain.

```solidity
// Create contract for signing
function createContract(
    bytes32 documentHash,     // Hash of document
    AgreementType type,       // Loan, Credit, etc.
    address[] requiredSigners,
    string ipfsHash,          // IPFS CID
    uint256 nftReputationTier,
    uint256 expiryDuration
)

// Sign contract
function signContract(
    bytes32 documentHash,
    bytes signature           // ECDSA signature
)

// Execute after all signed (Admin)
function executeContract(
    bytes32 documentHash,
    uint256 vaultId
)

// Check if fully signed
function isFullySigned(bytes32 documentHash) returns (bool)

// Get contract info
function getContract(bytes32 documentHash) 
    returns (ContractDocument memory)
```

---

## 🏗️ Vault Factory

### VaultFactory

**Purpose:** Create vaults for borrowers with Tier 3 NFT (Convexo_Vaults).

```solidity
// Create vault (Borrower with Tier 3 NFT)
function createVault(
    uint256 principalAmount,
    uint256 interestRate,     // 1200 = 12%
    uint256 protocolFeeRate,  // 200 = 2%
    uint256 maturityDate,
    string name,
    string symbol
) returns (uint256 vaultId, address vaultAddress)
```

**Requirements:**
- Caller must have Tier 3 NFT (Convexo_Vaults)
- Principal amount > 0
- Maturity date in the future
- Interest rate between 0.01% and 100%
- Protocol fee ≤ 10%

---

## 🎭 Reputation System

### ReputationManager (v2.1 - UPDATED)

**Purpose:** Calculate user reputation tier based on NFT ownership.

**New Tier Hierarchy:**
```
Tier 0: No NFTs → No access
Tier 1: Convexo_Passport → Individual: Treasury + Vault investments
Tier 2: Convexo_LPs → Limited Partner: LP pools + Vault investments
Tier 3: Convexo_Vaults → Vault Creator: All above + Vault creation

Note: Highest tier wins (progressive KYC - no mutual exclusivity)
```

```solidity
// Get user's tier
function getReputationTier(address user) returns (ReputationTier)
// Returns: None (0), Passport (1), LimitedPartner (2), VaultCreator (3)

// Get numeric tier
function getReputationTierNumeric(address user) returns (uint256)

// NEW: Check if can create treasuries (Tier 1+)
function canCreateTreasury(address user) returns (bool)

// NEW: Check if can invest in vaults (Tier 1+)
function canInvestInVaults(address user) returns (bool)

// NEW: Check if can access LP pools (Tier 2+)
function canAccessLPPools(address user) returns (bool)

// NEW: Check if can create vaults (Tier 3)
function canCreateVaults(address user) returns (bool)

// Check if has LimitedPartner access (Tier 2+)
function hasLimitedPartnerAccess(address user) returns (bool)

// Check if has VaultCreator access (Tier 3)
function hasVaultCreatorAccess(address user) returns (bool)

// Check NFT ownership
function holdsConvexoLPs(address user) returns (bool)
function holdsConvexoVaults(address user) returns (bool)
function holdsConvexoPassport(address user) returns (bool)

// Get detailed info
function getReputationDetails(address user) 
    returns (
        ReputationTier tier,
        uint256 lpsBalance,
        uint256 vaultsBalance,
        uint256 passportBalance
    )
```

**Deprecated Functions (kept for backward compatibility):**
- `hasCompliantAccess()` → Use `hasLimitedPartnerAccess()`
- `hasCreditscoreAccess()` → Use `hasVaultCreatorAccess()`

---

## 🎯 Quick Reference

### For Individual Investors (Tier 1 - Passport):
1. Verify identity: ZKPassport → `convexoPassport.safeMintWithIdentifier()`
2. Create treasury: `treasuryFactory.createTreasury()`
3. Invest in vaults: `vault.purchaseShares(amount)`
4. Track returns: `vault.getInvestorReturn(address)`
5. Redeem: `vault.redeemShares(shares)` (after full repayment)

### For Limited Partners (Tier 2 - LPs):
1. Verify business: Veriff → `veriffVerifier.approveVerification()` → Convexo_LPs NFT
2. Access LP pools: Trade USDC/ECOP, USDC/ARS, etc.
3. Invest in vaults: `vault.purchaseShares(amount)`
4. All Tier 1 benefits included

### For Vault Creators (Tier 3 - Vaults):
1. Submit financials: AI scoring → Admin mints Convexo_Vaults NFT
2. Create vault: `vaultFactory.createVault()`
3. Wait for funding: `vault.getVaultMetrics().fundingProgress`
4. Attach contract: `vault.attachContract(contractHash)`
5. Withdraw loan: `vault.withdrawFunds()`
6. Repay anytime: `vault.makeRepayment(amount)`
7. All Tier 2 benefits included

### For Admins:
1. Mint NFTs: `convexoLPs.safeMint()`, `convexoVaults.safeMint()`
2. Approve Veriff: `veriffVerifier.approveVerification()`
3. Deploy hooks: `hookDeployer.deploy()`
4. Register pools: `poolRegistry.registerPool()`
5. Configure prices: `priceFeedManager.setPriceFeed()`
6. Attach contracts: `vault.attachContract(contractHash)`

---

## 📊 Dashboard Requirements

### Investor Dashboard Needs (Tier 1+):
```typescript
// Check tier and access
const tier = await reputationManager.getReputationTierNumeric(userAddress);
const canInvest = await reputationManager.canInvestInVaults(userAddress);

// Main metrics
const metrics = await vault.getVaultMetrics();

// User's position
const returns = await vault.getInvestorReturn(userAddress);

// Interest tracking
const [accrued, remaining] = await vault.getAccruedInterest();

// Share balance
const shares = await vault.balanceOf(userAddress);
```

### Borrower Dashboard Needs (Tier 3):
```typescript
// Repayment status
const [due, paid, remaining, fee] = await vault.getRepaymentStatus();

// Vault timeline
const createdAt = await vault.getVaultCreatedAt();
const fundedAt = await vault.getVaultFundedAt();
const fundsWithdrawnAt = await vault.getVaultFundsWithdrawnAt();
const actualDueDate = await vault.getActualDueDate();

// Vault state
const state = await vault.getVaultState();
```

### Treasury Dashboard Needs (Tier 1+):
```typescript
// List treasuries
const treasuryIds = await treasuryFactory.getTreasuriesByOwner(userAddress);

// Treasury balance
const balance = await treasury.getBalance();

// Pending proposals
const proposal = await treasury.getProposal(proposalId);
```

---

## 🆕 What's New in v2.1

### New Contracts (12 total)
1. **TreasuryFactory** - Create multi-sig treasuries (Tier 1+)
2. **TreasuryVault** - Multi-sig USDC treasury management
3. **VeriffVerifier** - Human-approved KYC/KYB for Tier 2

### Tier System Changes
- **Tier 1**: Passport (Individual) - Treasury creation + Vault investments
- **Tier 2**: LPs (Limited Partner) - LP pools + Vault investments
- **Tier 3**: Vaults (Vault Creator) - Vault creation + All benefits
- **Progressive KYC**: Highest tier wins (no mutual exclusivity)

### New ReputationManager Functions
- `canCreateTreasury()` - Tier 1+
- `canInvestInVaults()` - Tier 1+
- `canAccessLPPools()` - Tier 2+
- `canCreateVaults()` - Tier 3

### Privacy-Compliant Passport
- Only verification traits stored (no PII)
- Traits: `kycVerified`, `faceMatchPassed`, `sanctionsPassed`, `isOver18`

### Vault Redemption Update
- Redemption now requires **full repayment** when in Repaying state
- Early exit allowed when vault is Funded/Active (before borrower withdrawal)

---

**This reference covers all core functions for the 12 Convexo contracts. For deployment details, see `FRONTEND_INTEGRATION.md`.**

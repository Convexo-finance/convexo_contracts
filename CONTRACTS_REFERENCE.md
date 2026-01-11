# Convexo Contracts Reference

**Version 3.0** | Solidity ^0.8.27 | **Privacy-Enhanced Verification**

> **📍 Contract Addresses:** See [addresses.json](./addresses.json)

---

## Tier System

| Tier | NFT | Verification | Access |
|------|-----|--------------|--------|
| **0** | None | - | No access |
| **1** | Convexo_Passport | ZKPassport | **LP Pool Swaps** (via Uniswap V4 hook) + Vault investments |
| **2** | LP_Individuals / LP_Business | Veriff / Sumsub | **Request Credit Score** + Monetization + OTC Orders + Vault investments |
| **3** | Ecreditscoring | AI Credit Score | All above + **Vault creation** |

**Note:**
- **Limited_Partners_Individuals** and **Limited_Partners_Business** grant identical permissions (Tier 2)
- They differ only as identity markers: Individual (KYC via Veriff) vs Business (KYB via Sumsub)
- Both can request credit scoring to upgrade to Tier 3 (Ecreditscoring NFT)

---

## ReputationManager

Central hub for NFT-based access control.

```solidity
enum ReputationTier { None, Passport, LimitedPartner, VaultCreator }
```

### Read Functions

```solidity
// Get user tier (0-3)
function getReputationTier(address user) returns (ReputationTier)
function getReputationTierNumeric(address user) returns (uint256)

// Access checks
function canAccessLPPools(address user) returns (bool)      // Tier 1+
function canCreateTreasury(address user) returns (bool)     // Tier 1+
function canInvestInVaults(address user) returns (bool)     // Tier 1+
function canRequestCreditScore(address user) returns (bool) // Tier 2+
function canCreateVaults(address user) returns (bool)       // Tier 3

// NFT balance checks
function holdsPassport(address user) returns (bool)
function holdsLPIndividuals(address user) returns (bool)
function holdsLPBusiness(address user) returns (bool)
function holdsAnyLP(address user) returns (bool)
function holdsEcreditscoring(address user) returns (bool)

// Detailed info
function getReputationDetails(address user) returns (
    ReputationTier tier,
    uint256 passportBalance,
    uint256 lpIndividualsBalance,
    uint256 lpBusinessBalance,
    uint256 ecreditscoringBalance
)
```

---

## Convexo_Passport

**Purpose**: Soulbound NFT for ZKPassport-verified individuals (Tier 1)  
**IPFS Integration**: Pinata with custom gateway `lime-famous-condor-7.mypinata.cloud`  
**Image Hash**: `bafybeiekwlyujx32cr5u3ixt5esfxhusalt5ljtrmsng74q7k45tilugh4`

### Write Functions

```solidity
// Simplified mint with verification results and IPFS metadata
function safeMintWithVerification(
    bytes32 uniqueIdentifier,     // Unique ID from ZKPassport
    bytes32 personhoodProof,      // Personhood proof from ZKPassport
    bool sanctionsPassed,         // Sanctions check result
    bool isOver18,                // Age verification result
    bool faceMatchPassed,         // Private face match result
    string calldata ipfsMetadataHash // IPFS hash for NFT metadata
) returns (uint256 tokenId)

// Revoke passport
function revokePassport(uint256 tokenId) // REVOKER_ROLE
```

### Read Functions

```solidity
function holdsActivePassport(address holder) returns (bool)
function getVerifiedIdentity(address holder) returns (VerifiedIdentity memory)
function isIdentifierUsed(bytes32 uniqueIdentifier) returns (bool)
function getActivePassportCount() returns (uint256)
```

### VerifiedIdentity Struct

```solidity
struct VerifiedIdentity {
    bytes32 uniqueIdentifier;
    bytes32 personhoodProof;
    uint256 verifiedAt;
    uint256 zkPassportTimestamp;
    bool isActive;
    bool kycVerified;
    bool faceMatchPassed;
    bool sanctionsPassed;
    bool isOver18;
}
```

---

## TokenizedBondVault

ERC20 vault for tokenized bonds. Investors purchase shares, borrowers repay with interest.

### Vault States

```solidity
enum VaultState { Pending, Funded, Active, Repaying, Completed, Defaulted }
```

### Write Functions (Investor)

```solidity
// Purchase shares with USDC (Tier 1+ required)
function purchaseShares(uint256 amount)

// Redeem shares for USDC (after full repayment)
function redeemShares(uint256 shares)
```

### Write Functions (Borrower)

```solidity
// Withdraw funds after contract signed
function withdrawFunds()

// Make repayment
function makeRepayment(uint256 amount)
```

### Write Functions (Admin)

```solidity
function attachContract(bytes32 _contractHash) // VAULT_MANAGER_ROLE
function markAsDefaulted() // VAULT_MANAGER_ROLE
function withdrawProtocolFees()
```

### Read Functions

```solidity
function getVaultMetrics() returns (
    uint256 totalShares,
    uint256 sharePrice,
    uint256 totalValueLocked,
    uint256 targetAmount,
    uint256 fundingProgress,
    uint256 currentAPY
)

function getInvestorReturn(address investor) returns (
    uint256 invested,
    uint256 currentValue,
    uint256 profit,
    uint256 apy
)

function getRepaymentStatus() returns (
    uint256 totalDue,
    uint256 totalPaid,
    uint256 remaining,
    uint256 protocolFee
)

function getAvailableForInvestors() returns (uint256)
function getVaultState() returns (VaultState)
function getVaultCreatedAt() returns (uint256)
function getVaultFundedAt() returns (uint256)
function getVaultContractAttachedAt() returns (uint256)
function getVaultFundsWithdrawnAt() returns (uint256)
function getActualDueDate() returns (uint256)
function getInvestors() returns (address[] memory)
```

---

## VaultFactory

Creates TokenizedBondVault instances. Requires Tier 3.

### Write Functions

```solidity
function createVault(
    uint256 principalAmount,  // USDC (6 decimals)
    uint256 interestRate,     // Basis points (1200 = 12%)
    uint256 protocolFeeRate,  // Basis points (200 = 2%)
    uint256 maturityDate,     // Unix timestamp
    string memory name,
    string memory symbol
) returns (uint256 vaultId, address vaultAddress)
```

### Read Functions

```solidity
function getVault(uint256 vaultId) returns (address)
function getVaultCount() returns (uint256)
function getVaultAddressAtIndex(uint256 index) returns (address)
```

---

## TreasuryFactory

Creates personal TreasuryVault instances. Requires Tier 1+.

### Write Functions

```solidity
function createTreasury(
    address[] memory signers,      // Empty for single-sig
    uint256 signaturesRequired     // 0 for single-sig
) returns (uint256 treasuryId, address treasuryAddress)
```

### Read Functions

```solidity
function getTreasury(uint256 treasuryId) returns (address)
function getTreasuryCount() returns (uint256)
function getTreasuriesByOwner(address owner) returns (uint256[] memory)
function getTreasuryCountByOwner(address owner) returns (uint256)
```

---

## TreasuryVault

Multi-sig USDC treasury management.

### Write Functions

```solidity
function deposit(uint256 amount)
function proposeWithdrawal(address recipient, uint256 amount, string calldata reason) returns (uint256 proposalId)
function approveWithdrawal(uint256 proposalId)
function executeWithdrawal(uint256 proposalId)
```

### Read Functions

```solidity
function getBalance() returns (uint256)
function getProposal(uint256 proposalId) returns (Proposal memory)
```

---

## ContractSigner

Multi-party on-chain contract signing.

### Write Functions

```solidity
function createContract(
    bytes32 documentHash,
    AgreementType agreementType,
    address[] requiredSigners,
    string ipfsHash,
    uint256 nftReputationTier,
    uint256 expiryDuration
)

function signContract(bytes32 documentHash, bytes signature)
function executeContract(bytes32 documentHash, uint256 vaultId)
```

### Read Functions

```solidity
function getContract(bytes32 documentHash) returns (ContractDocument memory)
function isFullySigned(bytes32 documentHash) returns (bool)
function isContractSigned(bytes32 documentHash, address signer) returns (bool)
```

---

## Verification System Architecture (Tier 2)

### Overview

**Tier 2 uses a PRIVACY-ENHANCED two-contract system:**

1. **Verifier Contracts** (VeriffVerifier, SumsubVerifier) = **Private Registry & Approval Workflow**
   - Store verification submissions with PRIVATE data (admin-only access)
   - Admin reviews private data and approves/rejects
   - **NO auto-mint on approval** - status changes to Approved only
   - Public can only check `hasVerificationRecord()` and `getStatus()` (no details)

2. **NFT Contracts** (Limited_Partners_Individuals, Limited_Partners_Business) = **Access Token**
   - Soulbound ERC721 tokens
   - Grant identical Tier 2 permissions (only difference: person vs business identifier)
   - Admin manually mints after verification approval
   - **Auto-callback** to verifier on mint to update status to Minted

**Privacy Model:**
- All verification data (session IDs, company names, etc.) is PRIVATE
- Events emit minimal info (user address, timestamp only)
- Public can check existence and status, but not details

**Key Point:** Both LP NFT types grant the same access:
- ✅ Request Credit Score (upgrade to Tier 3)
- ✅ Monetization features
- ✅ OTC Orders
- ✅ Vault investments

### Verification Flow (Privacy-Enhanced)

```
┌─────────────────────────────────────────────────────────────┐
│  INDIVIDUAL PATH (Veriff) - MANUAL MINT                      │
│                                                              │
│  1. User completes Veriff KYC                                │
│  2. Backend → VeriffVerifier.submitVerification()            │
│  3. Admin reviews PRIVATE data                               │
│  4. Admin → VeriffVerifier.approveVerification()             │
│     └── Status: Approved (NO auto-mint)                      │
│  5. Admin → Limited_Partners_Individuals.safeMint()          │
│     └── NFT callback → VeriffVerifier.markAsMinted()         │
│  6. User receives LP Individual NFT (Tier 2)                 │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  BUSINESS PATH (Sumsub) - MANUAL MINT                        │
│                                                              │
│  1. Business completes Sumsub KYB                            │
│  2. Backend → SumsubVerifier.submitVerification()            │
│  3. Admin reviews PRIVATE data                               │
│  4. Admin → SumsubVerifier.approveVerification()             │
│     └── Status: Approved (NO auto-mint)                      │
│  5. Admin → Limited_Partners_Business.safeMint()             │
│     └── NFT callback → SumsubVerifier.markAsMinted()         │
│  6. Business receives LP Business NFT (Tier 2)               │
└─────────────────────────────────────────────────────────────┘
```

---

## VeriffVerifier (Registry Contract)

**Purpose:** Privacy-enhanced KYC registry for individual Limited Partners.

**Architecture:** This is NOT the NFT contract. It acts as a PRIVATE registry that:
- Stores verification submissions with PRIVATE data (admin-only access)
- Requires admin approval before minting (NO auto-mint)
- NFT contract calls `markAsMinted()` after manual mint

**Privacy Features:**
- All verification data is PRIVATE (admin-only via `VERIFIER_ROLE`)
- Public can only check `hasVerificationRecord()`, `getStatus()`, `isApproved()`, `isMinted()`
- Events emit no sensitive data (user address and timestamp only)

### Verification States

```solidity
enum VerificationStatus {
    None,       // 0 - No submission
    Pending,    // 1 - Submitted, awaiting admin review
    Approved,   // 2 - Approved but NFT NOT yet minted
    Rejected,   // 3 - Rejected by admin
    Minted      // 4 - Approved AND NFT minted (via callback)
}
```

### Write Functions

```solidity
// Submit verification result (backend calls this after Veriff webhook)
function submitVerification(address user, string calldata sessionId) // VERIFIER_ROLE

// Approve verification (NO auto-mint - status changes to Approved only)
function approveVerification(address user) // VERIFIER_ROLE

// Reject with reason
function rejectVerification(address user, string calldata reason) // VERIFIER_ROLE

// Reset rejected verification (allows resubmission)
function resetVerification(address user) // DEFAULT_ADMIN_ROLE

// Called by NFT contract after minting (updates status to Minted)
function markAsMinted(address user, uint256 tokenId) // MINTER_CALLBACK_ROLE
```

### Read Functions (Admin-Only - VERIFIER_ROLE)

```solidity
function getVerificationRecord(address user) returns (VerificationRecord memory)
function getSessionId(address user) returns (string memory)
function isSessionIdUsed(string calldata sessionId) returns (bool)
function getUserBySessionId(string calldata sessionId) returns (address)
```

### Read Functions (Public - No sensitive data)

```solidity
function hasVerificationRecord(address user) returns (bool)
function getStatus(address user) returns (VerificationStatus)
function isApproved(address user) returns (bool)  // Status == Approved
function isMinted(address user) returns (bool)    // Status == Minted
function isVerified(address user) returns (bool)  // Approved OR Minted
```

### Role Management (Multi-Admin Support)

```solidity
// Add/remove compliance officers (VERIFIER_ROLE)
function addVerifier(address account) // DEFAULT_ADMIN_ROLE
function removeVerifier(address account) // DEFAULT_ADMIN_ROLE
function isVerifier(address account) returns (bool)

// Add/remove admins
function addAdmin(address account) // DEFAULT_ADMIN_ROLE
function removeAdmin(address account) // DEFAULT_ADMIN_ROLE (cannot remove self)
function isAdmin(address account) returns (bool)

// Manage NFT callback permissions
function addMinterCallback(address nftContract) // DEFAULT_ADMIN_ROLE
function removeMinterCallback(address nftContract) // DEFAULT_ADMIN_ROLE
function hasMinterCallback(address account) returns (bool)
```

---

## SumsubVerifier (Registry Contract)

**Purpose:** Privacy-enhanced KYB registry for business Limited Partners.

**Architecture:** This is NOT the NFT contract. It acts as a PRIVATE registry that:
- Stores business verification submissions with PRIVATE company details
- Requires admin approval before minting (NO auto-mint)
- NFT contract calls `markAsMinted()` after manual mint

**Privacy Features:**
- All verification data is PRIVATE (admin-only via `VERIFIER_ROLE`)
- Company names, registration numbers, etc. are NOT publicly readable
- Public can only check `hasVerificationRecord()`, `getStatus()`, `isApproved()`, `isMinted()`
- Events emit no sensitive data (user address and timestamp only)

### Verification States

```solidity
enum VerificationStatus {
    None,       // 0 - No submission
    Pending,    // 1 - Submitted, awaiting admin review
    Approved,   // 2 - Approved but NFT NOT yet minted
    Rejected,   // 3 - Rejected by admin
    Minted      // 4 - Approved AND NFT minted (via callback)
}
```

### Write Functions

```solidity
// Submit KYB verification (backend calls this after Sumsub webhook)
function submitVerification(
    address user,
    string calldata applicantId,
    string calldata companyName,
    string calldata registrationNumber,
    string calldata jurisdiction,
    BusinessType businessType
) // VERIFIER_ROLE

// Approve verification (NO auto-mint - status changes to Approved only)
function approveVerification(address user) // VERIFIER_ROLE

// Reject with reason
function rejectVerification(address user, string calldata reason) // VERIFIER_ROLE

// Reset rejected verification (allows resubmission)
function resetVerification(address user) // DEFAULT_ADMIN_ROLE

// Called by NFT contract after minting (updates status to Minted)
function markAsMinted(address user, uint256 tokenId) // MINTER_CALLBACK_ROLE
```

### Read Functions (Admin-Only - VERIFIER_ROLE)

```solidity
function getVerificationRecord(address user) returns (VerificationRecord memory)
function getCompanyDetails(address user) returns (companyName, registrationNumber, jurisdiction, businessType)
function isApplicantIdUsed(string calldata applicantId) returns (bool)
function isRegistrationUsed(string calldata registrationNumber) returns (bool)
function getUserByApplicantId(string calldata applicantId) returns (address)
function getUserByRegistration(string calldata registrationNumber) returns (address)
```

### Read Functions (Public - No sensitive data)

```solidity
function hasVerificationRecord(address user) returns (bool)
function getStatus(address user) returns (VerificationStatus)
function isApproved(address user) returns (bool)  // Status == Approved
function isMinted(address user) returns (bool)    // Status == Minted
function isVerified(address user) returns (bool)  // Approved OR Minted
```

### Role Management (Multi-Admin Support)

```solidity
// Add/remove compliance officers (VERIFIER_ROLE)
function addVerifier(address account) // DEFAULT_ADMIN_ROLE
function removeVerifier(address account) // DEFAULT_ADMIN_ROLE
function isVerifier(address account) returns (bool)

// Add/remove admins
function addAdmin(address account) // DEFAULT_ADMIN_ROLE
function removeAdmin(address account) // DEFAULT_ADMIN_ROLE (cannot remove self)
function isAdmin(address account) returns (bool)

// Manage NFT callback permissions
function addMinterCallback(address nftContract) // DEFAULT_ADMIN_ROLE
function removeMinterCallback(address nftContract) // DEFAULT_ADMIN_ROLE
function hasMinterCallback(address account) returns (bool)
```

---

## Limited_Partners_Individuals (NFT Contract)

**Purpose:** Soulbound NFT for verified individual Limited Partners (Tier 2)  
**IPFS Integration**: Pinata with custom gateway `lime-famous-condor-7.mypinata.cloud`  
**Image Hash**: `bafkreib7mkjzpdm3id6st6d5vsxpn7v5h6sxeiswejjmrbcb5yoagaf4em`

**Architecture:** This is the ERC721 NFT contract with verifier callback:
- Admin manually mints after verification approval
- On mint, auto-calls `VeriffVerifier.markAsMinted()` to update status

**Verifier Callback:**
- Constructor takes `_verifier` address (immutable)
- `safeMint()` calls `verifier.markAsMinted(to, tokenId)` after minting
- Ensures verifier status stays in sync with NFT ownership

**Access Granted:**
- Request credit score (upgrade to Tier 3 Ecreditscoring NFT)
- Monetization features
- OTC Orders
- Vault investments

**Note:** This NFT grants the SAME permissions as Limited_Partners_Business. The only difference is the identity marker (individual vs business).

### Write Functions

```solidity
// Mint NFT and trigger verifier callback
function safeMint(address to, string memory verificationId, string memory uri) returns (uint256) // MINTER_ROLE
// After mint: calls verifierContract.markAsMinted(to, tokenId)

// Set token state
function setTokenState(uint256 tokenId, bool isActive) // DEFAULT_ADMIN_ROLE

// Burn token
function burn(uint256 tokenId) // Token owner only
```

### Read Functions

```solidity
function balanceOf(address owner) returns (uint256)
function ownerOf(uint256 tokenId) returns (address)
function getTokenState(uint256 tokenId) returns (bool)
function getVerificationId(uint256 tokenId) returns (string memory) // Admin only
function verifierContract() returns (address) // Immutable verifier address
```

---

## Limited_Partners_Business (NFT Contract)

**Purpose:** Soulbound NFT for verified business Limited Partners (Tier 2)  
**IPFS Integration**: Pinata with custom gateway `lime-famous-condor-7.mypinata.cloud`  
**Image Hash**: `bafkreiejesvgsvohwvv7q5twszrbu5z6dnpke6sg5cdiwgn2rq7dilu33m`

**Architecture:** This is the ERC721 NFT contract with verifier callback:
- Admin manually mints after verification approval
- On mint, auto-calls `SumsubVerifier.markAsMinted()` to update status

**Verifier Callback:**
- Constructor takes `_verifier` address (immutable)
- `safeMint()` calls `verifier.markAsMinted(to, tokenId)` after minting
- Ensures verifier status stays in sync with NFT ownership

**Access Granted:**
- Request credit score (upgrade to Tier 3 Ecreditscoring NFT)
- Monetization features
- OTC Orders
- Vault investments

**Note:** This NFT grants the SAME permissions as Limited_Partners_Individuals. The only difference is the identity marker (business vs individual).

### Write Functions

```solidity
// Mint NFT and trigger verifier callback
function safeMint(
    address to,
    string memory companyName,
    string memory registrationNumber,
    string memory jurisdiction,
    BusinessType businessType,
    string memory sumsubApplicantId,
    string memory uri
) returns (uint256) // MINTER_ROLE
// After mint: calls verifierContract.markAsMinted(to, tokenId)

// Set token state
function setTokenState(uint256 tokenId, bool isActive) // DEFAULT_ADMIN_ROLE

// Burn token
function burn(uint256 tokenId) // Token owner only
```

### Read Functions

```solidity
function balanceOf(address owner) returns (uint256)
function ownerOf(uint256 tokenId) returns (address)
function getTokenState(uint256 tokenId) returns (bool)
function getCompanyName(uint256 tokenId) returns (string memory) // Public
function getBusinessInfo(uint256 tokenId) returns (BusinessInfo memory) // Admin only
function verifierContract() returns (address) // Immutable verifier address
```

---

## Ecreditscoring (NFT Contract)

**Purpose:** Soulbound NFT for users with AI Credit Score approval (Tier 3)  
**IPFS Integration**: Pinata with custom gateway `lime-famous-condor-7.mypinata.cloud`  
**Image Hash**: `bafkreignxas6gqi7it5ng6muoykujxlgxxc4g7rr6sqvwgdfwveqf2zw3e`  
**Prerequisites**: Must hold LP_Individuals OR LP_Business NFT

### Write Functions

```solidity
// Mint credit NFT (requires LP NFT)
function safeMint(
    address to,
    uint256 score,                // Credit score (0-100)
    CreditTier tier,             // Bronze, Silver, Gold, Platinum
    uint256 maxLoanAmount,       // Maximum loan amount allowed
    string memory referenceId,   // External reference ID
    string memory uri            // IPFS metadata URI
) returns (uint256) // MINTER_ROLE

// Update credit info for re-scoring
function updateCreditInfo(
    uint256 tokenId,
    uint256 score,
    CreditTier tier,
    uint256 maxLoanAmount,
    string memory referenceId,
    uint256 scoredAt
) // MINTER_ROLE
```

### Read Functions

```solidity
function hasLPStatus(address user) returns (bool)
function canReceiveEcreditscoringNFT(address user) returns (bool)
function getCreditInfo(uint256 tokenId) returns (CreditInfo memory)
function getCreditTier(uint256 tokenId) returns (CreditTier)
function getMaxLoanAmount(uint256 tokenId) returns (uint256)
```

---

## CompliantLPHook (Uniswap V4 Integration)

**Purpose:** Uniswap V4 hook that gates LP pool access to Tier 1+ users.

**Architecture:** This hook is attached to Uniswap V4 liquidity pools to enforce KYC requirements.

**Access Requirements:**
- **Tier 1 (Convexo_Passport)**: ✅ Can swap, add liquidity, remove liquidity
- **Tier 2+ (Limited Partners, Vault Creators)**: ✅ Can swap, add liquidity, remove liquidity
- **Tier 0 (No NFT)**: ❌ Cannot interact with gated pools

**Key Feature:** This is THE contract that enables Tier 1 passport holders to access LP pools.

### Hook Functions (Automatic)

These functions are called automatically by Uniswap V4 before each operation:

```solidity
function beforeSwap(...) // Requires Tier 1+ (Convexo_Passport or higher)
function beforeAddLiquidity(...) // Requires Tier 1+ (Convexo_Passport or higher)
function beforeRemoveLiquidity(...) // Requires Tier 1+ (Convexo_Passport or higher)
```

**Integration:** Liquidity pools register this hook via the PoolRegistry contract.

---

## PoolRegistry

Registry for compliant liquidity pools.

### Write Functions

```solidity
function registerPool(
    address poolAddress,
    address token0,
    address token1,
    address hookAddress,
    string description
) returns (bytes32 poolId)
```

### Read Functions

```solidity
function getPool(bytes32 poolId) returns (PoolInfo memory)
function getPoolCount() returns (uint256)
function getPoolIdAtIndex(uint256 index) returns (bytes32)
```

---

## PriceFeedManager

Chainlink price feed management for currency conversion.

### Write Functions

```solidity
function setPriceFeed(CurrencyPair pair, address aggregator, uint256 heartbeat)
```

### Read Functions

```solidity
function getLatestPrice(CurrencyPair pair) returns (int256 price, uint8 decimals)
function convertUSDCToLocal(CurrencyPair pair, uint256 usdcAmount) returns (uint256)
function convertLocalToUSDC(CurrencyPair pair, uint256 localAmount) returns (uint256)
```

---

## Access Control Roles

| Role | Contract | Permission |
|------|----------|------------|
| `DEFAULT_ADMIN_ROLE` | All | Full admin |
| `MINTER_ROLE` | NFTs | Can mint |
| `REVOKER_ROLE` | Convexo_Passport | Can revoke |
| `VERIFIER_ROLE` | VeriffVerifier, SumsubVerifier | Can submit/approve/reject, read private data |
| `MINTER_CALLBACK_ROLE` | VeriffVerifier, SumsubVerifier | Can call markAsMinted (granted to NFT contracts) |
| `VAULT_MANAGER_ROLE` | TokenizedBondVault | Can attach contracts |

---

## Events

### Verifier Events (Privacy-Enhanced - No sensitive data)
```solidity
// VeriffVerifier & SumsubVerifier
event VerificationSubmitted(address indexed user, uint256 timestamp)
event VerificationApproved(address indexed user, address indexed approver, uint256 timestamp)
event VerificationRejected(address indexed user, address indexed rejector, uint256 timestamp)
event VerificationMinted(address indexed user, uint256 tokenId, uint256 timestamp)
```

### Passport Events
```solidity
event PassportMinted(address indexed holder, uint256 tokenId, bytes32 uniqueIdentifier, ...)
event PassportRevoked(address indexed holder, uint256 tokenId, bytes32 uniqueIdentifier)
```

### Vault Events
```solidity
event SharesPurchased(address indexed investor, uint256 amount, uint256 shares)
event RepaymentMade(uint256 amount, uint256 totalRepaid)
event SharesRedeemed(address indexed investor, uint256 shares, uint256 amount)
event VaultStateChanged(VaultState newState)
event VaultFullyFunded(uint256 indexed vaultId, uint256 timestamp)
event ContractAttached(uint256 indexed vaultId, bytes32 contractHash)
event FundsWithdrawn(address indexed borrower, uint256 amount)
```

### Factory Events
```solidity
event VaultCreated(uint256 indexed vaultId, address indexed vaultAddress, address indexed borrower, ...)
event TreasuryCreated(uint256 indexed treasuryId, address indexed treasuryAddress, address indexed owner, ...)
```

---

*For contract addresses, see [addresses.json](./addresses.json).*

# Convexo Contracts Reference

**Version 3.17** | Solidity ^0.8.27 | **Arbitrum support + Treasury deprecated + Folder reorganization + ZKPassport on-chain trustless verification**

> **📍 Contract Addresses:** See [addresses.json](./addresses.json)

---

## Supported Networks

| Chain ID | Network | Type | Explorer |
|----------|---------|------|----------|
| **1** | Ethereum Mainnet | Mainnet | etherscan.io |
| **8453** | Base Mainnet | Mainnet | basescan.org |
| **130** | Unichain Mainnet | Mainnet | unichain.blockscout.com |
| **42161** | Arbitrum One | Mainnet | arbiscan.io |
| **11155111** | Ethereum Sepolia | Testnet | sepolia.etherscan.io |
| **84532** | Base Sepolia | Testnet | sepolia.basescan.org |
| **1301** | Unichain Sepolia | Testnet | unichain-sepolia.blockscout.com |
| **421614** | Arbitrum Sepolia | Testnet | sepolia.arbiscan.io |

**Note:** Arbitrum One (42161) and Arbitrum Sepolia (421614) added in v3.17. All addresses pending redeploy with salt `convexo.v3.17`.

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
**Verification**: Fully trustless — ZK proof verified on-chain by `IZKPassportVerifier` (no admin bypass)
**ZKPassport Verifier**: `0x1D000001000EFD9a6371f4d90bB8920D5431c0D8` (Ethereum, Ethereum Sepolia, Base, Base Sepolia)
**App Domain**: `protocol.convexo.xyz` | **App Scope**: `convexo-passport-identity`

### Write Functions

```solidity
// Self-claim — caller submits ZK proof, verified on-chain
// ProofVerificationParams from ZKPassport SDK getSolidityVerifierParameters()
// Bound requirements: proof.bound.senderAddress == msg.sender, proof.bound.chainId == block.chainid
// Checks (in order): verify proof → scope → sender binding → chain binding → age 18+ → sanctions → nationality → expiry → sybil
function claimPassport(
    ProofVerificationParams calldata proof,  // full ZK proof from SDK
    bool isIDCard,                           // false=passport, true=ID card
    string calldata ipfsMetadataHash         // IPFS hash for NFT metadata
) returns (uint256 tokenId)

// Revoke passport (admin only)
function revokePassport(uint256 tokenId) // REVOKER_ROLE
```

### Read Functions

```solidity
function holdsActivePassport(address holder) returns (bool)
function getVerifiedIdentity(address holder) returns (VerifiedIdentity memory)
function isIdentifierUsed(bytes32 uniqueIdentifier) returns (bool)  // bytes32 from ZKPassport verifier
function getActivePassportCount() returns (uint256)
```

### VerifiedIdentity Struct

```solidity
struct VerifiedIdentity {
    bytes32 identifierHash;       // uniqueIdentifier returned by IZKPassportVerifier (sybil-resistant)
    uint256 verifiedAt;           // block.timestamp at mint
    uint256 zkPassportTimestamp;  // timestamp from ZKPassport proof
    bool isActive;
    bool isIDCard;                // false=passport, true=ID card
    bool sanctionsPassed;
    bool isOver18;
    bool nationalityCompliant;    // nationality not in sanctioned countries list
}
```

### Custom Errors

```solidity
error ProofVerificationFailed()      // IZKPassportVerifier.verify returned false
error InvalidScope()                 // proof.service.scope != APP_SCOPE
error InvalidSender()                // proof.bound.senderAddress != msg.sender
error InvalidChain()                 // proof.bound.chainId != block.chainid
error AgeVerificationFailed()        // helper.isAgeValid() failed or age < 18
error SanctionsCheckFailed()         // helper.isSanctionsValid() returned false (sanctions hit)
error NationalityNotCompliant()      // nationality in sanctioned countries list
error PassportExpired()              // helper.isExpiryValid() returned false
error AlreadyHasPassport()           // wallet already owns a passport
error IdentifierAlreadyUsed()        // same real-world identity already minted
error SoulboundTokenCannotBeTransferred()
```

### Sanctioned Countries (nationality block list)
20 countries (alphabetically sorted, ISO 3166-1 alpha-3):
`AFG, BLR, CAF, COD, CUB, IRN, IRQ, LBY, MLI, MMR, NIC, PRK, RUS, SDN, SOM, SSD, SYR, VEN, YEM, ZWE`

---

## TokenizedBondVault

**ERC-7540 async-redeem vault** for tokenized bonds. Investors buy shares at a fixed base price; borrowers repay with interest; investors claim pro-rata as repayments accumulate.

### Economics Model

| Concept | Formula |
|---------|---------|
| Base share price | `principalAmount / totalShareSupply` (USDC 6-dec) |
| Expected final price | `(principal + interest − fee) / totalShareSupply` |
| Current share price | `basePrice + (finalPrice − basePrice) × repaidFraction` — interpolated, deterministic |
| Share denomination | ERC-20 with 18 decimals (`totalShareSupply × 1e18` minted at deployment) |
| Min investment | Settable by borrower (VAULT_MANAGER_ROLE), default $100 USDC |

### Vault States

```solidity
enum VaultState { Pending, Funded, Active, Repaying, Completed, Defaulted }
```

### Write Functions (Investor)

```solidity
// ERC-4626: deposit USDC, receive shares (Tier 1+ required, state: Pending/Funded)
function deposit(uint256 assets, address receiver) returns (uint256 shares)

// ERC-7540: lock shares for async redemption (state: Repaying/Completed)
// requestId is always 0; shares locked until claimed
function requestRedeem(uint256 shares, address controller, address owner) returns (uint256 requestId)

// ERC-7540: claim USDC proportional to repaid fraction (can call multiple times as repayments accumulate)
// assets: how much USDC to claim (≤ claimableNow)
function redeem(uint256 shares, address receiver, address controller) returns (uint256 assets)

// Exit before borrower withdraws (state: Pending/Funded) — refund at base price
function earlyExit(uint256 shares)
```

### Write Functions (Borrower)

```solidity
// Withdraw raised funds (contract must be signed)
function withdrawFunds()

// Repay USDC; triggers state → Repaying (first repayment) or → Completed (if fully paid)
function makeRepayment(uint256 amount)
```

### Write Functions (Admin/Borrower)

```solidity
function attachContract(bytes32 _contractHash) // VAULT_MANAGER_ROLE
function markAsDefaulted()                     // VAULT_MANAGER_ROLE
function withdrawProtocolFees()
function setMinInvestment(uint256 amount)       // VAULT_MANAGER_ROLE
```

### Read Functions (ERC-7540)

```solidity
// Always returns 0 (all requests immediately claimable)
function pendingRedeemRequest(uint256 requestId, address controller) returns (uint256)

// Returns the remaining locked shares the controller has ready to claim
function claimableRedeemRequest(uint256 requestId, address controller) returns (uint256)
```

### Read Functions (ERC-4626)

```solidity
function asset() returns (address)                           // USDC address
function totalAssets() returns (uint256)                     // USDC in vault
function convertToShares(uint256 assets) returns (uint256)
function convertToAssets(uint256 shares) returns (uint256)
function maxDeposit(address receiver) returns (uint256)
function previewDeposit(uint256 assets) returns (uint256)
```

### Read Functions (Vault-Specific)

```solidity
function getBaseSharePrice() returns (uint256)         // principalAmount / originalTotalShares (USDC 6-dec)
function getExpectedFinalSharePrice() returns (uint256) // (principal + interest − fee) / originalTotalShares
function getCurrentSharePrice() returns (uint256)      // interpolated price at current repaid fraction
function originalTotalShares() returns (uint256)       // totalShareSupply × 1e18 (immutable)
function minInvestment() returns (uint256)             // minimum USDC per deposit

function getVaultBorrower() returns (address)
function getVaultPrincipalAmount() returns (uint256)
function getVaultTotalRepaid() returns (uint256)
function getVaultState() returns (VaultState)

function getRedeemState(address controller) returns (
    uint256 originalLockedShares,
    uint256 remainingLockedShares,
    uint256 assetsClaimed,
    uint256 claimableNow
)

function getRepaymentStatus() returns (
    uint256 totalDue,    // principal + interest + fee
    uint256 totalPaid,
    uint256 remaining,
    uint256 protocolFee
)

function getInvestorReturn(address investor) returns (
    uint256 invested,      // USDC deposited
    uint256 currentValue,  // at current share price
    uint256 profit,
    uint256 apy
)

function getVaultCreatedAt() returns (uint256)
function getVaultFundedAt() returns (uint256)
function getActualDueDate() returns (uint256)
function getInvestors() returns (address[] memory)

// ERC-165: announces ERC-7540 operator (0xe3bc4e65) + async redeem (0x620ee8e4)
function supportsInterface(bytes4 interfaceId) returns (bool)
```

---

## VaultFactory

Creates TokenizedBondVault instances. Requires Tier 3 (Ecreditscoring NFT).

### Write Functions

```solidity
function createVault(
    uint256 principalAmount,   // Total USDC to raise (6 decimals, e.g. 100_000e6 = $100k)
    uint256 interestRate,      // Basis points (e.g. 1200 = 12%)
    uint256 protocolFeeRate,   // Basis points (e.g. 200 = 2%, max 1000)
    uint256 maturityDate,      // Unix timestamp (must be future)
    uint256 totalShareSupply,  // Number of shares (e.g. 1000 → $100/share at $100k raise)
    uint256 minInvestment,     // Minimum USDC per investor deposit (e.g. 100e6 = $100)
    string memory name,        // ERC-20 share token name
    string memory symbol       // ERC-20 share token symbol
) returns (uint256 vaultId, address vaultAddress)

// Guard: principalAmount >= totalShareSupply × 1e6 (share price ≥ $1)
// Guard: canCreateVaults(msg.sender) — Tier 3 required

function updateProtocolFeeCollector(address newCollector) // DEFAULT_ADMIN_ROLE
```

### Read Functions

```solidity
function getVault(uint256 vaultId) returns (address)
function getVaultCount() returns (uint256)
function getVaultAddressAtIndex(uint256 index) returns (address)
function protocolFeeCollector() returns (address)
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

## PassportGatedHook (Uniswap V4 Integration)

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
function _beforeSwap(...) // Requires Tier 1+ (Convexo_Passport or higher)
function _beforeAddLiquidity(...) // Requires Tier 1+ (Convexo_Passport or higher)
function _beforeRemoveLiquidity(...) // Requires Tier 1+ (Convexo_Passport or higher)
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
| `MINTER_ROLE` | LP_Individuals, LP_Business, Ecreditscoring | Can mint (not Convexo_Passport — self-mint) |
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
event PassportMinted(
    address indexed holder,
    uint256 indexed tokenId,
    bytes32 identifierHash,
    bool isIDCard,
    bool nationalityCompliant,
    bool isOver18,
    bool sanctionsPassed
);
event PassportRevoked(address indexed holder, uint256 tokenId, bytes32 identifierHash)
```

### Vault Events
```solidity
// ERC-4626
event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares)
event Withdraw(address indexed sender, address indexed receiver, address indexed owner, uint256 assets, uint256 shares)

// ERC-7540
event RedeemRequest(address indexed controller, address indexed owner, uint256 indexed requestId, address sender, uint256 shares)

// Vault lifecycle
event VaultStateChanged(VaultState newState)
event RepaymentMade(address indexed borrower, uint256 amount, uint256 totalRepaid)
event ContractAttached(bytes32 contractHash)
event FundsWithdrawn(address indexed borrower, uint256 amount)
event EarlyExitProcessed(address indexed investor, uint256 shares, uint256 refund)
event ProtocolFeesWithdrawn(address indexed collector, uint256 amount)
```

### Factory Events
```solidity
event VaultCreated(
    uint256 indexed vaultId,
    address indexed vaultAddress,
    address indexed borrower,
    uint256 principalAmount,
    uint256 totalShareSupply,
    uint256 initialSharePrice  // principalAmount / totalShareSupply (USDC 6-dec)
)
event ProtocolFeeCollectorUpdated(address indexed oldCollector, address indexed newCollector)
```

---

*For contract addresses, see [addresses.json](./addresses.json).*

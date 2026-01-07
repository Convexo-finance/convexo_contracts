# Convexo Contracts Reference

**Version 2.2** | Solidity ^0.8.27

> **📍 Contract Addresses:** See [ETHEREUM_DEPLOYMENTS.md](./ETHEREUM_DEPLOYMENTS.md), [BASE_DEPLOYMENTS.md](./BASE_DEPLOYMENTS.md), [UNICHAIN_DEPLOYMENTS.md](./UNICHAIN_DEPLOYMENTS.md)

---

## Tier System

| Tier | NFT | Verification | Access |
|------|-----|--------------|--------|
| **0** | None | - | No access |
| **1** | Convexo_Passport | ZKPassport | Treasury + Vault investments |
| **2** | LP_Individuals / LP_Business | Veriff / Sumsub | LP pools + Vault investments |
| **3** | Ecreditscoring | AI Credit Score | All above + Vault creation |

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

Soulbound NFT for ZKPassport-verified individuals (Tier 1).

### Write Functions

```solidity
// Self-mint with ZKPassport proof (on-chain verification)
function safeMintWithZKPassport(
    ProofVerificationParams calldata params,
    bool isIDCard
) returns (uint256 tokenId)

// Self-mint with unique identifier (off-chain verification)
function safeMintWithIdentifier(bytes32 uniqueIdentifier) returns (uint256 tokenId)

// Admin mint
function safeMint(address to, string memory uri) returns (uint256 tokenId)

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

## VeriffVerifier

Human-approved KYC for Limited Partners (Tier 2).

### Write Functions

```solidity
// Submit verification result
function submitVerification(address user, string calldata sessionId) // VERIFIER_ROLE

// Approve and mint LP NFT
function approveVerification(address user) // VERIFIER_ROLE

// Reject with reason
function rejectVerification(address user, string calldata reason) // VERIFIER_ROLE

// Reset rejected verification
function resetVerification(address user) // DEFAULT_ADMIN_ROLE
```

### Read Functions

```solidity
function getVerificationStatus(address user) returns (VerificationRecord memory)
function isVerified(address user) returns (bool)
function isSessionIdUsed(string calldata sessionId) returns (bool)
function getUserBySessionId(string calldata sessionId) returns (address)
```

---

## CompliantLPHook

Uniswap V4 hook that gates pool access to Tier 1+.

### Hook Functions (Automatic)

```solidity
function beforeSwap(...) // Requires Tier 1+
function beforeAddLiquidity(...) // Requires Tier 1+
function beforeRemoveLiquidity(...) // Requires Tier 1+
```

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
| `VERIFIER_ROLE` | VeriffVerifier | Can approve/reject |
| `VAULT_MANAGER_ROLE` | TokenizedBondVault | Can attach contracts |

---

## Events

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

*For contract addresses, see chain-specific deployment docs.*

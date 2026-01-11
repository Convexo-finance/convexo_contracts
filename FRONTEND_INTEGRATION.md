# Frontend Integration Guide

**Version**: 3.0 | **Solidity**: ^0.8.27 | **Framework**: React + Viem + Wagmi  
**IPFS**: Pinata Gateway `lime-famous-condor-7.mypinata.cloud`

---

## Table of Contents

1. [Quick Setup](#quick-setup)
2. [Contract Addresses](#contract-addresses)
3. [IPFS Integration](#ipfs-integration)
4. [Tier System](#tier-system)
5. [Contract Functions Reference](#contract-functions-reference)
6. [React Hooks](#react-hooks)
7. [Complete Examples](#complete-examples)

---

## Quick Setup

### Install Dependencies

```bash
npm install viem wagmi @rainbow-me/rainbowkit @tanstack/react-query
```

### Import ABIs

```typescript
// config/abis.ts
import ConvexoPassportABI from '../abis/Convexo_Passport.json';
import LPIndividualsABI from '../abis/Limited_Partners_Individuals.json';
import LPBusinessABI from '../abis/Limited_Partners_Business.json';
import EcreditscoringABI from '../abis/Ecreditscoring.json';
import ReputationManagerABI from '../abis/ReputationManager.json';
import VeriffVerifierABI from '../abis/VeriffVerifier.json';
import SumsubVerifierABI from '../abis/SumsubVerifier.json';
import VaultFactoryABI from '../abis/VaultFactory.json';
import TokenizedBondVaultABI from '../abis/TokenizedBondVault.json';
import TreasuryFactoryABI from '../abis/TreasuryFactory.json';
import TreasuryVaultABI from '../abis/TreasuryVault.json';
import ContractSignerABI from '../abis/ContractSigner.json';
import PoolRegistryABI from '../abis/PoolRegistry.json';
import PriceFeedManagerABI from '../abis/PriceFeedManager.json';

export {
  ConvexoPassportABI,
  LPIndividualsABI,
  LPBusinessABI,
  EcreditscoringABI,
  ReputationManagerABI,
  VeriffVerifierABI,
  SumsubVerifierABI,
  VaultFactoryABI,
  TokenizedBondVaultABI,
  TreasuryFactoryABI,
  TreasuryVaultABI,
  ContractSignerABI,
  PoolRegistryABI,
  PriceFeedManagerABI,
};
```

---

## IPFS Integration

### Pinata Configuration

```typescript
// config/ipfs.ts
export const PINATA_CONFIG = {
  gateway: 'lime-famous-condor-7.mypinata.cloud',
  apiKey: process.env.PINATA_API_KEY,
  secretKey: process.env.PINATA_SECRET_KEY,
};

export const NFT_IMAGES = {
  convexoPassport: 'bafybeiekwlyujx32cr5u3ixt5esfxhusalt5ljtrmsng74q7k45tilugh4',
  lpBusiness: 'bafkreiejesvgsvohwvv7q5twszrbu5z6dnpke6sg5cdiwgn2rq7dilu33m',
  lpIndividuals: 'bafkreib7mkjzpdm3id6st6d5vsxpn7v5h6sxeiswejjmrbcb5yoagaf4em',
  ecreditscoring: 'bafkreignxas6gqi7it5ng6muoykujxlgxxc4g7rr6sqvwgdfwveqf2zw3e'
};

// Helper function to build IPFS URLs
export const buildIPFSUrl = (hash: string): string => 
  `https://${PINATA_CONFIG.gateway}/ipfs/${hash}`;
```

### Upload NFT Metadata

```typescript
// utils/metadata.ts
import { PINATA_CONFIG, NFT_IMAGES, buildIPFSUrl } from '../config/ipfs';

export interface NFTMetadata {
  name: string;
  description: string;
  image: string;
  external_url: string;
  attributes: Array<{
    trait_type: string;
    value: string;
  }>;
}

export const createPassportMetadata = (tokenId: number, traits: {
  kycVerified: boolean;
  faceMatchPassed: boolean;
  sanctionsPassed: boolean;
  isOver18: boolean;
}): NFTMetadata => ({
  name: `Convexo Passport #${tokenId}`,
  description: "Soulbound NFT representing verified identity for Tier 1 access in the Convexo Protocol. It represents a privacy-compliant verification of identity without storing personal information. This passport enables swap and liquidity provision in gated Uniswap V4 liquidity pools, create OTC and P2P orders and lending options within the vaults created by verified lenders.",
  image: buildIPFSUrl(NFT_IMAGES.convexoPassport),
  external_url: "https://convexo.io",
  attributes: [
    { trait_type: "Tier", value: "1" },
    { trait_type: "Type", value: "Passport" },
    { trait_type: "KYC Verified", value: traits.kycVerified ? "Yes" : "No" },
    { trait_type: "Face Match Passed", value: traits.faceMatchPassed ? "Yes" : "No" },
    { trait_type: "Sanctions Check Passed", value: traits.sanctionsPassed ? "Yes" : "No" },
    { trait_type: "Age Verification", value: traits.isOver18 ? "18+" : "Under 18" },
    { trait_type: "Soulbound", value: "True" },
    { trait_type: "Network Access", value: "LP Pools" },
    { trait_type: "Verification Method", value: "ZKPassport" }
  ]
});

export const uploadMetadataToPinata = async (metadata: NFTMetadata): Promise<string> => {
  const response = await fetch('https://api.pinata.cloud/pinning/pinJSONToIPFS', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'pinata_api_key': PINATA_CONFIG.apiKey!,
      'pinata_secret_api_key': PINATA_CONFIG.secretKey!,
    },
    body: JSON.stringify({
      pinataContent: metadata,
      pinataMetadata: {
        name: `${metadata.name} Metadata`
      }
    })
  });

  const result = await response.json();
  return result.IpfsHash;
};
```

---

## Contract Addresses

Load addresses from `addresses.json` or use this helper:

```typescript
// config/contracts.ts
import addresses from '../addresses.json';

export function getContracts(chainId: number) {
  const chain = addresses[chainId.toString()];
  if (!chain) throw new Error(`Chain ${chainId} not supported`);

  return {
    CONVEXO_PASSPORT: chain.convexo_passport?.address,
    LP_INDIVIDUALS: chain.lp_individuals?.address,
    LP_BUSINESS: chain.lp_business?.address,
    ECREDITSCORING: chain.ecreditscoring?.address,
    REPUTATION_MANAGER: chain.reputation_manager?.address,
    VERIFF_VERIFIER: chain.veriff_verifier?.address,
    SUMSUB_VERIFIER: chain.sumsub_verifier?.address,
    VAULT_FACTORY: chain.vault_factory?.address,
    TREASURY_FACTORY: chain.treasury_factory?.address,
    CONTRACT_SIGNER: chain.contract_signer?.address,
    POOL_REGISTRY: chain.pool_registry?.address,
    PRICE_FEED_MANAGER: chain.price_feed_manager?.address,
    PASSPORT_GATED_HOOK: chain.passport_gated_hook?.address,
  };
}

// Supported chains
export const SUPPORTED_CHAINS = {
  ETHEREUM_MAINNET: 1,
  ETHEREUM_SEPOLIA: 11155111,
  BASE_MAINNET: 8453,
  BASE_SEPOLIA: 84532,
  UNICHAIN_MAINNET: 130,
  UNICHAIN_SEPOLIA: 1301,
};
```

---

## Tier System

### Tier Definitions

| Tier | NFT Required | Verification Method | Access |
|------|--------------|---------------------|--------|
| **0** | None | - | No access |
| **1** | Convexo_Passport | ZKPassport (self-mint) | LP Pools, Vault investments, Treasury |
| **2** | LP_Individuals | Veriff KYC (admin-mint) | Tier 1 + Credit Score request, OTC |
| **2** | LP_Business | Sumsub KYB (admin-mint) | Tier 1 + Credit Score request, OTC |
| **3** | Ecreditscoring | AI Credit Score (backend-mint) | All above + Vault creation |

### TypeScript Types

```typescript
// types/reputation.ts
export enum ReputationTier {
  None = 0,
  Passport = 1,
  LimitedPartner = 2,
  VaultCreator = 3,
}

export interface UserReputation {
  tier: ReputationTier;
  passportBalance: bigint;
  lpIndividualsBalance: bigint;
  lpBusinessBalance: bigint;
  ecreditscoringBalance: bigint;
  canAccessLPPools: boolean;
  canCreateTreasury: boolean;
  canInvestInVaults: boolean;
  canRequestCreditScore: boolean;
  canCreateVaults: boolean;
}

export enum VerificationStatus {
  None = 0,
  Pending = 1,
  Approved = 2,
  Rejected = 3,
  Minted = 4,
}

export enum VaultState {
  Pending = 0,
  Funded = 1,
  Active = 2,
  Repaying = 3,
  Completed = 4,
  Defaulted = 5,
}
```

---

## Contract Functions Reference

### ReputationManager

**Purpose**: Central hub for checking user tiers and permissions.

#### Read Functions

```typescript
// Get user's tier (0-3)
function getReputationTier(address user) returns (ReputationTier)
function getReputationTierNumeric(address user) returns (uint256)

// Permission checks
function canAccessLPPools(address user) returns (bool)      // Tier 1+
function canCreateTreasury(address user) returns (bool)     // Tier 1+
function canInvestInVaults(address user) returns (bool)     // Tier 1+
function canRequestCreditScore(address user) returns (bool) // Tier 2+
function canCreateVaults(address user) returns (bool)       // Tier 3 only

// NFT balance checks
function holdsPassport(address user) returns (bool)
function holdsLPIndividuals(address user) returns (bool)
function holdsLPBusiness(address user) returns (bool)
function holdsAnyLP(address user) returns (bool)
function holdsEcreditscoring(address user) returns (bool)

// Detailed info (returns all balances + tier)
function getReputationDetails(address user) returns (
    ReputationTier tier,
    uint256 passportBalance,
    uint256 lpIndividualsBalance,
    uint256 lpBusinessBalance,
    uint256 ecreditscoringBalance
)
```

---

### Convexo_Passport (Tier 1 NFT)

**Purpose**: Soulbound NFT for ZKPassport-verified individuals.

#### Write Functions

```typescript
// Self-mint with ZKPassport proof (on-chain verification)
// Self-mint with verification results (simplified)
function safeMintWithVerification(
    bytes32 uniqueIdentifier,     // Unique ID from ZKPassport
    bytes32 personhoodProof,      // Personhood proof from ZKPassport
    bool sanctionsPassed,         // Sanctions check result
    bool isOver18,                // Age verification result
    bool faceMatchPassed          // Private face match result
) returns (uint256 tokenId)

// Revoke passport (REVOKER_ROLE required)
function revokePassport(uint256 tokenId)
```

#### Read Functions

```typescript
function holdsActivePassport(address holder) returns (bool)
function getVerifiedIdentity(address holder) returns (VerifiedIdentity memory)
function isIdentifierUsed(bytes32 uniqueIdentifier) returns (bool)
function getActivePassportCount() returns (uint256)
function balanceOf(address owner) returns (uint256)
function ownerOf(uint256 tokenId) returns (address)
```

#### VerifiedIdentity Struct

```typescript
struct VerifiedIdentity {
    bytes32 uniqueIdentifier;
    bytes32 personhoodProof;
    uint256 verifiedAt;
    uint256 zkPassportTimestamp;
    bool isActive;
    bool kycVerified;      // Public trait
    bool faceMatchPassed;  // Public trait
    bool sanctionsPassed;  // Public trait
    bool isOver18;         // Public trait
}
```

---

### VeriffVerifier (Individual KYC Registry)

**Purpose**: Privacy-enhanced KYC verification for individuals. Admin-only data access.

#### Verification Status

```typescript
enum VerificationStatus {
    None,      // 0 - No submission
    Pending,   // 1 - Awaiting admin review
    Approved,  // 2 - Approved, NFT not yet minted
    Rejected,  // 3 - Rejected
    Minted     // 4 - Approved and NFT minted
}
```

#### Write Functions (VERIFIER_ROLE required)

```typescript
// Backend calls after Veriff webhook
function submitVerification(
    address user,
    string calldata sessionId
)

// Admin approves (status → Approved, NO auto-mint)
function approveVerification(address user)

// Admin rejects with reason
function rejectVerification(
    address user,
    string calldata reason
)

// Reset rejected verification (DEFAULT_ADMIN_ROLE)
function resetVerification(address user)

// Called by NFT contract after minting (MINTER_CALLBACK_ROLE)
function markAsMinted(address user, uint256 tokenId)
```

#### Read Functions (Public - No sensitive data)

```typescript
function hasVerificationRecord(address user) returns (bool)
function getStatus(address user) returns (VerificationStatus)
function isApproved(address user) returns (bool)
function isMinted(address user) returns (bool)
function isVerified(address user) returns (bool) // Approved OR Minted
```

#### Read Functions (VERIFIER_ROLE only - Private data)

```typescript
function getVerificationRecord(address user) returns (VerificationRecord memory)
function getSessionId(address user) returns (string memory)
function isSessionIdUsed(string calldata sessionId) returns (bool)
function getUserBySessionId(string calldata sessionId) returns (address)
```

#### Role Management

```typescript
function addVerifier(address account)    // DEFAULT_ADMIN_ROLE
function removeVerifier(address account) // DEFAULT_ADMIN_ROLE
function isVerifier(address account) returns (bool)
function addAdmin(address account)       // DEFAULT_ADMIN_ROLE
function removeAdmin(address account)    // DEFAULT_ADMIN_ROLE
function isAdmin(address account) returns (bool)
```

---

### SumsubVerifier (Business KYB Registry)

**Purpose**: Privacy-enhanced KYB verification for businesses. Admin-only data access.

#### Business Types

```typescript
enum BusinessType {
    Corporation,
    LLC,
    Partnership,
    SoleProprietor,
    Other
}
```

#### Write Functions (VERIFIER_ROLE required)

```typescript
// Backend calls after Sumsub webhook
function submitVerification(
    address user,
    string calldata applicantId,
    string calldata companyName,
    string calldata registrationNumber,
    string calldata jurisdiction,
    BusinessType businessType
)

// Admin approves (status → Approved, NO auto-mint)
function approveVerification(address user)

// Admin rejects with reason
function rejectVerification(
    address user,
    string calldata reason
)

// Reset rejected verification (DEFAULT_ADMIN_ROLE)
function resetVerification(address user)

// Called by NFT contract after minting (MINTER_CALLBACK_ROLE)
function markAsMinted(address user, uint256 tokenId)
```

#### Read Functions (Public - No sensitive data)

```typescript
function hasVerificationRecord(address user) returns (bool)
function getStatus(address user) returns (VerificationStatus)
function isApproved(address user) returns (bool)
function isMinted(address user) returns (bool)
function isVerified(address user) returns (bool)
```

#### Read Functions (VERIFIER_ROLE only - Private data)

```typescript
function getVerificationRecord(address user) returns (VerificationRecord memory)
function getCompanyDetails(address user) returns (
    string memory companyName,
    string memory registrationNumber,
    string memory jurisdiction,
    BusinessType businessType
)
function isApplicantIdUsed(string calldata applicantId) returns (bool)
function isRegistrationUsed(string calldata registrationNumber) returns (bool)
function getUserByApplicantId(string calldata applicantId) returns (address)
function getUserByRegistration(string calldata registrationNumber) returns (address)
```

---

### Limited_Partners_Individuals (Tier 2 NFT)

**Purpose**: Soulbound NFT for verified individual LPs.

#### Write Functions (MINTER_ROLE required)

```typescript
// Mint NFT (auto-calls verifier.markAsMinted)
function safeMint(
    address to,
    string memory verificationId,
    string memory uri
) returns (uint256 tokenId)

// Set token active/inactive (DEFAULT_ADMIN_ROLE)
function setTokenState(uint256 tokenId, bool isActive)

// Burn token (owner only)
function burn(uint256 tokenId)
```

#### Read Functions

```typescript
function balanceOf(address owner) returns (uint256)
function ownerOf(uint256 tokenId) returns (address)
function getTokenState(uint256 tokenId) returns (bool)
function getVerificationId(uint256 tokenId) returns (string memory) // Admin only
function verifierContract() returns (address) // Immutable
```

---

### Limited_Partners_Business (Tier 2 NFT)

**Purpose**: Soulbound NFT for verified business LPs.

#### Write Functions (MINTER_ROLE required)

```typescript
// Mint NFT (auto-calls verifier.markAsMinted)
function safeMint(
    address to,
    string memory companyName,
    string memory registrationNumber,
    string memory jurisdiction,
    BusinessType businessType,
    string memory sumsubApplicantId,
    string memory uri
) returns (uint256 tokenId)

// Set token active/inactive (DEFAULT_ADMIN_ROLE)
function setTokenState(uint256 tokenId, bool isActive)

// Burn token (owner only)
function burn(uint256 tokenId)
```

#### Read Functions

```typescript
function balanceOf(address owner) returns (uint256)
function ownerOf(uint256 tokenId) returns (address)
function getTokenState(uint256 tokenId) returns (bool)
function getCompanyName(uint256 tokenId) returns (string memory) // Public
function getBusinessInfo(uint256 tokenId) returns (BusinessInfo memory) // Admin only
function verifierContract() returns (address) // Immutable
```

---

### Ecreditscoring (Tier 3 NFT)

**Purpose**: Soulbound NFT for credit-scored vault creators.

#### Write Functions (MINTER_ROLE required)

```typescript
// Mint NFT (requires LP NFT)
function safeMint(
    address to,
    uint256 creditScore,      // 0-100
    string memory riskLevel,  // "Low", "Medium", "High"
    string memory uri
) returns (uint256 tokenId)

// Update credit info (MINTER_ROLE)
function updateCreditInfo(
    uint256 tokenId,
    uint256 newCreditScore,
    string memory newRiskLevel
)

// Burn token (owner only)
function burn(uint256 tokenId)
```

#### Read Functions

```typescript
function balanceOf(address owner) returns (uint256)
function ownerOf(uint256 tokenId) returns (address)
function getCreditInfo(uint256 tokenId) returns (
    uint256 creditScore,
    string memory riskLevel,
    uint256 lastUpdated
)
function hasLPStatus(address user) returns (bool) // Has LP Individual or Business
function canReceiveEcreditscoringNFT(address user) returns (bool)
```

---

### VaultFactory

**Purpose**: Create tokenized bond vaults. Requires Tier 3.

#### Write Functions

```typescript
// Create new vault (Tier 3 required)
function createVault(
    uint256 principalAmount,  // USDC amount (6 decimals)
    uint256 interestRate,     // Basis points (1200 = 12%)
    uint256 protocolFeeRate,  // Basis points (200 = 2%)
    uint256 maturityDate,     // Unix timestamp
    string memory name,       // Vault token name
    string memory symbol      // Vault token symbol
) returns (uint256 vaultId, address vaultAddress)
```

#### Read Functions

```typescript
function getVault(uint256 vaultId) returns (address)
function getVaultCount() returns (uint256)
function getVaultAddressAtIndex(uint256 index) returns (address)
function getAllVaults() returns (address[] memory)
```

---

### TokenizedBondVault

**Purpose**: Individual vault for tokenized bonds.

#### Vault States

```typescript
enum VaultState {
    Pending,    // 0 - Accepting investments
    Funded,     // 1 - Fully funded
    Active,     // 2 - Contract signed, funds withdrawn
    Repaying,   // 3 - Making repayments
    Completed,  // 4 - Fully repaid
    Defaulted   // 5 - Failed to repay
}
```

#### Write Functions (Investor - Tier 1+ required)

```typescript
// Purchase shares with USDC
function purchaseShares(uint256 amount)

// Redeem shares after repayment
function redeemShares(uint256 shares)
```

#### Write Functions (Borrower)

```typescript
// Withdraw funds after contract signed
function withdrawFunds()

// Make repayment
function makeRepayment(uint256 amount)
```

#### Write Functions (Admin)

```typescript
function attachContract(bytes32 contractHash) // VAULT_MANAGER_ROLE
function markAsDefaulted()                     // VAULT_MANAGER_ROLE
function withdrawProtocolFees()                // Protocol collector
```

#### Read Functions

```typescript
function getVaultState() returns (VaultState)

function getVaultMetrics() returns (
    uint256 totalShares,
    uint256 sharePrice,
    uint256 totalValueLocked,
    uint256 targetAmount,
    uint256 fundingProgress,  // Percentage * 100
    uint256 currentAPY        // Basis points
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
function getInvestors() returns (address[] memory)
function balanceOf(address account) returns (uint256) // ERC20 shares
```

---

### TreasuryFactory

**Purpose**: Create personal treasuries. Requires Tier 1+.

#### Write Functions

```typescript
// Create treasury (Tier 1+ required)
function createTreasury(
    address[] memory signers,      // Empty for single-sig
    uint256 signaturesRequired     // 0 for single-sig
) returns (uint256 treasuryId, address treasuryAddress)
```

#### Read Functions

```typescript
function getTreasury(uint256 treasuryId) returns (address)
function getTreasuryCount() returns (uint256)
function getTreasuriesByOwner(address owner) returns (uint256[] memory)
function getTreasuryCountByOwner(address owner) returns (uint256)
```

---

### TreasuryVault

**Purpose**: Multi-sig USDC treasury.

#### Write Functions

```typescript
// Deposit USDC
function deposit(uint256 amount)

// Propose withdrawal (owner or signer)
function proposeWithdrawal(
    address recipient,
    uint256 amount,
    string calldata reason
) returns (uint256 proposalId)

// Approve withdrawal (signer only, multi-sig)
function approveWithdrawal(uint256 proposalId)

// Execute approved withdrawal
function executeWithdrawal(uint256 proposalId)
```

#### Read Functions

```typescript
function getBalance() returns (uint256)
function getProposal(uint256 proposalId) returns (Proposal memory)
function owner() returns (address)
function signers(uint256 index) returns (address)
function signaturesRequired() returns (uint256)
```

---

### ContractSigner

**Purpose**: On-chain multi-party contract signing.

#### Agreement Types

```typescript
enum AgreementType {
    LoanAgreement,
    InvestmentContract,
    ServiceAgreement,
    Other
}
```

#### Write Functions

```typescript
// Create contract (anyone)
function createContract(
    bytes32 documentHash,
    AgreementType agreementType,
    address[] calldata requiredSigners,
    string calldata ipfsHash,
    uint256 nftReputationTier,  // Min tier required
    uint256 expiryDuration      // Seconds until expiry
)

// Sign contract
function signContract(
    bytes32 documentHash,
    bytes calldata signature
)

// Execute contract and attach to vault
function executeContract(
    bytes32 documentHash,
    uint256 vaultId
)
```

#### Read Functions

```typescript
function getContract(bytes32 documentHash) returns (ContractDocument memory)
function isFullySigned(bytes32 documentHash) returns (bool)
function isContractSigned(bytes32 documentHash, address signer) returns (bool)
function getContractsByUser(address user) returns (bytes32[] memory)
```

---

## React Hooks

### useUserReputation

```typescript
// hooks/useUserReputation.ts
import { useReadContracts } from 'wagmi';
import { getContracts } from '../config/contracts';
import { ReputationManagerABI } from '../config/abis';

export function useUserReputation(address: `0x${string}` | undefined, chainId: number) {
  const contracts = getContracts(chainId);

  const { data, isLoading, error, refetch } = useReadContracts({
    contracts: address ? [
      {
        address: contracts.REPUTATION_MANAGER as `0x${string}`,
        abi: ReputationManagerABI,
        functionName: 'getReputationDetails',
        args: [address],
      },
      {
        address: contracts.REPUTATION_MANAGER as `0x${string}`,
        abi: ReputationManagerABI,
        functionName: 'canAccessLPPools',
        args: [address],
      },
      {
        address: contracts.REPUTATION_MANAGER as `0x${string}`,
        abi: ReputationManagerABI,
        functionName: 'canCreateTreasury',
        args: [address],
      },
      {
        address: contracts.REPUTATION_MANAGER as `0x${string}`,
        abi: ReputationManagerABI,
        functionName: 'canInvestInVaults',
        args: [address],
      },
      {
        address: contracts.REPUTATION_MANAGER as `0x${string}`,
        abi: ReputationManagerABI,
        functionName: 'canRequestCreditScore',
        args: [address],
      },
      {
        address: contracts.REPUTATION_MANAGER as `0x${string}`,
        abi: ReputationManagerABI,
        functionName: 'canCreateVaults',
        args: [address],
      },
    ] : [],
  });

  const reputation = data ? {
    tier: Number(data[0].result?.[0]),
    passportBalance: data[0].result?.[1] ?? 0n,
    lpIndividualsBalance: data[0].result?.[2] ?? 0n,
    lpBusinessBalance: data[0].result?.[3] ?? 0n,
    ecreditscoringBalance: data[0].result?.[4] ?? 0n,
    canAccessLPPools: data[1].result ?? false,
    canCreateTreasury: data[2].result ?? false,
    canInvestInVaults: data[3].result ?? false,
    canRequestCreditScore: data[4].result ?? false,
    canCreateVaults: data[5].result ?? false,
  } : null;

  return { reputation, isLoading, error, refetch };
}
```

### useVerificationStatus

```typescript
// hooks/useVerificationStatus.ts
import { useReadContracts } from 'wagmi';
import { getContracts } from '../config/contracts';
import { VeriffVerifierABI, SumsubVerifierABI } from '../config/abis';

export function useVerificationStatus(address: `0x${string}` | undefined, chainId: number) {
  const contracts = getContracts(chainId);

  const { data, isLoading, refetch } = useReadContracts({
    contracts: address ? [
      // Veriff (Individual)
      {
        address: contracts.VERIFF_VERIFIER as `0x${string}`,
        abi: VeriffVerifierABI,
        functionName: 'hasVerificationRecord',
        args: [address],
      },
      {
        address: contracts.VERIFF_VERIFIER as `0x${string}`,
        abi: VeriffVerifierABI,
        functionName: 'getStatus',
        args: [address],
      },
      // Sumsub (Business)
      {
        address: contracts.SUMSUB_VERIFIER as `0x${string}`,
        abi: SumsubVerifierABI,
        functionName: 'hasVerificationRecord',
        args: [address],
      },
      {
        address: contracts.SUMSUB_VERIFIER as `0x${string}`,
        abi: SumsubVerifierABI,
        functionName: 'getStatus',
        args: [address],
      },
    ] : [],
  });

  return {
    veriff: {
      hasRecord: data?.[0].result ?? false,
      status: Number(data?.[1].result ?? 0),
    },
    sumsub: {
      hasRecord: data?.[2].result ?? false,
      status: Number(data?.[3].result ?? 0),
    },
    isLoading,
    refetch,
  };
}
```

### useMintPassport

```typescript
// hooks/useMintPassport.ts
import { useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { keccak256, toBytes } from 'viem';
import { ConvexoPassportABI } from '../config/abis';
import { getContracts } from '../config/contracts';

export function useMintPassport(chainId: number) {
  const contracts = getContracts(chainId);

  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const mintWithZKPassport = async (params: ProofVerificationParams, isIDCard: boolean) => {
    await writeContract({
      address: contracts.CONVEXO_PASSPORT as `0x${string}`,
      abi: ConvexoPassportABI,
      functionName: 'safeMintWithZKPassport',
      args: [params, isIDCard],
    });
  };

  const generateIdentifier = (publicKey: string, scope: string): `0x${string}` => {
    const combined = publicKey + scope.replace('0x', '');
    return keccak256(toBytes(combined));
  };Verification,
    createVerificationResults
  return {
    mintWithZKPassport,
    generateIdentifier,
    hash,
    isPending,
    isConfirming,
    isSuccess,
    error,
  };
}
```

### useInvestInVault

```typescript
// hooks/useInvestInVault.ts
import { useWriteContract, useWaitForTransactionReceipt, useReadContract } from 'wagmi';
import { parseUnits } from 'viem';
import { TokenizedBondVaultABI } from '../config/abis';
import { getContracts } from '../config/contracts';

const ERC20_ABI = [
  {
    name: 'approve',
    type: 'function',
    inputs: [
      { name: 'spender', type: 'address' },
      { name: 'amount', type: 'uint256' },
    ],
    outputs: [{ type: 'bool' }],
  },
  {
    name: 'allowance',
    type: 'function',
    inputs: [
      { name: 'owner', type: 'address' },
      { name: 'spender', type: 'address' },
    ],
    outputs: [{ type: 'uint256' }],
  },
] as const;

export function useInvestInVault(
  vaultAddress: `0x${string}`,
  userAddress: `0x${string}` | undefined,
  chainId: number
) {
  const contracts = getContracts(chainId);

  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const { data: allowance, refetch: refetchAllowance } = useReadContract({
    address: contracts.USDC as `0x${string}`,
    abi: ERC20_ABI,
    functionName: 'allowance',
    args: userAddress ? [userAddress, vaultAddress] : undefined,
    query: { enabled: !!userAddress },
  });

  const approve = async (amount: string) => {
    await writeContract({
      address: contracts.USDC as `0x${string}`,
      abi: ERC20_ABI,
      functionName: 'approve',
      args: [vaultAddress, parseUnits(amount, 6)],
    });
  };

  const invest = async (amount: string) => {
    await writeContract({
      address: vaultAddress,
      abi: TokenizedBondVaultABI,
      functionName: 'purchaseShares',
      args: [parseUnits(amount, 6)],
    });
  };

  return {
    approve,
    invest,
    allowance,
    refetchAllowance,
    hash,
    isPending,
    isConfirming,
    isSuccess,
    error,
  };
}
```

### useCreateVault

```typescript
// hooks/useCreateVault.ts
import { useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { parseUnits } from 'viem';
import { VaultFactoryABI } from '../config/abis';
import { getContracts } from '../config/contracts';

interface CreateVaultParams {
  principalAmount: string;
  interestRate: number;
  protocolFeeRate: number;
  maturityDays: number;
  name: string;
  symbol: string;
}

export function useCreateVault(chainId: number) {
  const contracts = getContracts(chainId);

  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess, data: receipt } = useWaitForTransactionReceipt({ hash });

  const createVault = async (params: CreateVaultParams) => {
    const principalAmount = parseUnits(params.principalAmount, 6);
    const maturityDate = BigInt(Math.floor(Date.now() / 1000) + params.maturityDays * 86400);

    await writeContract({
      address: contracts.VAULT_FACTORY as `0x${string}`,
      abi: VaultFactoryABI,
      functionName: 'createVault',
      args: [
        principalAmount,
        BigInt(params.interestRate),
        BigInt(params.protocolFeeRate),
        maturityDate,
        params.name,
        params.symbol,
      ],
    });
  };

  return {
    createVault,
    hash,
    isPending,
    isConfirming,
    isSuccess,
    receipt,
    error,
  };
}
```

### useCreateTreasury

```typescript
// hooks/useCreateTreasury.ts
import { useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { TreasuryFactoryABI } from '../config/abis';
import { getContracts } from '../config/contracts';

export function useCreateTreasury(chainId: number) {
  const contracts = getContracts(chainId);

  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess, data: receipt } = useWaitForTransactionReceipt({ hash });

  const createTreasury = async (signers: `0x${string}`[] = [], signaturesRequired = 0) => {
    await writeContract({
      address: contracts.TREASURY_FACTORY as `0x${string}`,
      abi: TreasuryFactoryABI,
      functionName: 'createTreasury',
      args: [signers, BigInt(signaturesRequired)],
    });
  };

  return {
    createTreasury,
    hash,
    isPending,
    isConfirming,
    isSuccess,
    receipt,
    error,
  };
}
```

---

## Complete Examples

### User Dashboard

```tsx
// components/Dashboard.tsx
import { useAccount, useChainId } from 'wagmi';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useUserReputation } from '../hooks/useUserReputation';
import { useVerificationStatus } from '../hooks/useVerificationStatus';

const TIER_NAMES = ['Unverified', 'Passport Holder', 'Limited Partner', 'Vault Creator'];
const STATUS_NAMES = ['None', 'Pending', 'Approved', 'Rejected', 'Minted'];

export function Dashboard() {
  const { address, isConnected } = useAccount();
  const chainId = useChainId();
  const { reputation, isLoading } = useUserReputation(address, chainId);
  const { veriff, sumsub } = useVerificationStatus(address, chainId);

  if (!isConnected) {
    return (
      <div className="text-center p-8">
        <h1 className="text-2xl font-bold mb-4">Welcome to Convexo</h1>
        <ConnectButton />
      </div>
    );
  }

  if (isLoading) {
    return <div className="p-8">Loading...</div>;
  }

  return (
    <div className="p-8 space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold">Dashboard</h1>
        <ConnectButton />
      </div>

      {/* Tier Badge */}
      <div className="p-6 bg-white rounded-lg shadow">
        <h2 className="text-lg font-semibold mb-2">Your Status</h2>
        <div className="text-3xl font-bold text-blue-600">
          Tier {reputation?.tier}: {TIER_NAMES[reputation?.tier ?? 0]}
        </div>
      </div>

      {/* Permissions */}
      <div className="p-6 bg-white rounded-lg shadow">
        <h2 className="text-lg font-semibold mb-4">Permissions</h2>
        <div className="grid grid-cols-2 gap-3">
          <PermissionItem label="LP Pools" enabled={reputation?.canAccessLPPools} />
          <PermissionItem label="Create Treasury" enabled={reputation?.canCreateTreasury} />
          <PermissionItem label="Invest in Vaults" enabled={reputation?.canInvestInVaults} />
          <PermissionItem label="Request Credit Score" enabled={reputation?.canRequestCreditScore} />
          <PermissionItem label="Create Vaults" enabled={reputation?.canCreateVaults} />
        </div>
      </div>

      {/* Verification Status */}
      <div className="p-6 bg-white rounded-lg shadow">
        <h2 className="text-lg font-semibold mb-4">Verification Status</h2>
        <div className="space-y-2">
          <div>Veriff (Individual): {STATUS_NAMES[veriff.status]}</div>
          <div>Sumsub (Business): {STATUS_NAMES[sumsub.status]}</div>
        </div>
      </div>
    </div>
  );
}

function PermissionItem({ label, enabled }: { label: string; enabled?: boolean }) {
  return (
    <div className={`p-3 rounded ${enabled ? 'bg-green-100' : 'bg-gray-100'}`}>
      {enabled ? '✅' : '❌'} {label}
    </div>
  );
}
```

### Vault Investment Card

```tsx
// components/VaultCard.tsx
import { useState } from 'react';
import { useAccount, useChainId } from 'wagmi';
import { formatUnits } from 'viem';
import { useReadContracts } from 'wagmi';
import { TokenizedBondVaultABI } from '../config/abis';
import { useInvestInVault } from '../hooks/useInvestInVault';
import { useUserReputation } from '../hooks/useUserReputation';

interface VaultCardProps {
  vaultAddress: `0x${string}`;
}

export function VaultCard({ vaultAddress }: VaultCardProps) {
  const { address } = useAccount();
  const chainId = useChainId();
  const { reputation } = useUserReputation(address, chainId);
  const { approve, invest, isPending, isConfirming, isSuccess } = useInvestInVault(
    vaultAddress,
    address,
    chainId
  );

  const [amount, setAmount] = useState('');

  const { data } = useReadContracts({
    contracts: [
      {
        address: vaultAddress,
        abi: TokenizedBondVaultABI,
        functionName: 'getVaultMetrics',
      },
      {
        address: vaultAddress,
        abi: TokenizedBondVaultABI,
        functionName: 'getVaultState',
      },
    ],
  });

  const metrics = data?.[0].result;
  const state = data?.[1].result;

  const canInvest = reputation?.canInvestInVaults && state === 0;

  return (
    <div className="p-6 bg-white rounded-lg shadow">
      <h3 className="text-lg font-bold mb-4">Vault</h3>

      {metrics && (
        <div className="grid grid-cols-2 gap-4 mb-4">
          <div>
            <div className="text-sm text-gray-500">Target</div>
            <div className="font-bold">${formatUnits(metrics[3], 6)}</div>
          </div>
          <div>
            <div className="text-sm text-gray-500">APY</div>
            <div className="font-bold text-green-600">{Number(metrics[5]) / 100}%</div>
          </div>
          <div>
            <div className="text-sm text-gray-500">Progress</div>
            <div className="font-bold">{Number(metrics[4]) / 100}%</div>
          </div>
        </div>
      )}

      {canInvest && (
        <div className="space-y-3">
          <input
            type="number"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            placeholder="USDC amount"
            className="w-full px-4 py-2 border rounded"
          />
          <div className="flex gap-2">
            <button
              onClick={() => approve(amount)}
              disabled={!amount || isPending}
              className="flex-1 px-4 py-2 bg-gray-200 rounded hover:bg-gray-300 disabled:opacity-50"
            >
              Approve
            </button>
            <button
              onClick={() => invest(amount)}
              disabled={!amount || isPending}
              className="flex-1 px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50"
            >
              {isPending ? 'Processing...' : 'Invest'}
            </button>
          </div>
        </div>
      )}

      {isSuccess && (
        <div className="mt-4 p-3 bg-green-100 text-green-800 rounded">
          Investment successful!
        </div>
      )}
    </div>
  );
}
```

---

## Verification Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│  TIER 1: PASSPORT (Self-Mint via ZKPassport)                    │
│  ─────────────────────────────────────────                      │
│  User → ZKPassport Verify → safeMintWithVerification() → NFT       │
│  Access: LP Pools, Vault Investments, Treasury Creation         │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  TIER 2: LIMITED PARTNER (Admin-Mint via Verifier)              │
│  ──────────────────────────────────────────────────             │
│  INDIVIDUAL PATH:                                                │
│  User → Veriff KYC → Backend → submitVerification()             │
│  Admin → approveVerification() → safeMint() → NFT               │
│  (NFT auto-calls verifier.markAsMinted())                       │
│                                                                  │
│  BUSINESS PATH:                                                  │
│  User → Sumsub KYB → Backend → submitVerification()             │
│  Admin → approveVerification() → safeMint() → NFT               │
│  (NFT auto-calls verifier.markAsMinted())                       │
│                                                                  │
│  Access: Tier 1 + Credit Score Request, OTC Orders              │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  TIER 3: VAULT CREATOR (Backend-Mint via AI Score)              │
│  ─────────────────────────────────────────────────              │
│  User (with LP NFT) → AI Credit Analysis → Backend → safeMint() │
│  Access: All above + Vault Creation                              │
└─────────────────────────────────────────────────────────────────┘
```

---

## Access Control Summary

| Feature | Required Tier | Contract | Function |
|---------|---------------|----------|----------|
| Uniswap V4 LP Swaps | 1+ | PassportGatedHook | (automatic) |
| Create Treasury | 1+ | TreasuryFactory | `createTreasury()` |
| Invest in Vaults | 1+ | TokenizedBondVault | `purchaseShares()` |
| Request Credit Score | 2+ | Backend | (API call) |
| OTC Orders | 2+ | (OTC contracts) | - |
| Create Vault | 3 | VaultFactory | `createVault()` |

---

*Version 3.0 | Updated January 2026*

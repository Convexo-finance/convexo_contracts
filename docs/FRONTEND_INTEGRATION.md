# Frontend Integration Guide

**Version 3.17** · Solidity ^0.8.27 · React + Viem + Wagmi
**IPFS Gateway:** `lime-famous-condor-7.mypinata.cloud`
**Addresses:** always load from `addresses.json` via `getContracts(chainId)`

---

## Table of Contents

1. [Setup](#setup)
2. [Contract Addresses](#contract-addresses)
3. [Tier System](#tier-system)
4. [ZKPassport Verification (Tier 1)](#zkpassport-verification-tier-1)
5. [IPFS / Pinata](#ipfs--pinata)
6. [Contract Functions Reference](#contract-functions-reference)
7. [React Hooks](#react-hooks)
8. [UI Examples](#ui-examples)
9. [Access Control Summary](#access-control-summary)

---

## Setup

```bash
npm install viem wagmi @rainbow-me/rainbowkit @tanstack/react-query @zkpassport/sdk
```

```typescript
// config/abis.ts
import ConvexoPassportABI    from '../abis/Convexo_Passport.json';
import LPIndividualsABI      from '../abis/Limited_Partners_Individuals.json';
import LPBusinessABI         from '../abis/Limited_Partners_Business.json';
import EcreditscoringABI     from '../abis/Ecreditscoring.json';
import ReputationManagerABI  from '../abis/ReputationManager.json';
import VeriffVerifierABI     from '../abis/VeriffVerifier.json';
import SumsubVerifierABI     from '../abis/SumsubVerifier.json';
import VaultFactoryABI       from '../abis/VaultFactory.json';
import TokenizedBondVaultABI from '../abis/TokenizedBondVault.json';
import ContractSignerABI     from '../abis/ContractSigner.json';
import PoolRegistryABI       from '../abis/PoolRegistry.json';
import PriceFeedManagerABI   from '../abis/PriceFeedManager.json';

export {
  ConvexoPassportABI, LPIndividualsABI, LPBusinessABI, EcreditscoringABI,
  ReputationManagerABI, VeriffVerifierABI, SumsubVerifierABI,
  VaultFactoryABI, TokenizedBondVaultABI, ContractSignerABI,
  PoolRegistryABI, PriceFeedManagerABI,
};
```

---

## Contract Addresses

```typescript
// config/contracts.ts
import addresses from '../addresses.json';

export function getContracts(chainId: number) {
  const chain = addresses[chainId.toString()];
  if (!chain) throw new Error(`Chain ${chainId} not supported`);
  return {
    CONVEXO_PASSPORT:    chain.contracts.convexo_passport?.address,
    LP_INDIVIDUALS:      chain.contracts.lp_individuals?.address,
    LP_BUSINESS:         chain.contracts.lp_business?.address,
    ECREDITSCORING:      chain.contracts.ecreditscoring?.address,
    REPUTATION_MANAGER:  chain.contracts.reputation_manager?.address,
    VERIFF_VERIFIER:     chain.contracts.veriff_verifier?.address,
    SUMSUB_VERIFIER:     chain.contracts.sumsub_verifier?.address,
    VAULT_FACTORY:       chain.contracts.vault_factory?.address,
    CONTRACT_SIGNER:     chain.contracts.contract_signer?.address,
    POOL_REGISTRY:       chain.contracts.pool_registry?.address,
    PRICE_FEED_MANAGER:  chain.contracts.price_feed_manager?.address,
    PASSPORT_GATED_HOOK: chain.contracts.passport_gated_hook?.address,
    USDC:                chain.external?.usdc,
  };
}

export const SUPPORTED_CHAINS = {
  ETHEREUM_MAINNET:  1,
  BASE_MAINNET:      8453,
  UNICHAIN_MAINNET:  130,
  ARBITRUM_ONE:      42161,
  ETHEREUM_SEPOLIA:  11155111,
  BASE_SEPOLIA:      84532,
  UNICHAIN_SEPOLIA:  1301,
  ARBITRUM_SEPOLIA:  421614,
};
```

---

## Tier System

| Tier | NFT | Verification | Access |
|------|-----|--------------|--------|
| **0** | None | — | No access |
| **1** | Convexo_Passport | ZKPassport (self-mint) | LP pool swaps + vault investments |
| **2** | LP_Individuals | Veriff KYC (admin-mint) | Tier 1 + credit score + OTC |
| **2** | LP_Business | Sumsub KYB (admin-mint) | Tier 1 + credit score + OTC |
| **3** | Ecreditscoring | AI credit score (backend-mint) | All above + vault creation |

```typescript
// types/reputation.ts
export enum ReputationTier { None = 0, Passport = 1, LimitedPartner = 2, VaultCreator = 3 }
export enum VerificationStatus { None = 0, Pending = 1, Approved = 2, Rejected = 3, Minted = 4 }
export enum VaultState { Pending = 0, Funded = 1, Active = 2, Repaying = 3, Completed = 4, Defaulted = 5 }
```

---

## ZKPassport Verification (Tier 1)

### Flow

```
1. User opens ZKPassport mobile app → scans passport
2. Frontend creates verification request (domain + scope must match contract constants)
3. SDK generates ZK proof on device
4. Frontend captures ProofVerificationParams via SDK getSolidityVerifierParameters()
5. Frontend uploads NFT metadata to Pinata → gets ipfsHash
6. User calls claimPassport(proof, isIDCard, ipfsHash) — proof verified on-chain
7. Contract verifies: scope → sender → chain → age → sanctions → nationality → expiry → sybil
8. NFT minted → user has Tier 1
```

**IMPORTANT:**
- `claimPassport` is self-called by the user — no admin/minter role involved
- Proof is bound to `msg.sender` and `block.chainid` — cannot be replayed by another wallet or chain
- ZKPassport verifier only deployed on: **Ethereum**, **Ethereum Sepolia**, **Base**, **Base Sepolia**
- On Unichain/Arbitrum: use LP_Individuals/LP_Business for pool access (no ZKPassport)

### SDK Setup

```typescript
// lib/zkpassport.ts
import { ZKPassport } from '@zkpassport/sdk';

// APP_DOMAIN and APP_SCOPE must match contract constants EXACTLY
export const APP_DOMAIN = 'protocol.convexo.xyz';
export const APP_SCOPE = 'convexo-passport-identity';

export const zkPassport = new ZKPassport(APP_DOMAIN);

export async function createVerificationRequest(walletAddress: string, chainId: number) {
  const queryBuilder = await zkPassport.request({
    name: 'Convexo Identity Verification',
    logo: 'https://protocol.convexo.xyz/logo.png',
    purpose: 'Verify identity for Convexo Passport NFT',
    scope: APP_SCOPE,
    mode: 'compressed-evm',  // required for on-chain verification
  });

  return queryBuilder
    .gte('age', 18)      // age18.md — no birthdate stored
    .sanctions()         // kyc.md — US/UK/EU/CH lists
    .bind('user_address', walletAddress)  // anti-replay: binds to msg.sender
    .bind('chain', chainId)               // anti-replay: binds to chainId
    .done();
}
```

### Capture Proof Parameters

```typescript
// types/zkpassport.ts
export interface PassportProofResult {
  proof: any;           // ProofVerificationParams (opaque, passed directly to contract)
  isIDCard: boolean;    // true = ID card, false = passport
}

export async function getProofFromSDK(zkPassport: ZKPassport): Promise<PassportProofResult> {
  return new Promise((resolve, reject) => {
    zkPassport.onProofGenerated(async ({ proof, isIDCard }) => {
      try {
        // Get the Solidity-ready params — pass directly to claimPassport()
        const proofParams = await proof.getSolidityVerifierParameters();
        resolve({ proof: proofParams, isIDCard: isIDCard ?? false });
      } catch (err) {
        reject(err);
      }
    });
    zkPassport.onError(reject);
  });
}
```

### useClaimPassport Hook

```typescript
// hooks/useClaimPassport.ts
import { useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { ConvexoPassportABI } from '../config/abis';
import { getContracts } from '../config/contracts';

export function useClaimPassport(chainId: number) {
  const contracts = getContracts(chainId);
  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const claimPassport = (
    proof: any,             // ProofVerificationParams from getSolidityVerifierParameters()
    isIDCard: boolean,      // false=passport, true=ID card
    ipfsMetadataHash: string
  ) => writeContract({
    address: contracts.CONVEXO_PASSPORT as `0x${string}`,
    abi: ConvexoPassportABI,
    functionName: 'claimPassport',
    args: [proof, isIDCard, ipfsMetadataHash],
  });

  return { claimPassport, hash, isPending, isConfirming, isSuccess, error };
}
```

### Pre-Claim Checks

```typescript
// Before calling claimPassport, always check:
// 1. holdsActivePassport(address) → revert: AlreadyHasPassport
// 2. isIdentifierUsed(bytes32) → revert: IdentifierAlreadyUsed
//    (uniqueIdentifier is returned as bytes32 from IZKPassportVerifier — cannot be checked before proof)
// 3. User is on a supported ZKPassport chain (Ethereum, Base, Ethereum Sepolia, Base Sepolia)
// 4. User has enough native token for gas
```

### Error Reference

| Contract revert | Meaning |
|----------------|---------|
| `ProofVerificationFailed` | ZK proof invalid — IZKPassportVerifier rejected it |
| `InvalidScope` | SDK scope doesn't match `convexo-passport-identity` |
| `InvalidSender` | Proof not bound to this wallet address |
| `InvalidChain` | Proof not bound to this chain ID |
| `AgeVerificationFailed` | User under 18 or age proof invalid |
| `SanctionsCheckFailed` | User on sanctions list |
| `NationalityNotCompliant` | Nationality in blocked country list |
| `PassportExpired` | Physical passport/ID has expired |
| `AlreadyHasPassport` | Wallet already owns a passport NFT |
| `IdentifierAlreadyUsed` | This real-world identity already minted |
| `SoulboundTokenCannotBeTransferred` | NFTs are non-transferable by design |

---

## IPFS / Pinata

```typescript
// config/ipfs.ts
export const PINATA_GATEWAY = 'lime-famous-condor-7.mypinata.cloud';

export const NFT_IMAGES = {
  convexoPassport: 'bafybeiekwlyujx32cr5u3ixt5esfxhusalt5ljtrmsng74q7k45tilugh4',
  lpIndividuals:   'bafkreib7mkjzpdm3id6st6d5vsxpn7v5h6sxeiswejjmrbcb5yoagaf4em',
  lpBusiness:      'bafkreiejesvgsvohwvv7q5twszrbu5z6dnpke6sg5cdiwgn2rq7dilu33m',
  ecreditscoring:  'bafkreignxas6gqi7it5ng6muoykujxlgxxc4g7rr6sqvwgdfwveqf2zw3e',
};

export const ipfsUrl = (hash: string) => `https://${PINATA_GATEWAY}/ipfs/${hash}`;

export const createPassportMetadata = (tokenId: number, traits: {
  kycVerified: boolean; sanctionsPassed: boolean; isOver18: boolean;
}) => ({
  name: `Convexo Passport #${tokenId}`,
  description: 'Soulbound NFT for ZKPassport-verified identity. Grants Tier 1 access to Convexo Protocol.',
  image: ipfsUrl(NFT_IMAGES.convexoPassport),
  external_url: 'https://protocol.convexo.xyz',
  attributes: [
    { trait_type: 'Tier', value: '1' },
    { trait_type: 'KYC Verified', value: traits.kycVerified ? 'Yes' : 'No' },
    { trait_type: 'Sanctions Passed', value: traits.sanctionsPassed ? 'Yes' : 'No' },
    { trait_type: 'Age 18+', value: traits.isOver18 ? 'Yes' : 'No' },
    { trait_type: 'Soulbound', value: 'True' },
    { trait_type: 'Verification', value: 'ZKPassport' },
  ],
});

export const uploadToPinata = async (metadata: object): Promise<string> => {
  const res = await fetch('https://api.pinata.cloud/pinning/pinJSONToIPFS', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'pinata_api_key': process.env.PINATA_API_KEY!,
      'pinata_secret_api_key': process.env.PINATA_SECRET_KEY!,
    },
    body: JSON.stringify({ pinataContent: metadata }),
  });
  if (!res.ok) throw new Error('Pinata upload failed');
  const { IpfsHash } = await res.json();
  return IpfsHash;
};
```

---

## Contract Functions Reference

### ReputationManager

```typescript
// Read
getReputationTier(address user) returns (ReputationTier)      // 0-3
getReputationTierNumeric(address user) returns (uint256)
canAccessLPPools(address user) returns (bool)                  // Tier 1+
canInvestInVaults(address user) returns (bool)                 // Tier 1+
canRequestCreditScore(address user) returns (bool)             // Tier 2+
canCreateVaults(address user) returns (bool)                   // Tier 3 only
holdsPassport(address user) returns (bool)
holdsAnyLP(address user) returns (bool)
holdsEcreditscoring(address user) returns (bool)
getReputationDetails(address user) returns (tier, passportBal, lpIndBal, lpBizBal, ecredBal)
```

### Convexo_Passport (Tier 1)

```typescript
// Write (caller = user — no admin required)
claimPassport(
  proof: ProofVerificationParams,  // from ZKPassport SDK getSolidityVerifierParameters()
  isIDCard: boolean,               // false=passport, true=ID card
  ipfsMetadataHash: string         // IPFS hash for NFT metadata
) returns (uint256 tokenId)

revokePassport(uint256 tokenId)  // REVOKER_ROLE only

// Read
holdsActivePassport(address holder) returns (bool)
getVerifiedIdentity(address holder) returns (VerifiedIdentity)
isIdentifierUsed(bytes32 uniqueIdentifier) returns (bool)  // bytes32, not string
getActivePassportCount() returns (uint256)

// VerifiedIdentity struct
{ bytes32 identifierHash, uint256 verifiedAt, uint256 zkPassportTimestamp,
  bool isActive, bool isIDCard, bool sanctionsPassed, bool isOver18, bool nationalityCompliant }
```

### VeriffVerifier / SumsubVerifier (Tier 2 Registry)

```typescript
// Write (VERIFIER_ROLE)
submitVerification(address user, string sessionId)     // Veriff
submitVerification(address user, string applicantId, string companyName,
  string registrationNumber, string jurisdiction, BusinessType)  // Sumsub
approveVerification(address user)   // status → Approved (NO auto-mint)
rejectVerification(address user, string reason)
resetVerification(address user)     // DEFAULT_ADMIN_ROLE
markAsMinted(address user, uint256 tokenId)  // MINTER_CALLBACK_ROLE (called by NFT)

// Read (public — no sensitive data)
hasVerificationRecord(address user) returns (bool)
getStatus(address user) returns (VerificationStatus)
isApproved(address user) returns (bool)
isMinted(address user) returns (bool)
isVerified(address user) returns (bool)  // Approved OR Minted
```

### VaultFactory

```typescript
// Write (Tier 3 required)
createVault(
  uint256 principalAmount,   // USDC 6-dec (e.g. 100_000e6 = $100k)
  uint256 interestRate,      // bps (e.g. 1200 = 12%)
  uint256 protocolFeeRate,   // bps (e.g. 200 = 2%, max 1000)
  uint256 maturityDate,      // unix timestamp (must be future)
  uint256 totalShareSupply,  // number of shares (e.g. 1000 → $100/share at $100k raise)
  uint256 minInvestment,     // min USDC per deposit (e.g. 100e6 = $100)
  string name,               // ERC-20 share token name
  string symbol              // ERC-20 share token symbol
) returns (uint256 vaultId, address vaultAddress)

// Guard: principalAmount >= totalShareSupply × 1e6 (share price ≥ $1)

updateProtocolFeeCollector(address)  // DEFAULT_ADMIN_ROLE

// Read
getVault(uint256 vaultId) returns (address)
getVaultCount() returns (uint256)
getVaultAddressAtIndex(uint256 index) returns (address)
```

### TokenizedBondVault (ERC-7540 Async Redeem)

```typescript
// Share price model (all deterministic, unaffected by redemptions)
getBaseSharePrice() returns (uint256)          // principalAmount / totalShares (USDC 6-dec)
getExpectedFinalSharePrice() returns (uint256) // (principal + interest − fee) / totalShares
getCurrentSharePrice() returns (uint256)       // interpolated at current repaid fraction
originalTotalShares() returns (uint256)        // totalShareSupply × 1e18 (immutable)
minInvestment() returns (uint256)

// Write — Investor (Tier 1+)
deposit(uint256 assets, address receiver) returns (uint256 shares)
  // state: Pending/Funded — approve USDC first
requestRedeem(uint256 shares, address controller, address owner) returns (uint256 requestId)
  // state: Repaying/Completed — locks shares, requestId always 0
redeem(uint256 shares, address receiver, address controller) returns (uint256 assets)
  // claim USDC proportional to repaid fraction; call multiple times as repayments accumulate
earlyExit(uint256 shares)
  // state: Pending/Funded — refund at base price before borrower withdraws

// Write — Borrower
withdrawFunds()                     // contract must be signed
makeRepayment(uint256 amount)       // transitions state to Repaying → Completed

// Write — Admin/Borrower (VAULT_MANAGER_ROLE)
attachContract(bytes32 contractHash)
markAsDefaulted()
withdrawProtocolFees()
setMinInvestment(uint256 amount)

// Read — ERC-7540
pendingRedeemRequest(uint256, address) returns (uint256)     // always 0
claimableRedeemRequest(uint256, address controller) returns (uint256)  // remaining locked shares

// Read — ERC-4626
asset() returns (address)
totalAssets() returns (uint256)
convertToShares(uint256 assets) returns (uint256)
convertToAssets(uint256 shares) returns (uint256)
maxDeposit(address) returns (uint256)
previewDeposit(uint256 assets) returns (uint256)

// Read — Vault-specific
getVaultState() returns (VaultState)
getVaultBorrower() returns (address)
getVaultPrincipalAmount() returns (uint256)
getVaultTotalRepaid() returns (uint256)
getRepaymentStatus() returns (uint256 totalDue, uint256 totalPaid, uint256 remaining, uint256 protocolFee)
getInvestorReturn(address) returns (uint256 invested, uint256 currentValue, uint256 profit, uint256 apy)
getRedeemState(address controller) returns (uint256 originalLocked, uint256 remainingLocked, uint256 claimed, uint256 claimableNow)
getInvestors() returns (address[])
```

### ContractSigner

```typescript
// Write
createContract(bytes32 documentHash, AgreementType, address[] signers, string ipfsHash, uint256 minTier, uint256 expirySeconds)
signContract(bytes32 documentHash, bytes signature)
executeContract(bytes32 documentHash, uint256 vaultId)

// Read
getContract(bytes32 documentHash) returns (ContractDocument)
isFullySigned(bytes32 documentHash) returns (bool)
isContractSigned(bytes32 documentHash, address signer) returns (bool)
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

  const { data, isLoading, refetch } = useReadContracts({
    contracts: address ? [
      { address: contracts.REPUTATION_MANAGER as `0x${string}`, abi: ReputationManagerABI, functionName: 'getReputationDetails', args: [address] },
      { address: contracts.REPUTATION_MANAGER as `0x${string}`, abi: ReputationManagerABI, functionName: 'canInvestInVaults', args: [address] },
      { address: contracts.REPUTATION_MANAGER as `0x${string}`, abi: ReputationManagerABI, functionName: 'canCreateVaults', args: [address] },
    ] : [],
  });

  return {
    tier: Number(data?.[0].result?.[0] ?? 0),
    canInvestInVaults: (data?.[1].result ?? false) as boolean,
    canCreateVaults: (data?.[2].result ?? false) as boolean,
    isLoading,
    refetch,
  };
}
```

### useInvestInVault (ERC-7540)

```typescript
// hooks/useInvestInVault.ts
import { useWriteContract, useWaitForTransactionReceipt, useReadContract } from 'wagmi';
import { parseUnits } from 'viem';
import { TokenizedBondVaultABI } from '../config/abis';
import { getContracts } from '../config/contracts';

const ERC20_ABI = [
  { name: 'approve', type: 'function', inputs: [{ name: 'spender', type: 'address' }, { name: 'amount', type: 'uint256' }], outputs: [{ type: 'bool' }] },
  { name: 'allowance', type: 'function', inputs: [{ name: 'owner', type: 'address' }, { name: 'spender', type: 'address' }], outputs: [{ type: 'uint256' }] },
] as const;

export function useInvestInVault(vaultAddress: `0x${string}`, userAddress: `0x${string}` | undefined, chainId: number) {
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

  // ERC-4626 deposit (replaces purchaseShares)
  const approve = (amount: string) => writeContract({
    address: contracts.USDC as `0x${string}`,
    abi: ERC20_ABI,
    functionName: 'approve',
    args: [vaultAddress, parseUnits(amount, 6)],
  });

  const deposit = (amount: string) => writeContract({
    address: vaultAddress,
    abi: TokenizedBondVaultABI,
    functionName: 'deposit',
    args: [parseUnits(amount, 6), userAddress!],
  });

  // ERC-7540 redeem flow
  const requestRedeem = (shares: bigint) => writeContract({
    address: vaultAddress,
    abi: TokenizedBondVaultABI,
    functionName: 'requestRedeem',
    args: [shares, userAddress!, userAddress!],
  });

  const redeem = (shares: bigint) => writeContract({
    address: vaultAddress,
    abi: TokenizedBondVaultABI,
    functionName: 'redeem',
    args: [shares, userAddress!, userAddress!],
  });

  return { approve, deposit, requestRedeem, redeem, allowance, refetchAllowance, hash, isPending, isConfirming, isSuccess, error };
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
  principalAmount: string;   // e.g. "100000" → 100k USDC
  interestRate: number;      // bps, e.g. 1200 = 12%
  protocolFeeRate: number;   // bps, e.g. 200 = 2%
  maturityDays: number;      // days from now
  totalShareSupply: number;  // e.g. 1000 shares → $100/share at $100k raise
  minInvestment: string;     // e.g. "100" → 100 USDC minimum
  name: string;
  symbol: string;
}

export function useCreateVault(chainId: number) {
  const contracts = getContracts(chainId);
  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess, data: receipt } = useWaitForTransactionReceipt({ hash });

  const createVault = (params: CreateVaultParams) => writeContract({
    address: contracts.VAULT_FACTORY as `0x${string}`,
    abi: VaultFactoryABI,
    functionName: 'createVault',
    args: [
      parseUnits(params.principalAmount, 6),
      BigInt(params.interestRate),
      BigInt(params.protocolFeeRate),
      BigInt(Math.floor(Date.now() / 1000) + params.maturityDays * 86400),
      BigInt(params.totalShareSupply),
      parseUnits(params.minInvestment, 6),
      params.name,
      params.symbol,
    ],
  });

  return { createVault, hash, isPending, isConfirming, isSuccess, receipt, error };
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
      { address: contracts.VERIFF_VERIFIER as `0x${string}`, abi: VeriffVerifierABI, functionName: 'hasVerificationRecord', args: [address] },
      { address: contracts.VERIFF_VERIFIER as `0x${string}`, abi: VeriffVerifierABI, functionName: 'getStatus', args: [address] },
      { address: contracts.SUMSUB_VERIFIER as `0x${string}`, abi: SumsubVerifierABI, functionName: 'hasVerificationRecord', args: [address] },
      { address: contracts.SUMSUB_VERIFIER as `0x${string}`, abi: SumsubVerifierABI, functionName: 'getStatus', args: [address] },
    ] : [],
  });

  return {
    veriff: { hasRecord: data?.[0].result ?? false, status: Number(data?.[1].result ?? 0) },
    sumsub: { hasRecord: data?.[2].result ?? false, status: Number(data?.[3].result ?? 0) },
    isLoading,
    refetch,
  };
}
```

---

## UI Examples

### User Dashboard

```tsx
// components/Dashboard.tsx
import { useAccount, useChainId } from 'wagmi';
import { useUserReputation } from '../hooks/useUserReputation';

const TIER_LABELS = ['Unverified', 'Passport Holder', 'Limited Partner', 'Vault Creator'];

export function Dashboard() {
  const { address } = useAccount();
  const chainId = useChainId();
  const { tier, canInvestInVaults, canCreateVaults, isLoading } = useUserReputation(address, chainId);

  if (isLoading) return <div>Loading...</div>;

  return (
    <div>
      <p>Tier {tier}: {TIER_LABELS[tier]}</p>
      <p>{canInvestInVaults ? '✅' : '❌'} Invest in vaults</p>
      <p>{canCreateVaults ? '✅' : '❌'} Create vaults</p>
    </div>
  );
}
```

### Vault Investment Card (ERC-7540)

```tsx
// components/VaultCard.tsx
import { useAccount, useChainId, useReadContracts } from 'wagmi';
import { formatUnits } from 'viem';
import { useState } from 'react';
import { TokenizedBondVaultABI } from '../config/abis';
import { useInvestInVault } from '../hooks/useInvestInVault';
import { useUserReputation } from '../hooks/useUserReputation';

export function VaultCard({ vaultAddress }: { vaultAddress: `0x${string}` }) {
  const { address } = useAccount();
  const chainId = useChainId();
  const { canInvestInVaults } = useUserReputation(address, chainId);
  const { approve, deposit, requestRedeem, redeem, isPending, isSuccess } = useInvestInVault(vaultAddress, address, chainId);
  const [amount, setAmount] = useState('');

  const { data } = useReadContracts({
    contracts: [
      { address: vaultAddress, abi: TokenizedBondVaultABI, functionName: 'getVaultState' },
      { address: vaultAddress, abi: TokenizedBondVaultABI, functionName: 'getBaseSharePrice' },
      { address: vaultAddress, abi: TokenizedBondVaultABI, functionName: 'getExpectedFinalSharePrice' },
      { address: vaultAddress, abi: TokenizedBondVaultABI, functionName: 'getCurrentSharePrice' },
      { address: vaultAddress, abi: TokenizedBondVaultABI, functionName: 'claimableRedeemRequest', args: [0n, address!] },
    ],
  });

  const [state, basePrice, finalPrice, currentPrice, claimableShares] = data?.map(d => d.result) ?? [];
  const isDepositPhase = state === 0 || state === 1; // Pending or Funded
  const isRedeemPhase = state === 3 || state === 4;  // Repaying or Completed

  return (
    <div>
      <div>Base price: ${formatUnits(basePrice ?? 0n, 6)}</div>
      <div>Expected final: ${formatUnits(finalPrice ?? 0n, 6)}</div>
      <div>Current price: ${formatUnits(currentPrice ?? 0n, 6)}</div>

      {canInvestInVaults && isDepositPhase && (
        <div>
          <input value={amount} onChange={e => setAmount(e.target.value)} placeholder="USDC amount" />
          <button onClick={() => approve(amount)} disabled={isPending}>Approve</button>
          <button onClick={() => deposit(amount)} disabled={isPending}>Deposit</button>
        </div>
      )}

      {isRedeemPhase && (
        <div>
          <button onClick={() => requestRedeem(/* shares from balanceOf */ 0n)}>Request Redeem</button>
          {(claimableShares as bigint) > 0n && (
            <button onClick={() => redeem(claimableShares as bigint)}>Claim USDC</button>
          )}
        </div>
      )}

      {isSuccess && <p>Transaction successful!</p>}
    </div>
  );
}
```

---

## Access Control Summary

| Action | Required Tier | Contract | Function |
|--------|---------------|----------|----------|
| Uniswap V4 swaps | 1+ | PassportGatedHook | (automatic) |
| Invest in vault | 1+ | TokenizedBondVault | `deposit()` |
| Request redeem | 1+ | TokenizedBondVault | `requestRedeem()` |
| Claim USDC | 1+ | TokenizedBondVault | `redeem()` |
| Request credit score | 2+ | Backend API | — |
| OTC orders | 2+ | OTC contracts | — |
| Create vault | 3 | VaultFactory | `createVault()` |

---

## Verification Flow

```
TIER 1 — Passport (Individual Self-Claim, trustless):
  ZKPassport app → SDK createVerificationRequest (mode: compressed-evm) → onProofGenerated
  → getSolidityVerifierParameters() → upload Pinata → claimPassport(proof, isIDCard, ipfsHash)
  → contract verifies ZK proof on-chain → NFT minted

TIER 2A — Individual (Admin-Mint):
  Veriff KYC → backend → submitVerification() → admin approveVerification() → admin safeMint() → NFT
  (NFT auto-calls verifier.markAsMinted())

TIER 2B — Business (Admin-Mint):
  Sumsub KYB → backend → submitVerification() → admin approveVerification() → admin safeMint() → NFT

TIER 3 — Vault Creator (Backend-Mint):
  User with LP NFT → AI credit score → backend safeMint() → NFT
```

---

*Version 3.17 · March 2026*

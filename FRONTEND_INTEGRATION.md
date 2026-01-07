# 🎨 Frontend Integration Guide

Complete guide for integrating Convexo Protocol smart contracts into your frontend application.

**Version**: 2.2  
**Framework**: React + Viem + Wagmi + RainbowKit  
**Last Updated**: January 2026

---

## 📋 Table of Contents

1. [Quick Setup](#quick-setup)
2. [Contract Configuration](#contract-configuration)
3. [NFT & Reputation System](#nft--reputation-system)
4. [User Authentication Flow](#user-authentication-flow)
5. [Vault Operations](#vault-operations)
6. [Treasury Operations](#treasury-operations)
7. [React Hooks](#react-hooks)
8. [Complete Examples](#complete-examples)

---

## ⚡ Quick Setup

### Install Dependencies

```bash
npm install viem wagmi @rainbow-me/rainbowkit @tanstack/react-query
```

### Configure Chains

```typescript
// config/wagmi.ts
import { createConfig, http } from 'wagmi';
import { mainnet, sepolia, base, baseSepolia } from 'wagmi/chains';
import { connectorsForWallets } from '@rainbow-me/rainbowkit';
import { 
  rainbowWallet, 
  walletConnectWallet,
  metaMaskWallet,
  coinbaseWallet 
} from '@rainbow-me/rainbowkit/wallets';

// Define Unichain
const unichain = {
  id: 130,
  name: 'Unichain',
  nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 },
  rpcUrls: {
    default: { http: ['https://mainnet.unichain.org'] },
  },
  blockExplorers: {
    default: { name: 'Blockscout', url: 'https://unichain.blockscout.com' },
  },
};

const unichainSepolia = {
  id: 1301,
  name: 'Unichain Sepolia',
  nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 },
  rpcUrls: {
    default: { http: ['https://sepolia.unichain.org'] },
  },
  blockExplorers: {
    default: { name: 'Blockscout', url: 'https://unichain-sepolia.blockscout.com' },
  },
  testnet: true,
};

export const config = createConfig({
  chains: [mainnet, base, unichain, sepolia, baseSepolia, unichainSepolia],
  transports: {
    [mainnet.id]: http(),
    [base.id]: http(),
    [unichain.id]: http(),
    [sepolia.id]: http(),
    [baseSepolia.id]: http(),
    [unichainSepolia.id]: http(),
  },
});
```

---

## 📍 Contract Configuration

### Contract Addresses

```typescript
// config/contracts.ts
export const CONTRACTS = {
  // Ethereum Sepolia (11155111)
  ETHEREUM_SEPOLIA: {
    CHAIN_ID: 11155111,
    CONVEXO_PASSPORT: '0x259adc4917c442dd9a509cb8333a9bed88fe5c70',
    LP_INDIVIDUALS: '0x6d2101b853e80ea873d2c7c0ec6138c837779c6a',    // Limited_Partners_Individuals
    LP_BUSINESS: '0xd1ff2d103a864ccb150602dedc09804037b8ce85',       // Limited_Partners_Business
    ECREDITSCORING: '0x...',  // Ecreditscoring NFT (TBD)
    REPUTATION_MANAGER: '0x82e856e70a0057fc6e26c17793a890ec38194cfc',
    VAULT_FACTORY: '0x4fc5ca49812b0c312046b000d234a96e9084effb',
    TREASURY_FACTORY: '0x53d38e2ca13d085d14a44b0deadc47995a82eca3',
    CONTRACT_SIGNER: '0x59b0f14ac23cd3b0a6a926a302ac01e4221785bf',
    VERIFF_VERIFIER: '0xb11f1c681b8719e6d82098e1316d2573477834ab',
    COMPLIANT_LP_HOOK: '0xb1697c34cc15cb1fba579f94693e9ab53292b51b',
    POOL_REGISTRY: '0x710299e39b130db198dd2a6973c2ccd7bcc2d093',
    PRICE_FEED_MANAGER: '0xebb59c7e14ea002924bf34eedf548836c25a3440',
    USDC: '0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238',
  },

  // Base Sepolia (84532)
  BASE_SEPOLIA: {
    CHAIN_ID: 84532,
    CONVEXO_PASSPORT: '0x5078300fa7e2d29c2e2145beb8a6eb5ad0d45e0c',
    LP_INDIVIDUALS: '0xf048da86da99a76856c02a83fb53e72277acacdf',
    LP_BUSINESS: '0xe9309e75f168b5c98c37a5465e539a0fdbf33eb9',
    ECREDITSCORING: '0x...',
    REPUTATION_MANAGER: '0xc8d1160e2e7719e29b34ab36402aaa0ec24d8c01',
    VAULT_FACTORY: '0xb987dd28a350d0d88765ac7310c0895b76fa0828',
    TREASURY_FACTORY: '0x68ec89e0884d05d3b4d2f9b27e4212820b1a56e5',
    CONTRACT_SIGNER: '0x437e0a14a515fa5dc5655a11856fe28c7bb78477',
    VERIFF_VERIFIER: '0x6f7413e36ffed4bde41b4521cf240aef0668201f',
    COMPLIANT_LP_HOOK: '0x058faa5e95b3deb41e6ecabe4dd870b8e3d90475',
    POOL_REGISTRY: '0x6ad2b7bd52d6382bc7ba37687be5533eb2cf4cd2',
    PRICE_FEED_MANAGER: '0x653bcfc6ea735fb67d73ff537746b804c75cd1f4',
    USDC: '0x036CbD53842c5426634e7929541eC2318f3dCF7e',
  },

  // Unichain Sepolia (1301)
  UNICHAIN_SEPOLIA: {
    CHAIN_ID: 1301,
    CONVEXO_PASSPORT: '0xab83ce760054c1d048d5a9de5194b05398a09d41',
    LP_INDIVIDUALS: '0xfb965542aa0b58538a9b50fe020314dd687eb128',
    LP_BUSINESS: '0x503f203ce6d6462f433cd04c7ad2b05d61b56548',
    ECREDITSCORING: '0x...',
    REPUTATION_MANAGER: '0x62227ff7ccbdb4d72c3511290b28c3424f1500ef',
    VAULT_FACTORY: '0x2cfa02372782cf20ef8342b0193fd69e4c5b04a8',
    TREASURY_FACTORY: '0xecde45fefb5c2ef6e5cc615291de9be9a99b46a6',
    CONTRACT_SIGNER: '0xa932e3eaa0a5e5e65f0567405207603266937618',
    VERIFF_VERIFIER: '0xe99a49bd81bbe61cdf7f6b7d247f76cacc2e5776',
    COMPLIANT_LP_HOOK: '0x50ace0dce54df668477adee4e9d6a6c0df4fedee',
    POOL_REGISTRY: '0xa46629011e0b8561a45ea03b822d28c0b2432c3a',
    PRICE_FEED_MANAGER: '0x8efc7e25c12a815329331da5f0e96affb4014472',
    USDC: '0x31d0220469e10c4E71834a79b1f276d740d3768F',
  },
} as const;

// Helper to get contracts for current chain
export function getContracts(chainId: number) {
  switch (chainId) {
    case 11155111: return CONTRACTS.ETHEREUM_SEPOLIA;
    case 84532: return CONTRACTS.BASE_SEPOLIA;
    case 1301: return CONTRACTS.UNICHAIN_SEPOLIA;
    default: return CONTRACTS.BASE_SEPOLIA;
  }
}
```

### Import ABIs

```typescript
// config/abis.ts
import ConvexoPassportABI from '../abis/Convexo_Passport.json';
import ReputationManagerABI from '../abis/ReputationManager.json';
import TokenizedBondVaultABI from '../abis/TokenizedBondVault.json';
import VaultFactoryABI from '../abis/VaultFactory.json';
import TreasuryFactoryABI from '../abis/TreasuryFactory.json';
import ContractSignerABI from '../abis/ContractSigner.json';
import VeriffVerifierABI from '../abis/VeriffVerifier.json';
import ERC20ABI from '../abis/ERC20.json';

export {
  ConvexoPassportABI,
  ReputationManagerABI,
  TokenizedBondVaultABI,
  VaultFactoryABI,
  TreasuryFactoryABI,
  ContractSignerABI,
  VeriffVerifierABI,
  ERC20ABI,
};
```

---

## 🎫 NFT & Reputation System

### Understanding the Tier System

```typescript
// types/reputation.ts
export enum ReputationTier {
  None = 0,           // No NFTs - No access
  Passport = 1,       // Convexo_Passport - ZKPassport verified
  LimitedPartner = 2, // LP_Individuals OR LP_Business - Full LP access
  VaultCreator = 3,   // Ecreditscoring - Can create vaults
}

export interface UserReputation {
  tier: ReputationTier;
  tierName: string;
  passportBalance: bigint;
  lpIndividualsBalance: bigint;
  lpBusinessBalance: bigint;
  ecreditscoringBalance: bigint;
  // Access permissions
  canAccessLPPools: boolean;
  canCreateTreasury: boolean;
  canInvestInVaults: boolean;
  canRequestCreditScore: boolean;
  canCreateVaults: boolean;
}

export const TIER_NAMES: Record<ReputationTier, string> = {
  [ReputationTier.None]: 'Unverified',
  [ReputationTier.Passport]: 'Passport Holder',
  [ReputationTier.LimitedPartner]: 'Limited Partner',
  [ReputationTier.VaultCreator]: 'Vault Creator',
};

export const TIER_COLORS: Record<ReputationTier, string> = {
  [ReputationTier.None]: 'gray',
  [ReputationTier.Passport]: 'blue',
  [ReputationTier.LimitedPartner]: 'purple',
  [ReputationTier.VaultCreator]: 'gold',
};
```

### useUserReputation Hook

```typescript
// hooks/useUserReputation.ts
import { useReadContracts } from 'wagmi';
import { getContracts } from '../config/contracts';
import { ReputationManagerABI } from '../config/abis';
import { ReputationTier, UserReputation, TIER_NAMES } from '../types/reputation';

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

  const reputation: UserReputation | null = data ? {
    tier: Number(data[0].result?.[0]) as ReputationTier,
    tierName: TIER_NAMES[Number(data[0].result?.[0]) as ReputationTier],
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

### Reputation Badge Component

```tsx
// components/ReputationBadge.tsx
import { ReputationTier, TIER_NAMES, TIER_COLORS } from '../types/reputation';

interface ReputationBadgeProps {
  tier: ReputationTier;
  size?: 'sm' | 'md' | 'lg';
}

const TIER_ICONS: Record<ReputationTier, string> = {
  [ReputationTier.None]: '⚪',
  [ReputationTier.Passport]: '🛂',
  [ReputationTier.LimitedPartner]: '💼',
  [ReputationTier.VaultCreator]: '🏆',
};

export function ReputationBadge({ tier, size = 'md' }: ReputationBadgeProps) {
  const sizeClasses = {
    sm: 'px-2 py-1 text-xs',
    md: 'px-3 py-1.5 text-sm',
    lg: 'px-4 py-2 text-base',
  };

  return (
    <span 
      className={`inline-flex items-center gap-1.5 rounded-full font-medium ${sizeClasses[size]}`}
      style={{ 
        backgroundColor: `${TIER_COLORS[tier]}20`,
        color: TIER_COLORS[tier],
        border: `1px solid ${TIER_COLORS[tier]}40`
      }}
    >
      <span>{TIER_ICONS[tier]}</span>
      <span>{TIER_NAMES[tier]}</span>
    </span>
  );
}
```

### Access Matrix Component

```tsx
// components/AccessMatrix.tsx
import { UserReputation } from '../types/reputation';

interface AccessMatrixProps {
  reputation: UserReputation;
}

export function AccessMatrix({ reputation }: AccessMatrixProps) {
  const accessItems = [
    { label: 'LP Pools', hasAccess: reputation.canAccessLPPools },
    { label: 'Create Treasury', hasAccess: reputation.canCreateTreasury },
    { label: 'Invest in Vaults', hasAccess: reputation.canInvestInVaults },
    { label: 'Request Credit Score', hasAccess: reputation.canRequestCreditScore },
    { label: 'Create Vaults', hasAccess: reputation.canCreateVaults },
  ];

  return (
    <div className="grid grid-cols-2 gap-3">
      {accessItems.map((item) => (
        <div 
          key={item.label}
          className={`p-3 rounded-lg border ${
            item.hasAccess 
              ? 'bg-green-50 border-green-200' 
              : 'bg-gray-50 border-gray-200'
          }`}
        >
          <div className="flex items-center gap-2">
            <span className={item.hasAccess ? 'text-green-500' : 'text-gray-400'}>
              {item.hasAccess ? '✅' : '❌'}
            </span>
            <span className="text-sm font-medium">{item.label}</span>
          </div>
        </div>
      ))}
    </div>
  );
}
```

---

## 🔐 User Authentication Flow

### Authentication Flow Diagram

```
┌────────────────────────────────────────────────────────────────────────────┐
│                         USER AUTHENTICATION FLOWS                          │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  PATH 1: International Investor (Tier 1)                                  │
│  ═══════════════════════════════════════                                  │
│  ZKPassport ──▶ safeMintWithIdentifier() ──▶ Convexo_Passport NFT         │
│                                                                            │
│  PATH 2: Individual LP (Tier 2)                                           │
│  ═══════════════════════════════                                          │
│  Veriff KYC ──▶ VeriffVerifier.approveVerification() ──▶ LP_Individuals   │
│                                                                            │
│  PATH 3: Business LP (Tier 2)                                             │
│  ═════════════════════════════                                            │
│  Sumsub KYB ──▶ SumsubVerifier.approveVerification() ──▶ LP_Business      │
│                                                                            │
│  PATH 4: Vault Creator (Tier 3)                                           │
│  ═══════════════════════════════                                          │
│  LP NFT + AI Credit Score ──▶ mint() ──▶ Ecreditscoring NFT               │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
```

### Passport Minting (Path 1)

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

  const mintWithIdentifier = async (uniqueIdentifier: `0x${string}`) => {
    await writeContract({
      address: contracts.CONVEXO_PASSPORT as `0x${string}`,
      abi: ConvexoPassportABI,
      functionName: 'safeMintWithIdentifier',
      args: [uniqueIdentifier],
    });
  };

  // Helper to generate identifier from ZKPassport data
  const generateIdentifier = (publicKey: string, scope: string): `0x${string}` => {
    const combined = publicKey + scope.replace('0x', '');
    return keccak256(toBytes(combined));
  };

  return {
    mintWithIdentifier,
    generateIdentifier,
    hash,
    isPending,
    isConfirming,
    isSuccess,
    error,
  };
}
```

### Passport Minting Component

```tsx
// components/MintPassport.tsx
import { useState } from 'react';
import { useAccount, useChainId } from 'wagmi';
import { useMintPassport } from '../hooks/useMintPassport';

export function MintPassport() {
  const { address } = useAccount();
  const chainId = useChainId();
  const { mintWithIdentifier, generateIdentifier, isPending, isConfirming, isSuccess, error } = useMintPassport(chainId);
  
  const [zkPassportData, setZkPassportData] = useState<{
    publicKey: string;
    scope: string;
  } | null>(null);

  const handleMint = async () => {
    if (!zkPassportData) return;
    
    const identifier = generateIdentifier(zkPassportData.publicKey, zkPassportData.scope);
    await mintWithIdentifier(identifier);
  };

  return (
    <div className="p-6 bg-white rounded-xl shadow-lg">
      <h2 className="text-2xl font-bold mb-4">🛂 Get Your Convexo Passport</h2>
      
      <div className="space-y-4">
        {/* Step 1: ZKPassport Verification */}
        <div className="p-4 bg-blue-50 rounded-lg">
          <h3 className="font-semibold mb-2">Step 1: Verify with ZKPassport</h3>
          <p className="text-sm text-gray-600 mb-3">
            Complete identity verification using your passport or ID card.
          </p>
          <button
            onClick={() => {
              // Trigger ZKPassport flow
              // On success, set zkPassportData
            }}
            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
          >
            Start Verification
          </button>
        </div>

        {/* Step 2: Mint NFT */}
        {zkPassportData && (
          <div className="p-4 bg-green-50 rounded-lg">
            <h3 className="font-semibold mb-2">Step 2: Mint Your Passport NFT</h3>
            <p className="text-sm text-gray-600 mb-3">
              ✅ Verification complete! Now mint your soulbound Passport NFT.
            </p>
            <button
              onClick={handleMint}
              disabled={isPending || isConfirming}
              className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50"
            >
              {isPending ? 'Confirming...' : isConfirming ? 'Minting...' : 'Mint Passport NFT'}
            </button>
          </div>
        )}

        {/* Success */}
        {isSuccess && (
          <div className="p-4 bg-emerald-100 rounded-lg text-emerald-800">
            🎉 Passport NFT minted successfully! You now have Tier 1 access.
          </div>
        )}

        {/* Error */}
        {error && (
          <div className="p-4 bg-red-100 rounded-lg text-red-800">
            ❌ Error: {error.message}
          </div>
        )}
      </div>
    </div>
  );
}
```

---

## 🏦 Vault Operations

### Vault Types

```typescript
// types/vault.ts
export enum VaultState {
  Pending = 0,    // Accepting investments
  Funded = 1,     // Fully funded
  Active = 2,     // Contract signed
  Repaying = 3,   // Making repayments
  Completed = 4,  // All done
  Defaulted = 5,  // Failed
}

export interface VaultInfo {
  vaultId: bigint;
  borrower: `0x${string}`;
  contractHash: `0x${string}`;
  principalAmount: bigint;
  interestRate: bigint;
  protocolFeeRate: bigint;
  maturityDate: bigint;
  state: VaultState;
  totalRaised: bigint;
  totalRepaid: bigint;
  createdAt: bigint;
  fundedAt: bigint;
  contractAttachedAt: bigint;
  fundsWithdrawnAt: bigint;
}

export interface VaultMetrics {
  totalShares: bigint;
  sharePrice: bigint;
  totalValueLocked: bigint;
  targetAmount: bigint;
  fundingProgress: bigint;
  currentAPY: bigint;
}

export interface InvestorReturn {
  invested: bigint;
  currentValue: bigint;
  profit: bigint;
  apy: bigint;
}
```

### useVaultData Hook

```typescript
// hooks/useVaultData.ts
import { useReadContracts } from 'wagmi';
import { TokenizedBondVaultABI } from '../config/abis';
import { VaultInfo, VaultMetrics, VaultState } from '../types/vault';

export function useVaultData(vaultAddress: `0x${string}`) {
  const { data, isLoading, error, refetch } = useReadContracts({
    contracts: [
      {
        address: vaultAddress,
        abi: TokenizedBondVaultABI,
        functionName: 'vaultInfo',
      },
      {
        address: vaultAddress,
        abi: TokenizedBondVaultABI,
        functionName: 'getVaultMetrics',
      },
    ],
  });

  const vaultInfo: VaultInfo | null = data?.[0]?.result ? {
    vaultId: data[0].result[0],
    borrower: data[0].result[1],
    contractHash: data[0].result[2],
    principalAmount: data[0].result[3],
    interestRate: data[0].result[4],
    protocolFeeRate: data[0].result[5],
    maturityDate: data[0].result[6],
    state: Number(data[0].result[7]) as VaultState,
    totalRaised: data[0].result[8],
    totalRepaid: data[0].result[9],
    createdAt: data[0].result[10],
    fundedAt: data[0].result[11],
    contractAttachedAt: data[0].result[12],
    fundsWithdrawnAt: data[0].result[13],
  } : null;

  const metrics: VaultMetrics | null = data?.[1]?.result ? {
    totalShares: data[1].result[0],
    sharePrice: data[1].result[1],
    totalValueLocked: data[1].result[2],
    targetAmount: data[1].result[3],
    fundingProgress: data[1].result[4],
    currentAPY: data[1].result[5],
  } : null;

  return { vaultInfo, metrics, isLoading, error, refetch };
}
```

### Create Vault (Tier 3 Only)

```typescript
// hooks/useCreateVault.ts
import { useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { parseUnits } from 'viem';
import { VaultFactoryABI } from '../config/abis';
import { getContracts } from '../config/contracts';

interface CreateVaultParams {
  principalAmount: string;      // USDC amount (e.g., "10000")
  interestRate: number;         // Basis points (1200 = 12%)
  protocolFeeRate: number;      // Basis points (200 = 2%)
  maturityDays: number;         // Days until maturity
  name: string;
  symbol: string;
}

export function useCreateVault(chainId: number) {
  const contracts = getContracts(chainId);
  
  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess, data: receipt } = useWaitForTransactionReceipt({ hash });

  const createVault = async (params: CreateVaultParams) => {
    const principalAmount = parseUnits(params.principalAmount, 6); // USDC has 6 decimals
    const maturityDate = BigInt(Math.floor(Date.now() / 1000) + params.maturityDays * 24 * 60 * 60);

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

### Invest in Vault (Tier 1+)

```typescript
// hooks/useInvestInVault.ts
import { useWriteContract, useWaitForTransactionReceipt, useReadContract } from 'wagmi';
import { parseUnits, maxUint256 } from 'viem';
import { TokenizedBondVaultABI, ERC20ABI } from '../config/abis';
import { getContracts } from '../config/contracts';

export function useInvestInVault(vaultAddress: `0x${string}`, chainId: number) {
  const contracts = getContracts(chainId);
  
  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  // Check current allowance
  const { data: allowance, refetch: refetchAllowance } = useReadContract({
    address: contracts.USDC as `0x${string}`,
    abi: ERC20ABI,
    functionName: 'allowance',
    args: [vaultAddress],
  });

  const approve = async (amount: string) => {
    await writeContract({
      address: contracts.USDC as `0x${string}`,
      abi: ERC20ABI,
      functionName: 'approve',
      args: [vaultAddress, parseUnits(amount, 6)],
    });
  };

  const invest = async (amount: string) => {
    const amountWei = parseUnits(amount, 6);
    
    await writeContract({
      address: vaultAddress,
      abi: TokenizedBondVaultABI,
      functionName: 'purchaseShares',
      args: [amountWei],
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

### Vault Investment Card

```tsx
// components/VaultInvestmentCard.tsx
import { useState } from 'react';
import { useAccount, useChainId } from 'wagmi';
import { formatUnits } from 'viem';
import { useVaultData } from '../hooks/useVaultData';
import { useInvestInVault } from '../hooks/useInvestInVault';
import { useUserReputation } from '../hooks/useUserReputation';
import { VaultState } from '../types/vault';

interface VaultInvestmentCardProps {
  vaultAddress: `0x${string}`;
}

export function VaultInvestmentCard({ vaultAddress }: VaultInvestmentCardProps) {
  const { address } = useAccount();
  const chainId = useChainId();
  const { vaultInfo, metrics, isLoading } = useVaultData(vaultAddress);
  const { reputation } = useUserReputation(address, chainId);
  const { approve, invest, isPending, isConfirming, isSuccess } = useInvestInVault(vaultAddress, chainId);
  
  const [amount, setAmount] = useState('');

  if (isLoading || !vaultInfo || !metrics) {
    return <div className="animate-pulse bg-gray-200 h-64 rounded-xl" />;
  }

  const canInvest = reputation?.canInvestInVaults && vaultInfo.state === VaultState.Pending;
  const fundingPercentage = Number(metrics.fundingProgress) / 100;
  const apy = Number(metrics.currentAPY) / 100;

  return (
    <div className="p-6 bg-white rounded-xl shadow-lg border">
      {/* Header */}
      <div className="flex justify-between items-start mb-4">
        <div>
          <h3 className="text-xl font-bold">Vault #{vaultInfo.vaultId.toString()}</h3>
          <p className="text-sm text-gray-500">
            Borrower: {vaultInfo.borrower.slice(0, 6)}...{vaultInfo.borrower.slice(-4)}
          </p>
        </div>
        <span className={`px-3 py-1 rounded-full text-sm font-medium ${
          vaultInfo.state === VaultState.Pending ? 'bg-blue-100 text-blue-800' :
          vaultInfo.state === VaultState.Funded ? 'bg-yellow-100 text-yellow-800' :
          vaultInfo.state === VaultState.Active ? 'bg-green-100 text-green-800' :
          vaultInfo.state === VaultState.Repaying ? 'bg-purple-100 text-purple-800' :
          vaultInfo.state === VaultState.Completed ? 'bg-emerald-100 text-emerald-800' :
          'bg-red-100 text-red-800'
        }`}>
          {VaultState[vaultInfo.state]}
        </span>
      </div>

      {/* Metrics */}
      <div className="grid grid-cols-2 gap-4 mb-6">
        <div className="p-3 bg-gray-50 rounded-lg">
          <p className="text-sm text-gray-500">Target Amount</p>
          <p className="text-lg font-bold">
            ${formatUnits(metrics.targetAmount, 6).toLocaleString()}
          </p>
        </div>
        <div className="p-3 bg-gray-50 rounded-lg">
          <p className="text-sm text-gray-500">APY</p>
          <p className="text-lg font-bold text-green-600">{apy}%</p>
        </div>
      </div>

      {/* Progress Bar */}
      <div className="mb-6">
        <div className="flex justify-between text-sm mb-1">
          <span>Funding Progress</span>
          <span>{fundingPercentage.toFixed(1)}%</span>
        </div>
        <div className="h-3 bg-gray-200 rounded-full overflow-hidden">
          <div 
            className="h-full bg-blue-600 rounded-full transition-all duration-500"
            style={{ width: `${Math.min(fundingPercentage, 100)}%` }}
          />
        </div>
        <p className="text-sm text-gray-500 mt-1">
          ${formatUnits(vaultInfo.totalRaised, 6)} / ${formatUnits(metrics.targetAmount, 6)} USDC
        </p>
      </div>

      {/* Investment Form */}
      {canInvest && (
        <div className="space-y-3">
          <div>
            <label className="block text-sm font-medium mb-1">Investment Amount (USDC)</label>
            <input
              type="number"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              placeholder="Enter amount..."
              className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <div className="flex gap-2">
            <button
              onClick={() => approve(amount)}
              disabled={!amount || isPending || isConfirming}
              className="flex-1 px-4 py-2 bg-gray-200 rounded-lg hover:bg-gray-300 disabled:opacity-50"
            >
              Approve
            </button>
            <button
              onClick={() => invest(amount)}
              disabled={!amount || isPending || isConfirming}
              className="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
            >
              {isPending ? 'Confirming...' : isConfirming ? 'Investing...' : 'Invest'}
            </button>
          </div>
        </div>
      )}

      {/* Access Denied */}
      {!reputation?.canInvestInVaults && (
        <div className="p-4 bg-amber-50 rounded-lg text-amber-800 text-sm">
          ⚠️ You need at least Tier 1 (Passport) to invest in vaults.
        </div>
      )}

      {/* Success Message */}
      {isSuccess && (
        <div className="mt-4 p-4 bg-green-50 rounded-lg text-green-800">
          ✅ Investment successful! You now own shares in this vault.
        </div>
      )}
    </div>
  );
}
```

---

## 🏛️ Treasury Operations

### Create Treasury (Tier 1+)

```typescript
// hooks/useCreateTreasury.ts
import { useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { TreasuryFactoryABI } from '../config/abis';
import { getContracts } from '../config/contracts';

interface CreateTreasuryParams {
  signers?: `0x${string}`[];  // Empty for single-sig
  signaturesRequired?: number; // 0 for single-sig
}

export function useCreateTreasury(chainId: number) {
  const contracts = getContracts(chainId);
  
  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess, data: receipt } = useWaitForTransactionReceipt({ hash });

  const createTreasury = async (params?: CreateTreasuryParams) => {
    const signers = params?.signers || [];
    const signaturesRequired = params?.signaturesRequired || 0;

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

## 🪝 React Hooks Summary

| Hook | Purpose | Tier Required |
|------|---------|---------------|
| `useUserReputation` | Get user's tier and permissions | None |
| `useMintPassport` | Mint Convexo_Passport NFT | None |
| `useVaultData` | Read vault information | None |
| `useCreateVault` | Create new vault | Tier 3 |
| `useInvestInVault` | Invest USDC in vault | Tier 1+ |
| `useCreateTreasury` | Create personal treasury | Tier 1+ |
| `useRedeemShares` | Redeem vault shares | Tier 1+ |
| `useContractSigner` | Sign contracts on-chain | Tier 1+ |

---

## 📱 Complete Examples

### Full Dashboard Component

```tsx
// pages/Dashboard.tsx
import { useAccount, useChainId } from 'wagmi';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useUserReputation } from '../hooks/useUserReputation';
import { ReputationBadge } from '../components/ReputationBadge';
import { AccessMatrix } from '../components/AccessMatrix';
import { MintPassport } from '../components/MintPassport';
import { VaultList } from '../components/VaultList';
import { ReputationTier } from '../types/reputation';

export function Dashboard() {
  const { address, isConnected } = useAccount();
  const chainId = useChainId();
  const { reputation, isLoading } = useUserReputation(address, chainId);

  if (!isConnected) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="text-center">
          <h1 className="text-3xl font-bold mb-6">Welcome to Convexo</h1>
          <p className="text-gray-600 mb-8">Connect your wallet to get started</p>
          <ConnectButton />
        </div>
      </div>
    );
  }

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-6xl mx-auto space-y-6">
        {/* Header */}
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-2xl font-bold">Dashboard</h1>
            <p className="text-gray-500">Welcome back!</p>
          </div>
          <ConnectButton />
        </div>

        {/* Reputation Section */}
        <div className="bg-white rounded-xl shadow p-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-xl font-semibold">Your Status</h2>
            {reputation && <ReputationBadge tier={reputation.tier} size="lg" />}
          </div>
          {reputation && <AccessMatrix reputation={reputation} />}
        </div>

        {/* Get Verified (if no NFTs) */}
        {reputation?.tier === ReputationTier.None && (
          <MintPassport />
        )}

        {/* Vault List (if Tier 1+) */}
        {reputation && reputation.tier >= ReputationTier.Passport && (
          <VaultList />
        )}

        {/* Create Vault Button (if Tier 3) */}
        {reputation?.canCreateVaults && (
          <div className="bg-gradient-to-r from-gold-500 to-amber-600 rounded-xl p-6 text-white">
            <h2 className="text-xl font-bold mb-2">🏆 Vault Creator Access</h2>
            <p className="mb-4">As a verified Vault Creator, you can create new tokenized bond vaults.</p>
            <button className="px-6 py-2 bg-white text-amber-600 rounded-lg font-semibold hover:bg-gray-100">
              Create New Vault
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
```

---

## 🔄 Breaking Changes from v2.1

### NFT Contract Renames

| Old Name | New Name | Purpose |
|----------|----------|---------|
| `Convexo_LPs` | `Limited_Partners_Individuals` | Individual LP verification |
| `Convexo_Vaults` | `Limited_Partners_Business` | Business LP verification |
| (new) | `Ecreditscoring` | Credit-scored vault creators |

### ReputationManager Changes

```typescript
// OLD (v2.1)
const tier = await reputationManager.getReputationTier(address);
// 0: None, 1: Passport, 2: LimitedPartner, 3: VaultCreator

// NEW (v2.2) - Same enum values, but different underlying NFTs:
// Tier 2 now requires LP_Individuals OR LP_Business (not old Convexo_LPs)
// Tier 3 now requires Ecreditscoring (not old Convexo_Vaults)
```

### New Functions

```typescript
// Check if user can request credit score (Tier 2 required)
canRequestCreditScore(address user) returns (bool)

// Check specific LP NFT holdings
holdsLPIndividuals(address user) returns (bool)
holdsLPBusiness(address user) returns (bool)
holdsAnyLP(address user) returns (bool)
holdsEcreditscoring(address user) returns (bool)
```

---

## 📚 Additional Resources

- [Contracts Reference](./CONTRACTS_REFERENCE.md)
- [ZKPassport Integration](./ZKPASSPORT_FRONTEND_INTEGRATION.md)
- [Deployment Addresses](./addresses.json)
- [Security Audit](./SECURITY_AUDIT.md)

---

*Last updated: January 2026 - v2.2*

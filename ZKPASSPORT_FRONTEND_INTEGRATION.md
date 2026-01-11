# ZKPassport Frontend Integration Guide

**Version 3.16** - String uniqueIdentifier support (pass SDK value directly!)  
**IPFS**: Pinata Gateway `lime-famous-condor-7.mypinata.cloud`

---

## 📋 Overview

This guide implements a **simplified process** for individual investor verification with **full IPFS metadata integration**:

1. **Step 1**: User completes ZKPassport verification (off-chain)
2. **Step 2**: Frontend creates NFT metadata and uploads to Pinata IPFS
3. **Step 3**: Frontend calls contract with verification results + IPFS metadata hash

**Key Points:**
- ✅ ZKPassport verification happens **off-chain** (simpler frontend integration)
- ✅ **IPFS Integration**: Individual NFT metadata stored on Pinata
- ✅ **Custom Gateway**: Uses `lime-famous-condor-7.mypinata.cloud` for fast access
- ✅ Contract accepts verification results as simple parameters + IPFS hash
- ✅ Much easier frontend development - no complex proof handling
- ✅ **Privacy-compliant**: Only verification traits stored (no PII)
- ✅ Grants **Tier 1 (Passport)** access - Treasury creation, Vault investments, and Uniswap V4 swaps

**Parameters Required:**
- `uniqueIdentifier` - Unique ID from ZKPassport verification
- `personhoodProof` - Personhood proof (private face match)
- `sanctionsPassed` - Boolean: Sanctions check result
- `isOver18` - Boolean: Age verification result  
- `faceMatchPassed` - Boolean: Face match verification result
- `ipfsMetadataHash` - IPFS hash for NFT metadata

---

## 🏆 Tier System Overview (v2.1)

| Tier | NFT Required | User Type | Access |
|------|--------------|-----------|--------|
| **Tier 0** | None | Unverified | No access |
| **Tier 1** | Convexo_Passport | Individual | Treasury creation + Vault investments |
| **Tier 2** | Convexo_LPs | Limited Partner | LP pools + Vault investments |
| **Tier 3** | Convexo_Vaults | Vault Creator | All above + Vault creation |

**Note:** Tier 1 (Passport) is the entry-level tier for individuals. Highest tier wins (progressive KYC).

---

## 🎨 IPFS & Pinata Integration

### Pinata Configuration

```typescript
// config/pinata.ts
export const PINATA_CONFIG = {
  gateway: 'lime-famous-condor-7.mypinata.cloud',
  apiKey: process.env.NEXT_PUBLIC_PINATA_API_KEY,
  secretKey: process.env.PINATA_SECRET_KEY,
  passportImageHash: 'bafybeiekwlyujx32cr5u3ixt5esfxhusalt5ljtrmsng74q7k45tilugh4'
};

// Build IPFS URL with custom gateway
export const buildIPFSUrl = (hash: string): string => 
  `https://${PINATA_CONFIG.gateway}/ipfs/${hash}`;
```

### NFT Metadata Creation

```typescript
// utils/passportMetadata.ts
import { PINATA_CONFIG, buildIPFSUrl } from '../config/pinata';

interface PassportTraits {
  kycVerified: boolean;
  faceMatchPassed: boolean;
  sanctionsPassed: boolean;
  isOver18: boolean;
}

export const createPassportMetadata = (tokenId: number, traits: PassportTraits) => {
  return {
    name: `Convexo Passport #${tokenId}`,
    description: "Soulbound NFT representing verified identity for Tier 1 access in the Convexo Protocol. It represents a privacy-compliant verification of identity without storing personal information. This passport enables swap and liquidity provision in gated Uniswap V4 liquidity pools, create OTC and P2P orders and lending options within the vaults created by verified lenders.",
    image: buildIPFSUrl(PINATA_CONFIG.passportImageHash),
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
  };
};

export const uploadMetadataToPinata = async (metadata: any): Promise<string> => {
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
  
  if (!response.ok) {
    throw new Error(`Pinata upload failed: ${result.error}`);
  }
  
  return result.IpfsHash;
};
```

---

## 🚀 Quick Start

### 1. Install Dependencies

```bash
npm install @zkpassport/sdk viem wagmi @rainbow-me/rainbowkit
```

### 2. Environment Setup

Create `.env.local`:

```env
NEXT_PUBLIC_APP_DOMAIN=yourdomain.com
NEXT_PUBLIC_CONVEXO_PASSPORT_ADDRESS=0x5078300fa7e2d29c2e2145beb8a6eb5ad0d45e0c
```

---

## 📝 Contract Addresses (v2.1)

### Ethereum Sepolia (Chain ID: 11155111)

| Contract | Address | Verified |
|----------|---------|----------|
| **Convexo_Passport** | `0x259adc4917c442dd9a509cb8333a9bed88fe5c70` | ✅ |
| **ReputationManager** | `0x82e856e70a0057fc6e26c17793a890ec38194cfc` | ✅ |
| **TreasuryFactory** | `0x53d38e2ca13d085d14a44b0deadc47995a82eca3` | ✅ |

### Base Sepolia (Chain ID: 84532)

| Contract | Address | Verified |
|----------|---------|----------|
| **Convexo_Passport** | `0x5078300fa7e2d29c2e2145beb8a6eb5ad0d45e0c` | ✅ |
| **ReputationManager** | `0xc8d1160e2e7719e29b34ab36402aaa0ec24d8c01` | ✅ |
| **TreasuryFactory** | `0x68ec89e0884d05d3b4d2f9b27e4212820b1a56e5` | ✅ |

### Unichain Sepolia (Chain ID: 1301)

| Contract | Address | Verified |
|----------|---------|----------|
| **Convexo_Passport** | `0xab83ce760054c1d048d5a9de5194b05398a09d41` | ✅ |
| **ReputationManager** | `0x62227ff7ccbdb4d72c3511290b28c3424f1500ef` | ✅ |
| **TreasuryFactory** | `0xecde45fefb5c2ef6e5cc615291de9be9a99b46a6` | ✅ |

### Mainnet Deployments

| Network | Convexo_Passport | TreasuryFactory |
|---------|------------------|-----------------|
| **Base Mainnet** | `0x16d8a264aa305c5b0fc2551a3baf8b8602aa1710` | `0x3738d60fcb27d719fdd5113b855e1158b93a95b1` |
| **Unichain Mainnet** | `0x04aeb36d5fa2fb0b0df8b9561d9ee88273d3bc76` | `0xd7cf4aba5b9b4877419ab8af3979da637493afb1` |
| **Ethereum Mainnet** | `0x6b51adc34a503b23db99444048ac7c2dc735a12e` | `0xd189d95ee1a126a66fc5a84934372aa0fc0bb6d2` |

---

## 📝 Step 1: Off-Chain Identity Verification

### Initialize ZKPassport

Create `lib/zkpassport.ts`:

```typescript
import { ZKPassport } from "@zkpassport/sdk";

export const zkPassport = new ZKPassport(process.env.NEXT_PUBLIC_APP_DOMAIN!);
```

### Create Verification Request

```typescript
// lib/zkpassport.ts
export async function createVerificationRequest() {
  const queryBuilder = await zkPassport.request({
    name: "Convexo Identity Verification",
    logo: "https://yourdomain.com/logo.png",
    purpose: "Verify user identity for Convexo Passport NFT",
    scope: "convexo-identity",
  });

  return queryBuilder
    .disclose("nationality")
    .disclose("birthdate")
    .disclose("fullname")
    .sanctions() // Enable sanctions screening
    .facematch("strict") // Enable face match with strict mode
    .done();
}
```

### Handle Verification Result & Get Unique Identifier

```typescript
// lib/zkpassport.ts

export interface VerificationResult {
  verified: boolean;
  result: {
    facematch: {
      passed: boolean;
    };
    sanctions: {
      passed: boolean;
    };
    disclosed: {
      nationality?: string;
      birthdate?: string;
      fullname?: string;
    };
  };
  uniqueIdentifier?: string; // The unique identifier string from ZKPassport SDK (use directly!)
}

/**
 * IMPORTANT: Use the uniqueIdentifier directly from ZKPassport SDK!
 * 
 * ZKPassport computes the uniqueIdentifier using Poseidon2 hash:
 *   uniqueIdentifier = Poseidon2(ID_data + domain + scope)
 * 
 * This ensures:
 * - Same ID + same domain + same scope = SAME identifier (sybil resistance)
 * - Different IDs = Different identifiers (unique per person)
 * - Different domains = Different identifiers (privacy between services)
 * 
 * DO NOT manually compute the identifier! Use what ZKPassport provides.
 */
export function onResult(callback: (result: VerificationResult) => void) {
  // ZKPassport SDK provides uniqueIdentifier directly as a string
  zkPassport.onResult(({ verified, result, uniqueIdentifier }) => {
    const verificationResult: VerificationResult = {
      verified,
      result: {
        facematch: {
          passed: result.facematch?.passed ?? false,
        },
        sanctions: {
          passed: result.sanctions?.passed ?? false,
        },
        disclosed: {
          nationality: result.disclosed?.nationality,
          birthdate: result.disclosed?.birthdate,
          fullname: result.disclosed?.fullname,
        },
      },
      // Use uniqueIdentifier directly as string from ZKPassport SDK!
      // DO NOT convert or hash it - the contract handles hashing internally
      uniqueIdentifier: uniqueIdentifier,
    };

    callback(verificationResult);
  });
}
```

### Verification Component

```typescript
// components/IdentityVerification.tsx
'use client';

import { useState, useEffect } from 'react';
import { createVerificationRequest, onResult, VerificationResult } from '@/lib/zkpassport';

export function IdentityVerification({ onVerified }: { onVerified: (uniqueIdentifier: string) => void }) {
  const [isVerifying, setIsVerifying] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    // Set up result handler
    onResult((result: VerificationResult) => {
      setIsVerifying(false);

      // Check all requirements
      if (!result.verified) {
        setError("Verification proof invalid");
        return;
      }

      if (!result.result.facematch.passed) {
        setError("Face match failed. Please try again.");
        return;
      }

      if (!result.result.sanctions.passed) {
        setError("Sanctions check failed. Account flagged for review.");
        return;
      }

      if (!result.uniqueIdentifier) {
        setError("Failed to extract unique identifier");
        return;
      }

      // All checks passed - proceed to mint with unique identifier
      onVerified(result.uniqueIdentifier);
    });
  }, [onVerified]);

  const startVerification = async () => {
    try {
      setIsVerifying(true);
      setError(null);

      const { url } = await createVerificationRequest();
      
      // Redirect user to ZKPassport verification
      window.location.href = url;
    } catch (err: any) {
      setError(err.message || "Failed to start verification");
      setIsVerifying(false);
    }
  };

  return (
    <div className="verification-container">
      <h2>Identity Verification</h2>
      <p>Verify your identity to mint a Convexo Passport NFT</p>

      {error && (
        <div className="alert alert-error">
          <p>{error}</p>
        </div>
      )}

      <button 
        onClick={startVerification}
        disabled={isVerifying}
        className="btn btn-primary"
      >
        {isVerifying ? 'Starting Verification...' : 'Start Identity Verification'}
      </button>

      <div className="info-box mt-4">
        <p className="text-sm"><strong>What you'll need:</strong></p>
        <ul className="text-sm list-disc list-inside mt-2">
          <li>Government-issued ID (passport or ID card)</li>
          <li>Device with camera for face match</li>
          <li>5-10 minutes to complete</li>
        </ul>
      </div>
    </div>
  );
}
```

---

## 🎫 Step 2: Mint NFT with Unique Identifier

### Contract Addresses

```typescript
// lib/constants.ts
export const CONVEXO_PASSPORT_ADDRESSES = {
  // Testnets
  11155111: '0x259adc4917c442dd9a509cb8333a9bed88fe5c70', // Ethereum Sepolia
  84532: '0x5078300fa7e2d29c2e2145beb8a6eb5ad0d45e0c', // Base Sepolia
  1301: '0xab83ce760054c1d048d5a9de5194b05398a09d41', // Unichain Sepolia
  // Mainnets
  1: '0x6b51adc34a503b23db99444048ac7c2dc735a12e', // Ethereum Mainnet
  8453: '0x16d8a264aa305c5b0fc2551a3baf8b8602aa1710', // Base Mainnet
  130: '0x04aeb36d5fa2fb0b0df8b9561d9ee88273d3bc76', // Unichain Mainnet
} as const;
```

### Mint NFT Component

```typescript
// components/MintPassportNFT.tsx
'use client';

import { useState } from 'react';
import { useAccount, useNetwork, useBalance, useContractRead, useContractWrite, useWaitForTransaction } from 'wagmi';
import { parseEther, formatEther } from 'viem';
import ConvexoPassportABI from '@/abis/Convexo_Passport.json';
import { CONVEXO_PASSPORT_ADDRESSES } from '@/lib/constants';

interface MintPassportNFTProps {
  uniqueIdentifier: string; // String from ZKPassport SDK - pass directly to contract!
}

export function MintPassportNFT({ uniqueIdentifier }: MintPassportNFTProps) {
  const { address, isConnected } = useAccount();
  const { chain } = useNetwork();
  const [error, setError] = useState<string | null>(null);

  // Get contract address
  const contractAddress = chain?.id 
    ? CONVEXO_PASSPORT_ADDRESSES[chain.id as keyof typeof CONVEXO_PASSPORT_ADDRESSES]
    : CONVEXO_PASSPORT_ADDRESSES[84532];

  // Check ETH balance
  const { data: balance } = useBalance({ address });
  const MIN_ETH_REQUIRED = parseEther('0.01');
  const hasEnoughETH = balance && balance.value >= MIN_ETH_REQUIRED;

  // Check if identifier is already used
  const { data: isIdentifierUsed } = useContractRead({
    address: contractAddress as `0x${string}`,
    abi: ConvexoPassportABI,
    functionName: 'isIdentifierUsed',
    args: [uniqueIdentifier],
    enabled: !!contractAddress && !!uniqueIdentifier,
  });

  // Check if user already has passport
  const { data: hasPassport } = useContractRead({
    address: contractAddress as `0x${string}`,
    abi: ConvexoPassportABI,
    functionName: 'holdsActivePassport',
    args: [address!],
    enabled: !!address && !!contractAddress,
  });

  // Mint NFT with unique identifier
  const { 
    write: mintPassport, 
    isLoading: isMinting,
    data: mintData,
    error: mintError,
  } = useContractWrite({
    address: contractAddress as `0x${string}`,
    abi: ConvexoPassportABI,
    functionName: 'safeMintWithVerification',
    args: [
      uniqueIdentifier,
      personhoodProof,
      sanctionsPassed,
      isOver18,
      faceMatchPassed,
      ipfsMetadataHash // New parameter for IPFS metadata
    ],
    gas: BigInt(300000), // Simpler function = less gas (~200k-300k)
    onError: (error) => {
      const errorMsg = error.message || error.toString();
      if (errorMsg.includes('AlreadyHasPassport')) {
        setError('You already have a passport NFT');
      } else if (errorMsg.includes('IdentifierAlreadyUsed')) {
        setError('This unique identifier has already been used to mint a passport');
      } else if (errorMsg.includes('insufficient funds')) {
        setError(`Insufficient ETH. Please add at least ${formatEther(MIN_ETH_REQUIRED)} ETH`);
      } else {
        setError(errorMsg);
      }
    },
  });

  // Wait for transaction
  const { isLoading: isWaiting, isSuccess } = useWaitForTransaction({
    hash: mintData?.hash,
    onSuccess: () => {
      setError(null);
    },
    onError: (error) => {
      setError('Transaction failed. Please try again.');
    },
  });

  if (!isConnected) {
    return <p>Please connect your wallet</p>;
  }

  if (!hasEnoughETH) {
    return (
      <div className="alert alert-warning">
        <p>⚠️ Insufficient ETH for gas</p>
        <p>You need at least {formatEther(MIN_ETH_REQUIRED)} ETH</p>
        <p>Current balance: {balance ? formatEther(balance.value) : '0'} ETH</p>
      </div>
    );
  }

  if (isIdentifierUsed) {
    return (
      <div className="alert alert-error">
        <p>❌ This unique identifier has already been used</p>
        <p className="text-sm">Each identity can only mint one passport NFT</p>
      </div>
    );
  }

  if (hasPassport) {
    return (
      <div className="alert alert-success">
        <p>✅ You already have an active Convexo Passport NFT</p>
        <p className="text-sm">Tier 1 access granted - you can create treasuries and invest in vaults</p>
      </div>
    );
  }

  return (
    <div className="mint-container">
      <h2>Mint Convexo Passport NFT</h2>
      
      <div className="alert alert-success mb-4">
        <p>✅ Identity verified successfully</p>
        <p className="text-sm">
          Face match: ✅ Passed | Sanctions: ✅ Passed
        </p>
        <p className="text-xs mt-2">
          Unique Identifier: {uniqueIdentifier.slice(0, 10)}...{uniqueIdentifier.slice(-8)}
        </p>
      </div>

      {error && (
        <div className="alert alert-error mb-4">
          <p>{error}</p>
        </div>
      )}

      <button
        onClick={() => mintPassport?.()}
        disabled={isMinting || isWaiting || !mintPassport}
        className="btn btn-primary w-full"
      >
        {isMinting || isWaiting 
          ? 'Minting NFT...' 
          : 'Mint Passport NFT (Tier 1)'}
      </button>

      <div className="info-box mt-4">
        <p className="text-sm"><strong>Tier 1 Benefits:</strong></p>
        <ul className="text-xs space-y-1 mt-2">
          <li>• Create personal treasuries</li>
          <li>• Invest in tokenized bond vaults</li>
          <li>• Track investments in real-time</li>
        </ul>
      </div>

      <div className="info-box mt-4">
        <p className="text-sm"><strong>Gas Information:</strong></p>
        <ul className="text-xs space-y-1 mt-2">
          <li>• Estimated: 200k - 300k gas</li>
          <li>• Cost: ~$0.01 - $0.03 (Base/Unichain)</li>
          <li>• <strong>You pay for gas</strong></li>
        </ul>
      </div>

      {isSuccess && (
        <div className="alert alert-success mt-4">
          <p>🎉 Passport NFT minted successfully!</p>
          <p className="text-sm">You now have Tier 1 access!</p>
          {mintData?.hash && (
            <a 
              href={`https://${chain?.id === 84532 ? 'sepolia.basescan.org' : chain?.id === 11155111 ? 'sepolia.etherscan.io' : chain?.id === 8453 ? 'basescan.org' : chain?.id === 1 ? 'etherscan.io' : 'unichain-sepolia.blockscout.com'}/tx/${mintData.hash}`}
              target="_blank"
              rel="noopener noreferrer"
              className="text-sm text-blue-600"
            >
              View Transaction →
            </a>
          )}
        </div>
      )}
    </div>
  );
}
```

---

## 🔄 Complete Flow Component

```typescript
// components/PassportOnboarding.tsx
'use client';

import { useState } from 'react';
import { IdentityVerification } from './IdentityVerification';
import { MintPassportNFT } from './MintPassportNFT';

export function PassportOnboarding() {
  // uniqueIdentifier is now a string from ZKPassport SDK - no conversion needed!
  const [uniqueIdentifier, setUniqueIdentifier] = useState<string | null>(null);
  const [step, setStep] = useState<'verify' | 'mint'>('verify');

  const handleVerified = (identifier: string) => {
    setUniqueIdentifier(identifier);
    setStep('mint');
  };

  return (
    <div className="onboarding-container">
      {step === 'verify' && (
        <IdentityVerification onVerified={handleVerified} />
      )}

      {step === 'mint' && uniqueIdentifier && (
        <MintPassportNFT uniqueIdentifier={uniqueIdentifier} />
      )}
    </div>
  );
}
```

---

## ✅ How It Works

### Flow Diagram

```
1. User verifies identity wVerification(uniqueIdentifier, personhoodProof, sanctionsPassed, isOver18, faceMatchPasse
   ↓
2. ZKPassport returns: publicKey + scope + verification traits
   ↓
3. Frontend calculates: uniqueIdentifier = keccak256(publicKey + scope)
   ↓
4. User calls: safeMintWithZKPassport(proofParams, isIDCard)
   ↓
5. Contract checks:
   - User doesn't have passport? ✅
   - Identifier not used? ✅
   ↓
6. Contract mints NFT with Tier 1 access
   ↓
7. Contract stores: verification traits (privacy-compliant)
   ↓
8. User can now: Create treasuries + Invest in vaults
```

### Privacy-Compliant Stored Traits

The contract stores only **verification results** (boolean traits), **NOT personal data**:

| Trait | Description | Example Value |
|-------|-------------|---------------|
| `kycVerified` | Overall KYC verification passed | `true` |
| `faceMatchPassed` | Face match verification result | `true` |
| `sanctionsPassed` | Sanctions check passed | `true` |
| `isOver18` | Age verification result | `true` |

**What is NOT stored:**
- ❌ Name, address, birthdate
- ❌ Passport/ID images
- ❌ Biometric data
- ❌ Any personally identifiable information (PII)

### Contract Enforcement

The contract enforces:
- ✅ **1 wallet = 1 passport** (checked by `balanceOf(msg.sender) > 0`)
- ✅ **1 unique identifier = 1 passport** (checked by `passportIdentifierToAddress[identifier] != address(0)`)
- ✅ **Soulbound** (cannot be transferred)
- ✅ **Privacy-compliant** (only verification traits stored)

---

## � Complete Minting Workflow with IPFS

```typescript
// components/PassportMinter.tsx
import { useState } from 'react';
import { createPassportMetadata, uploadMetadataToPinata } from '../utils/passportMetadata';

const MintPassportWithIPFS = ({ verificationResults }) => {
  const [uploading, setUploading] = useState(false);
  const [ipfsHash, setIpfsHash] = useState<string>('');
  
  const handleMintWithMetadata = async () => {
    try {
      setUploading(true);
      
      // 1. Create metadata based on verification results
      const metadata = createPassportMetadata(1, {
        kycVerified: true,
        faceMatchPassed: verificationResults.faceMatchPassed,
        sanctionsPassed: verificationResults.sanctionsPassed,
        isOver18: verificationResults.isOver18
      });
      
      // 2. Upload metadata to Pinata
      const metadataHash = await uploadMetadataToPinata(metadata);
      setIpfsHash(metadataHash);
      
      // 3. Mint NFT with IPFS hash
      await contract.safeMintWithVerification(
        verificationResults.uniqueIdentifier,
        verificationResults.personhoodProof,
        verificationResults.sanctionsPassed,
        verificationResults.isOver18,
        verificationResults.faceMatchPassed,
        metadataHash // IPFS metadata hash
      );
      
      console.log('✅ Passport minted successfully!');
      
    } catch (error) {
      console.error('❌ Minting failed:', error);
    } finally {
      setUploading(false);
    }
  };

  return (
    <div>
      <button 
        onClick={handleMintWithMetadata}
        disabled={uploading}
      >
        {uploading ? 'Uploading & Minting...' : 'Mint Passport NFT'}
      </button>
      
      {ipfsHash && (
        <div className="mt-4">
          <p>✅ Metadata uploaded to IPFS:</p>
          <a 
            href={`https://lime-famous-condor-7.mypinata.cloud/ipfs/${ipfsHash}`}
            target="_blank"
            rel="noopener noreferrer"
            className="text-blue-500 underline"
          >
            View Metadata
          </a>
        </div>
      )}
    </div>
  );
};
```

---

## �🔧 Contract Functions

### Simplified Contract Interface

```solidity
// uniqueIdentifier is passed directly as string from ZKPassport SDK
// Contract hashes it internally with keccak256 for storage efficiency
function safeMintWithVerification(
    string calldata uniqueIdentifier, // Use string directly from ZKPassport SDK!
    bytes32 personhoodProof,          // Personhood proof (nullifier)
    bool sanctionsPassed,             // Sanctions check result
    bool isOver18,                    // Age verification result  
    bool faceMatchPassed,             // Face match result
    string calldata ipfsMetadataHash  // IPFS hash for NFT metadata
) external returns (uint256 tokenId) {
    // Check if user already has a passport
    if (balanceOf(msg.sender) > 0) {
        revert AlreadyHasPassport();
    }

    // Hash identifier for storage (contract handles this internally)
    bytes32 identifierHash = keccak256(bytes(uniqueIdentifier));

    // Check if identifier has been used (sybil resistance)
    if (passportIdentifierToAddress[identifierHash] != address(0)) {
        revert IdentifierAlreadyUsed();
    }

    // Set IPFS metadata URI
    if (bytes(ipfsMetadataHash).length > 0) {
        _setTokenURI(tokenId, string(abi.encodePacked(
            "https://lime-famous-condor-7.mypinata.cloud/ipfs/", 
            ipfsMetadataHash
        )));
    }

    // Mint NFT and store verification traits (no complex proof verification)
    // ...
}
```

### Self-Mint with ZKPassport Proof (On-Chain Verification)

```solidity
function safeMintWithZKPassport(
    ProofVerificationParams calldata params,
    bool isIDCard
) external returns (uint256 tokenId) {
    // Verify proof on-chain via ZKPassport verifier
    (bool success, DisclosedData memory disclosedData) = zkPassportVerifier.verifyProof(params, isIDCard);
    
    // Store actual verification results from ZKPassport
    // Stores: kycVerified, faceMatchPassed, sanctionsPassed, isOver18
    // ...
}
```

### Get Verified Identity

```solidity
function getVerifiedIdentity(address holder) external view returns (VerifiedIdentity memory) {
    return verifiedUsers[holder];
}

// Returns:
struct VerifiedIdentity {
    bytes32 identifierHash;        // keccak256 hash of uniqueIdentifier string
    bytes32 personhoodProof;       // Nullifier from ZKPassport
    uint256 verifiedAt;            // Contract verification timestamp
    uint256 zkPassportTimestamp;   // Original ZKPassport verification time
    bool isActive;                 // Passport active status
    bool kycVerified;              // KYC passed
    bool faceMatchPassed;          // Face match passed
    bool sanctionsPassed;          // Sanctions check passed
    bool isOver18;                 // Age verification passed
}
```

**Benefits:**
- ✅ No on-chain proof verification needed (for simplified flow)
- ✅ Privacy-compliant (only traits stored)
- ✅ Same security (1 wallet = 1 identifier)
- ✅ Faster transactions

---

## 📊 Gas Requirements

### Gas Estimates (Simplified Function)

- **Base Gas**: 21,000
- **NFT Mint**: 50,000
- **Storage Operations**: 100,000
- **Total Estimated**: 200,000
- **Recommended (with buffer)**: 300,000

### Network Costs

| Network | Estimated Cost |
|---------|---------------|
| **Base Sepolia** | ~$0.01 - $0.03 |
| **Base Mainnet** | ~$0.01 - $0.03 |
| **Unichain** | ~$0.01 - $0.03 |
| **Ethereum Sepolia** | ~$0.30 - $0.60 |
| **Ethereum Mainnet** | ~$2 - $5 |

**⚠️ User pays for gas - always check balance before minting**

---

## 🚨 Error Handling

### Common Errors

```typescript
- 'AlreadyHasPassport' → User already has NFT
- 'IdentifierAlreadyUsed' → This identity already minted
- 'SoulboundTokenCannotBeTransferred' → Cannot transfer passport
- 'insufficient funds' → Need more ETH for gas
```

### Frontend Checks

Before minting, check:
1. ✅ User has enough ETH
2. ✅ Identifier is not already used
3. ✅ User doesn't already have passport

---

## 🔍 Troubleshooting

### Issue: "Identifier already used"

**Solution**: Each unique identifier can only mint once. If you've already minted, you cannot mint again with the same identifier.

### Issue: "Already have passport"

**Solution**: Check your wallet - you may already own the NFT.

### Issue: Verification fails

**Solutions:**
1. Check ZKPassport app is installed
2. Verify app domain is correct
3. Ensure camera permissions are granted
4. Try again with better lighting

### Issue: "Soulbound token cannot be transferred"

**Solution**: Passport NFTs are soulbound (non-transferable). This is by design.

---

## 📋 Integration Checklist

- [ ] Install `@zkpassport/sdk`
- [ ] Set up environment variables
- [ ] Initialize ZKPassport with app domain
- [ ] Create verification request function
- [ ] Use `uniqueIdentifier` directly from ZKPassport callback (DO NOT compute manually!)
- [ ] Create verification component
- [ ] Create mint NFT component
- [ ] Add ETH balance check
- [ ] Add identifier usage check
- [ ] Implement error handling
- [ ] Test verification flow
- [ ] Test minting flow
- [ ] Verify no sensitive data is stored

---

## 📚 Additional Resources

- **ZKPassport Docs**: https://docs.zkpassport.id/
- **Contract ABIs**: `abis/Convexo_Passport.json`
- **Main Frontend Guide**: `FRONTEND_INTEGRATION.md`
- **Contracts Reference**: `CONTRACTS_REFERENCE.md`

---

## 🎯 Key Advantages of This Approach

1. ✅ **Privacy-First**: Only verification traits stored, no PII
2. ✅ **Simpler**: No complex on-chain proof verification (for simplified flow)
3. ✅ **Cheaper**: Lower gas costs (~200k vs ~500k)
4. ✅ **Faster**: No verifier contract calls (for simplified flow)
5. ✅ **Secure**: Still enforces 1 wallet = 1 identifier
6. ✅ **Soulbound**: NFT cannot be transferred
7. ✅ **Progressive KYC**: Can upgrade to higher tiers later

---

## 🆕 What's New in v2.1

### Tier System Changes
- **Passport is now Tier 1** (previously Tier 3)
- **LPs is now Tier 2** (previously Tier 1)
- **Vaults is now Tier 3** (previously Tier 2)
- **Highest tier wins** (no mutual exclusivity)

### New Features
- ✅ **TreasuryFactory**: Tier 1+ can create treasuries
- ✅ **Privacy-compliant traits**: Only verification results stored
- ✅ **Progressive KYC**: Start as individual, upgrade to business

### Benefits for Passport Holders (Tier 1)
- ✅ Create personal treasuries (new!)
- ✅ Invest in tokenized bond vaults
- ✅ Upgrade to Tier 2/3 via Veriff verification

---

**Last Updated**: v2.1 - Simplified Identifier-Based Minting with Privacy-Compliant Traits

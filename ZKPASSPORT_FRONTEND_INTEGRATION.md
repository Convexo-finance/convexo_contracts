# ZKPassport Frontend Integration Guide

**Simplified guide: Off-chain verification + On-chain minting with unique identifier**

---

## 📋 Overview

This guide implements a **simplified two-step process**:

1. **Step 1**: Identity verification with ZKPassport (OFF-CHAIN) → Get unique identifier
2. **Step 2**: Mint Convexo Passport NFT (ON-CHAIN) → Provide unique identifier

**Key Points:**
- ✅ ZKPassport verification happens **off-chain** (no on-chain proof verification)
- ✅ User gets a **unique identifier** from ZKPassport
- ✅ User mints NFT by providing the unique identifier
- ✅ Contract enforces: **1 wallet = 1 unique identifier**
- ✅ Users pay for gas fees
- ✅ No storage of ID images or biometric data

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
NEXT_PUBLIC_CONVEXO_PASSPORT_ADDRESS=0x4A164470586B7e80eEf2734d24f5F784e4f88ad0
```

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

### Handle Verification Result & Extract Unique Identifier

```typescript
// lib/zkpassport.ts
import { keccak256, toBytes, toHex } from 'viem';

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
  uniqueIdentifier?: `0x${string}`; // The unique identifier for minting
}

// Extract unique identifier from ZKPassport proof
export function extractUniqueIdentifier(proof: any): `0x${string}` {
  // ZKPassport provides publicKey and scope
  // Unique identifier = keccak256(publicKey + scope)
  const publicKey = proof.publicKey.startsWith('0x') 
    ? proof.publicKey 
    : `0x${proof.publicKey}`;
  
  const scope = proof.scope.startsWith('0x')
    ? proof.scope
    : `0x${proof.scope}`;

  // Generate unique identifier (same as contract does)
  const uniqueIdentifier = keccak256(
    toBytes(publicKey + scope.slice(2)) // Concatenate without 0x prefix
  ) as `0x${string}`;

  return uniqueIdentifier;
}

export function onResult(callback: (result: VerificationResult) => void) {
  zkPassport.onResult(({ verified, result, proof }) => {
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
      uniqueIdentifier: proof ? extractUniqueIdentifier(proof) : undefined,
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

export function IdentityVerification({ onVerified }: { onVerified: (uniqueIdentifier: `0x${string}`) => void }) {
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
  11155111: '0x2cfa02372782cf20ef8342B0193fd69E4c5B04A8', // Ethereum Sepolia
  84532: '0x4A164470586B7e80eEf2734d24f5F784e4f88ad0', // Base Sepolia
  1301: '0xB612DB1FE343C4B5FFa9e8C3f4dde37769F7C5B6', // Unichain Sepolia
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
  uniqueIdentifier: `0x${string}`;
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
    functionName: 'safeMintWithIdentifier',
    args: [uniqueIdentifier],
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
          : 'Mint Passport NFT'}
      </button>

      <div className="info-box mt-4">
        <p className="text-sm"><strong>Gas Information:</strong></p>
        <ul className="text-xs space-y-1 mt-2">
          <li>• Estimated: 200k - 300k gas (simpler function)</li>
          <li>• Cost: ~$0.01 - $0.03 (Base Sepolia)</li>
          <li>• <strong>You pay for gas</strong></li>
        </ul>
      </div>

      {isSuccess && (
        <div className="alert alert-success mt-4">
          <p>🎉 Passport NFT minted successfully!</p>
          {mintData?.hash && (
            <a 
              href={`https://${chain?.id === 84532 ? 'sepolia.basescan.org' : chain?.id === 11155111 ? 'sepolia.etherscan.io' : 'unichain-sepolia.blockscout.com'}/tx/${mintData.hash}`}
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
  const [uniqueIdentifier, setUniqueIdentifier] = useState<`0x${string}` | null>(null);
  const [step, setStep] = useState<'verify' | 'mint'>('verify');

  const handleVerified = (identifier: `0x${string}`) => {
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
1. User verifies identity with ZKPassport (OFF-CHAIN)
   ↓
2. ZKPassport returns: publicKey + scope
   ↓
3. Frontend calculates: uniqueIdentifier = keccak256(publicKey + scope)
   ↓
4. User calls: safeMintWithIdentifier(uniqueIdentifier)
   ↓
5. Contract checks:
   - User doesn't have passport? ✅
   - Identifier not used? ✅
   ↓
6. Contract mints NFT
   ↓
7. Contract stores: wallet → uniqueIdentifier (1:1 mapping)
```

### Contract Enforcement

The contract enforces:
- ✅ **1 wallet = 1 passport** (checked by `balanceOf(msg.sender) > 0`)
- ✅ **1 unique identifier = 1 passport** (checked by `passportIdentifierToAddress[identifier] != address(0)`)
- ✅ **1 wallet = 1 unique identifier** (mapping stores identifier → wallet)

---

## 🔧 Contract Function

### New Simplified Function

```solidity
function safeMintWithIdentifier(bytes32 uniqueIdentifier) external returns (uint256 tokenId) {
    // Check if user already has a passport
    if (balanceOf(msg.sender) > 0) {
        revert AlreadyHasPassport();
    }

    // Check if identifier has been used (prevents duplicate passports)
    if (passportIdentifierToAddress[uniqueIdentifier] != address(0)) {
        revert IdentifierAlreadyUsed();
    }

    // Mint NFT, store identifier, emit event
    // ...
}
```

**Benefits:**
- ✅ No on-chain proof verification (cheaper gas)
- ✅ Simpler implementation
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

- **Base Sepolia**: ~$0.01 - $0.03 (much cheaper!)
- **Ethereum Sepolia**: ~$0.30 - $0.60
- **Unichain Sepolia**: ~$0.01 - $0.03

**⚠️ User pays for gas - always check balance before minting**

---

## 🚨 Error Handling

### Common Errors

```typescript
- 'AlreadyHasPassport' → User already has NFT
- 'IdentifierAlreadyUsed' → This identity already minted
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

---

## 📋 Integration Checklist

- [ ] Install `@zkpassport/sdk`
- [ ] Set up environment variables
- [ ] Initialize ZKPassport with app domain
- [ ] Create verification request function
- [ ] Implement `extractUniqueIdentifier()` helper
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

---

## 🎯 Key Advantages of This Approach

1. ✅ **Simpler**: No complex on-chain proof verification
2. ✅ **Cheaper**: Lower gas costs (~200k vs ~500k)
3. ✅ **Faster**: No verifier contract calls
4. ✅ **Secure**: Still enforces 1 wallet = 1 identifier
5. ✅ **Flexible**: Verification happens off-chain, minting on-chain

---

**Last Updated**: v2.1 - Simplified Identifier-Based Minting

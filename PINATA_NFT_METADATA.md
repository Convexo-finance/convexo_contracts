# NFT Metadata Structure for Convexo Protocol

This document describes the metadata structure for Convexo Protocol NFTs stored on IPFS via Pinata.

## Pinata Configuration

- **Gateway**: `lime-famous-condor-7.mypinata.cloud`
- **API Key**: Configured in `.env` file
- **Secret Key**: Configured in `.env` file

## Available IPFS Images

### 1. Convexo Passport NFT
- **File**: `convexo_passport.png`
- **IPFS Hash**: `bafybeiekwlyujx32cr5u3ixt5esfxhusalt5ljtrmsng74q7k45tilugh4`
- **URL**: `https://lime-famous-condor-7.mypinata.cloud/ipfs/bafybeiekwlyujx32cr5u3ixt5esfxhusalt5ljtrmsng74q7k45tilugh4`
- **Usage**: Tier 1 (Individual Investor - KYC Verified)

### 2. Limited Partners Business NFT
- **File**: `convexo_lps_business.png`
- **IPFS Hash**: `bafkreiejesvgsvohwvv7q5twszrbu5z6dnpke6sg5cdiwgn2rq7dilu33m`
- **URL**: `https://lime-famous-condor-7.mypinata.cloud/ipfs/bafkreiejesvgsvohwvv7q5twszrbu5z6dnpke6sg5cdiwgn2rq7dilu33m`
- **Usage**: Tier 2 (Business Limited Partner)

### 3. Limited Partners Individual NFT
- **File**: `convexo_lps_persona.png`
- **IPFS Hash**: `bafkreib7mkjzpdm3id6st6d5vsxpn7v5h6sxeiswejjmrbcb5yoagaf4em`
- **URL**: `https://lime-famous-condor-7.mypinata.cloud/ipfs/bafkreib7mkjzpdm3id6st6d5vsxpn7v5h6sxeiswejjmrbcb5yoagaf4em`
- **Usage**: Tier 2 (Individual Limited Partner)

## Metadata JSON Structure

### Convexo Passport Metadata Example

```json
{
  "name": "Convexo Passport #1",
  "description": "Soulbound NFT representing verified identity for Tier 1 access in the Convexo Protocol. It represents a privacy-compliant verification of identity without storing personal information. This passport enables swap and liquidity provision in gated Uniswap V4 liquidity pools, create OTC and P2P orders and lending options within the vaults created by verified lenders.",
  "image": "https://lime-famous-condor-7.mypinata.cloud/ipfs/bafybeiekwlyujx32cr5u3ixt5esfxhusalt5ljtrmsng74q7k45tilugh4",
  "external_url": "https://convexo.io",
  "attributes": [
    {
      "trait_type": "Tier",
      "value": "1"
    },
    {
      "trait_type": "Type",
      "value": "Passport"
    },
    {
      "trait_type": "KYC Verified",
      "value": "Yes"
    },
    {
      "trait_type": "Face Match Passed",
      "value": "Yes"
    },
    {
      "trait_type": "Sanctions Check Passed",
      "value": "Yes"
    },
    {
      "trait_type": "Age Verification",
      "value": "18+"
    },
    {
      "trait_type": "Soulbound",
      "value": "True"
    },
    {
      "trait_type": "Network Access",
      "value": "LP Pools"
    },
    {
      "trait_type": "Verification Method",
      "value": "ZKPassport"
    }
  ]
}
```

### Limited Partners Business Metadata Example

```json
{
  "name": "Convexo LP Business #1",
  "description": "Soulbound Business Limited Partner NFT for institutional verified through Sumsub KYB verification in the Convexo Protocol. Provides Tier 2 access to Credit Score requests, monetization to trade local stablecoins to FIAT, and compliant protocol features.",
  "image": "https://lime-famous-condor-7.mypinata.cloud/ipfs/bafkreiejesvgsvohwvv7q5twszrbu5z6dnpke6sg5cdiwgn2rq7dilu33m",
  "external_url": "https://convexo.io",
  "attributes": [
    {
      "trait_type": "Tier",
      "value": "2"
    },
    {
      "trait_type": "Type",
      "value": "Business LP"
    },
    {
      "trait_type": "Entity Type",
      "value": "Business"
    },
    {
      "trait_type": "Verification Level",
      "value": "Enhanced"
    },
    {
      "trait_type": "Vault Creation",
      "value": "Enabled"
    },
    {
      "trait_type": "Network Access",
      "value": "Full Protocol"
    },
    {
      "trait_type": "Credit Scoring",
      "value": "Eligible"
    }
  ]
}
```

### Limited Partners Individual Metadata Example

```json
{
  "name": "Convexo LP Individual #1",
  "description": "Soulbound Individual Limited Partner NFT for Personas verified through Veriff KYC verification in the Convexo Protocol. Provides Tier 2 access to Credit Score requests, monetization to trade local stablecoins to FIAT, and compliant protocol features.",
  "image": "https://lime-famous-condor-7.mypinata.cloud/ipfs/bafkreib7mkjzpdm3id6st6d5vsxpn7v5h6sxeiswejjmrbcb5yoagaf4em",
  "external_url": "https://convexo.io",
  "attributes": [
    {
      "trait_type": "Tier",
      "value": "2"
    },
    {
      "trait_type": "Type",
      "value": "Individual LP"
    },
    {
      "trait_type": "Entity Type",
      "value": "Individual"
    },
    {
      "trait_type": "Verification Level",
      "value": "Enhanced"
    },
    {
      "trait_type": "Vault Creation",
      "value": "Enabled"
    },
    {
      "trait_type": "Network Access",
      "value": "Full Protocol"
    },
    {
      "trait_type": "Accredited Status",
      "value": "Verified"
    }
  ]
}
```

### Credit Score NFT Metadata Example

```json
{
  "name": "Convexo Credit Score #1",
  "description": "Soulbound AI-powered Credit Score NFT for borrowers in the Convexo Protocol. After a comprehensive creditworthiness assessment, this NFT grants Tier 3 access to Vaults and advanced Borrow and Lending features and institutional-grade protocol participation.",
  "image": "https://lime-famous-condor-7.mypinata.cloud/ipfs/bafkreignxas6gqi7it5ng6muoykujxlgxxc4g7rr6sqvwgdfwveqf2zw3e",
  "external_url": "https://convexo.io",
  "attributes": [
    {
      "trait_type": "Tier",
      "value": "3"
    },
    {
      "trait_type": "Type", 
      "value": "Credit Score"
    },
    {
      "trait_type": "Credit Score",
      "value": "85"
    },
    {
      "trait_type": "Max Loan Amount (USDC)",
      "value": "100000"
    },
    {
      "trait_type": "Credit Tier",
      "value": "Gold"
    },
    {
      "trait_type": "AI Assessment",
      "value": "Complete"
    },
    {
      "trait_type": "Soulbound",
      "value": "True"
    },
    {
      "trait_type": "Access Level",
      "value": "Vault Creation"
    },
    {
      "trait_type": "Verification Method",
      "value": "AI Credit Analysis"
    }
  ]
}
```

## Implementation Notes

### Frontend Integration

When minting NFTs, the frontend should:

1. **Upload Metadata to IPFS**: Create the metadata JSON and upload to Pinata
2. **Get IPFS Hash**: Receive the hash from Pinata API
3. **Call Contract**: Use the metadata hash in the minting function

```javascript
// Example frontend implementation
const mintPassport = async (verificationData, metadataHash) => {
  const tx = await contract.safeMintWithVerification(
    verificationData.uniqueIdentifier,
    verificationData.personhoodProof,
    verificationData.sanctionsPassed,
    verificationData.isOver18,
    verificationData.faceMatchPassed,
    metadataHash // IPFS hash from Pinata
  );
  return tx;
};
```

### Dynamic Metadata

For dynamic traits (like credit scores), consider:

1. **Base Metadata**: Static information (name, description, image)
2. **Dynamic Attributes**: Updated through separate IPFS files
3. **Metadata Refresh**: OpenSea and other platforms can refresh metadata

### Security Considerations

- **IPFS Pinning**: Ensure metadata is permanently pinned on Pinata
- **Gateway Redundancy**: Consider multiple gateway options
- **Hash Verification**: Validate IPFS hashes before contract calls
- **Rate Limiting**: Implement proper rate limiting for Pinata API calls

## Contract Functions

### Minting with IPFS

```solidity
// uniqueIdentifier is passed directly as string from ZKPassport SDK
// Contract hashes it internally with keccak256 for storage efficiency
function safeMintWithVerification(
    string calldata uniqueIdentifier, // Use string directly from ZKPassport SDK!
    bytes32 personhoodProof,
    bool sanctionsPassed,
    bool isOver18,
    bool faceMatchPassed,
    string calldata ipfsMetadataHash
) external returns (uint256 tokenId)
```

### Updating Base URI (Admin Only)

```solidity
function setBaseURI(string memory newBaseURI) external onlyRole(DEFAULT_ADMIN_ROLE)
```

The contract automatically constructs the full URL: `https://lime-famous-condor-7.mypinata.cloud/ipfs/{hash}`
# Convexo Frontend Integration Guide

## 🎯 Quick Start for Frontend Development

All contracts are deployed, tested, and verified on **Base Sepolia (Chain ID: 84532)**.

---

## 📝 Deployed Contract Addresses

### Base Sepolia (Chain ID: 84532)

| Contract | Address | Verified |
|----------|---------|----------|
| **Convexo_LPs** (NFT) | `0x4ACB3B523889f437D9FfEe9F2A50BBBa9580198d` | ✅ [View](https://sepolia.basescan.org/address/0x4ACB3B523889f437D9FfEe9F2A50BBBa9580198d) |
| **Convexo_Vaults** (NFT) | `0xc056c0Ddf959b8b63fb6Bc73b5E79e85a6bFB9b5` | ✅ [View](https://sepolia.basescan.org/address/0xc056c0Ddf959b8b63fb6Bc73b5E79e85a6bFB9b5) |
| **PoolRegistry** | `0xC0561AB6dB7762Cf81a6b1E54394551e9124Df50` | ✅ [View](https://sepolia.basescan.org/address/0xC0561AB6dB7762Cf81a6b1E54394551e9124Df50) |
| **PriceFeedManager** | `0x98E1F6d3Fd8b1EA91a24A43FD84f2F6B9f4EaEb2` | ✅ [View](https://sepolia.basescan.org/address/0x98E1F6d3Fd8b1EA91a24A43FD84f2F6B9f4EaEb2) |
| **ContractSigner** | `0x87af0C8203C84192dBf07f4B6D934fD00eB3F723` | ✅ [View](https://sepolia.basescan.org/address/0x87af0C8203C84192dBf07f4B6D934fD00eB3F723) |
| **ReputationManager** | `0x99612857Bb85b1de04d06385E44Fa53DC2aF79E1` | ✅ [View](https://sepolia.basescan.org/address/0x99612857Bb85b1de04d06385E44Fa53DC2aF79E1) |
| **VaultFactory** | `0xDe8daB3182426234ACf68E4197A1eDF5172450dD` | ✅ [View](https://sepolia.basescan.org/address/0xDe8daB3182426234ACf68E4197A1eDF5172450dD) |
| **InvoiceFactoring** | `0xbc4023284D789D7EB8512c1EDe245C77591a5D96` | ✅ [View](https://sepolia.basescan.org/address/0xbc4023284D789D7EB8512c1EDe245C77591a5D96) |
| **TokenizedBondCredits** | `0xC058588A8D82B2E2129119B209c80af8bF3d4961` | ✅ [View](https://sepolia.basescan.org/address/0xC058588A8D82B2E2129119B209c80af8bF3d4961) |

### Other Networks

| Network | Convexo_LPs | Convexo_Vaults | Status |
|---------|-------------|----------------|--------|
| **Unichain Sepolia** (1301) | `0x4ACB3B523889f437D9FfEe9F2A50BBBa9580198d` | `0xc056c0Ddf959b8b63fb6Bc73b5E79e85a6bFB9b5` | NFTs only |
| **Ethereum Sepolia** (11155111) | `0x4ACB3B523889f437D9FfEe9F2A50BBBa9580198d` | `0xc056c0Ddf959b8b63fb6Bc73b5E79e85a6bFB9b5` | NFTs only |

---

## 📦 ABIs Location

All contract ABIs are available in the `abis/` directory:

```
abis/
├── Convexo_LPs.json
├── Convexo_Vaults.json
├── PoolRegistry.json
├── PriceFeedManager.json
├── ContractSigner.json
├── ReputationManager.json
├── VaultFactory.json
├── TokenizedBondVault.json
├── InvoiceFactoring.json
├── TokenizedBondCredits.json
├── CompliantLPHook.json
└── combined.json (all ABIs in one file)
```

---

## 🔧 Frontend Setup

### 1. Install Dependencies

```bash
npm install viem wagmi @rainbow-me/rainbowkit
# or
yarn add viem wagmi @rainbow-me/rainbowkit
```

### 2. Import Contract Addresses

```typescript
// contracts/addresses.ts
export const CONTRACTS = {
  BASE_SEPOLIA: {
    CHAIN_ID: 84532,
    CONVEXO_LPS: '0x4ACB3B523889f437D9FfEe9F2A50BBBa9580198d',
    CONVEXO_VAULTS: '0xc056c0Ddf959b8b63fb6Bc73b5E79e85a6bFB9b5',
    POOL_REGISTRY: '0xC0561AB6dB7762Cf81a6b1E54394551e9124Df50',
    PRICE_FEED_MANAGER: '0x98E1F6d3Fd8b1EA91a24A43FD84f2F6B9f4EaEb2',
    CONTRACT_SIGNER: '0x87af0C8203C84192dBf07f4B6D934fD00eB3F723',
    REPUTATION_MANAGER: '0x99612857Bb85b1de04d06385E44Fa53DC2aF79E1',
    VAULT_FACTORY: '0xDe8daB3182426234ACf68E4197A1eDF5172450dD',
    INVOICE_FACTORING: '0xbc4023284D789D7EB8512c1EDe245C77591a5D96',
    TOKENIZED_BOND_CREDITS: '0xC058588A8D82B2E2129119B209c80af8bF3d4961',
  },
} as const;
```

### 3. Import ABIs

```typescript
// contracts/abis.ts
import ConvexoLPsABI from '../abis/Convexo_LPs.json';
import ConvexoVaultsABI from '../abis/Convexo_Vaults.json';
import ReputationManagerABI from '../abis/ReputationManager.json';
import VaultFactoryABI from '../abis/VaultFactory.json';
import TokenizedBondVaultABI from '../abis/TokenizedBondVault.json';
// ... import other ABIs as needed

export {
  ConvexoLPsABI,
  ConvexoVaultsABI,
  ReputationManagerABI,
  VaultFactoryABI,
  TokenizedBondVaultABI,
};
```

---

## 🎨 Key Frontend Features to Implement

### 1. User Reputation Check

```typescript
import { useContractRead } from 'wagmi';
import { CONTRACTS } from './contracts/addresses';
import { ReputationManagerABI } from './contracts/abis';

function useUserReputation(address: `0x${string}` | undefined) {
  const { data: tier } = useContractRead({
    address: CONTRACTS.BASE_SEPOLIA.REPUTATION_MANAGER,
    abi: ReputationManagerABI,
    functionName: 'getReputationTier',
    args: address ? [address] : undefined,
    enabled: !!address,
  });

  return {
    tier, // 0 = None, 1 = Compliant, 2 = Creditscore
    hasCompliantAccess: tier && tier >= 1,
    hasCreditscoreAccess: tier && tier >= 2,
  };
}
```

### 2. Check NFT Ownership

```typescript
function useNFTOwnership(address: `0x${string}` | undefined) {
  const { data: lpsBalance } = useContractRead({
    address: CONTRACTS.BASE_SEPOLIA.CONVEXO_LPS,
    abi: ConvexoLPsABI,
    functionName: 'balanceOf',
    args: address ? [address] : undefined,
  });

  const { data: vaultsBalance } = useContractRead({
    address: CONTRACTS.BASE_SEPOLIA.CONVEXO_VAULTS,
    abi: ConvexoVaultsABI,
    functionName: 'balanceOf',
    args: address ? [address] : undefined,
  });

  return {
    hasLPsNFT: lpsBalance && lpsBalance > 0n,
    hasVaultsNFT: vaultsBalance && vaultsBalance > 0n,
  };
}
```

### 3. Vault Investment Interface

```typescript
function VaultInvestmentCard({ vaultAddress }: { vaultAddress: `0x${string}` }) {
  const { data: metrics } = useContractRead({
    address: vaultAddress,
    abi: TokenizedBondVaultABI,
    functionName: 'getVaultMetrics',
  });

  const { data: userReturns } = useContractRead({
    address: vaultAddress,
    abi: TokenizedBondVaultABI,
    functionName: 'getInvestorReturn',
    args: [userAddress],
  });

  if (!metrics) return null;

  const [totalShares, sharePrice, tvl, target, progress, apy] = metrics;

  return (
    <div className="vault-card">
      <h3>Vault Investment</h3>
      <p>TVL: {formatUnits(tvl, 6)} USDC</p>
      <p>APY: {Number(apy) / 100}%</p>
      <p>Progress: {Number(progress) / 100}%</p>
      
      {userReturns && (
        <div>
          <p>Your Investment: {formatUnits(userReturns[0], 6)} USDC</p>
          <p>Current Value: {formatUnits(userReturns[1], 6)} USDC</p>
          <p>Profit: {formatUnits(userReturns[2], 6)} USDC</p>
        </div>
      )}
    </div>
  );
}
```

### 4. Purchase Vault Shares

```typescript
function usePurchaseShares(vaultAddress: `0x${string}`) {
  const { config } = usePrepareContractWrite({
    address: vaultAddress,
    abi: TokenizedBondVaultABI,
    functionName: 'purchaseShares',
    args: [parseUnits('1000', 6)], // 1000 USDC
  });

  const { write, isLoading } = useContractWrite(config);

  return { purchaseShares: write, isLoading };
}
```

---

## 🔑 Key User Flows

### Flow 1: Check User Access (For Pool Trading)

```typescript
// 1. Check reputation tier
const reputation = useUserReputation(address);

// 2. Display access level
if (reputation.tier === 0) {
  return <p>❌ No access - Apply for KYB verification</p>;
} else if (reputation.tier === 1) {
  return <p>✅ Compliant - Can trade in pools & create invoices</p>;
} else if (reputation.tier === 2) {
  return <p>✅ Creditscore - Full access to all products</p>;
}
```

### Flow 2: Browse & Invest in Vaults

```typescript
// 1. Get all vaults from VaultFactory
const { data: vaultCount } = useContractRead({
  address: CONTRACTS.BASE_SEPOLIA.VAULT_FACTORY,
  abi: VaultFactoryABI,
  functionName: 'getVaultCount',
});

// 2. Get each vault address
const vaults = Array.from({ length: Number(vaultCount) }, (_, i) => 
  useContractRead({
    address: CONTRACTS.BASE_SEPOLIA.VAULT_FACTORY,
    abi: VaultFactoryABI,
    functionName: 'getVault',
    args: [BigInt(i)],
  })
);

// 3. Display vault cards with metrics
{vaults.map(vault => <VaultInvestmentCard vaultAddress={vault.data} />)}
```

### Flow 3: Create Invoice (Tier 1+)

```typescript
function CreateInvoiceForm() {
  const { write: createInvoice } = useContractWrite({
    address: CONTRACTS.BASE_SEPOLIA.INVOICE_FACTORING,
    abi: InvoiceFactoringABI,
    functionName: 'createInvoice',
    args: [
      issuerAddress,
      parseUnits('100000', 6), // 100k USDC
      Math.floor(Date.now() / 1000) + 60 * 60 * 24 * 60, // 60 days
      contractHash,
    ],
  });

  return (
    <form onSubmit={() => createInvoice?.()}>
      {/* Form fields */}
    </form>
  );
}
```

---

## 📊 Dashboard Components to Build

### 1. User Dashboard

- **NFT Status**: Show if user has Convexo_LPs and/or Convexo_Vaults NFT
- **Reputation Tier**: Display tier and access level
- **Portfolio**: Show all vault investments with real-time returns
- **Active Invoices**: List invoices for Tier 1 users
- **Credits**: List bond credits for Tier 2 users

### 2. Vault Marketplace

- **Browse Vaults**: Display all available vaults with:
  - TVL
  - APY
  - Funding progress
  - Maturity date
  - Risk level
- **Filter Options**: By APY, risk, maturity
- **Invest Modal**: Amount input + approval flow

### 3. Admin Dashboard (if applicable)

- **Mint NFTs**: Interface to mint Convexo_LPs and Convexo_Vaults
- **Manage Pools**: Register/deregister pools
- **Price Feeds**: Configure Chainlink price feeds
- **Contract Signing**: Manage multi-sig contracts

---

## 🌐 Network Configuration

### Base Sepolia RPC

```typescript
import { defineChain } from 'viem';

export const baseSepolia = defineChain({
  id: 84532,
  name: 'Base Sepolia',
  network: 'base-sepolia',
  nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 },
  rpcUrls: {
    default: { http: ['https://sepolia.base.org'] },
    public: { http: ['https://sepolia.base.org'] },
  },
  blockExplorers: {
    default: { name: 'BaseScan', url: 'https://sepolia.basescan.org' },
  },
  testnet: true,
});
```

---

## 🔐 USDC Contract

Base Sepolia USDC: `0x036CbD53842c5426634e7929541eC2318f3dCF7e`

### Get Test USDC

1. Visit [Base Sepolia Faucet](https://www.coinbase.com/faucets/base-ethereum-goerli-faucet)
2. Get test ETH for gas
3. Swap for USDC on testnet DEX or mint from faucet

---

## 🎯 Testing Checklist

### For Frontend Developers:

- [ ] Connect wallet to Base Sepolia
- [ ] Check user reputation tier
- [ ] Display NFT ownership status
- [ ] List all available vaults
- [ ] Show vault metrics (TVL, APY, etc.)
- [ ] Approve USDC spending
- [ ] Purchase vault shares
- [ ] Display user's investment returns
- [ ] Test invoice creation (if Tier 1+)
- [ ] Test bond credit application (if Tier 2)

### Test Accounts Needed:

1. **No NFT Account**: Test restricted access
2. **Tier 1 Account**: Has Convexo_LPs NFT
3. **Tier 2 Account**: Has both NFTs

---

## 📞 Support & Resources

- **Contract Documentation**: See `CONTRACTS_REFERENCE.md`
- **Deployment Guide**: See `DEPLOYMENT_GUIDE.md`
- **BaseScan Explorer**: https://sepolia.basescan.org
- **Admin Address**: `0x156d3C1648ef2f50A8de590a426360Cf6a89C6f8`

---

## 🚀 Next Steps

1. **Set up wallet connection** with RainbowKit or ConnectKit
2. **Implement reputation check** on app load
3. **Build vault browsing interface**
4. **Create investment flow** (approve USDC → purchase shares)
5. **Add real-time updates** for vault metrics
6. **Implement admin dashboard** for NFT minting

---

## 💡 Pro Tips

1. **Cache contract reads**: Use SWR or React Query for better UX
2. **Real-time updates**: Listen to contract events
3. **Error handling**: Show user-friendly messages for reverts
4. **Loading states**: Show loading during transactions
5. **Gas optimization**: Batch reads with multicall
6. **Mobile responsive**: Ensure wallet connection works on mobile

---

## 🔗 Useful Links

- [Viem Docs](https://viem.sh/)
- [Wagmi Docs](https://wagmi.sh/)
- [RainbowKit](https://www.rainbowkit.com/)
- [Base Docs](https://docs.base.org/)
- [BaseScan](https://sepolia.basescan.org/)

---

**Ready to build!** All contracts are deployed, verified, and ready for frontend integration. 🎉


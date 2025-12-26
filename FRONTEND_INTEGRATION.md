# Convexo Frontend Integration Guide

**Version 2.0** - Updated with new vault flow and all network deployments

## 🎯 Quick Start for Frontend Development

All 9 contracts are deployed, tested, and verified on **3 testnets**:
- ✅ Ethereum Sepolia (Chain ID: 11155111)
- ✅ Base Sepolia (Chain ID: 84532)
- ✅ Unichain Sepolia (Chain ID: 1301)

---

## 📝 Deployed Contract Addresses (v2.0)

### Ethereum Sepolia (Chain ID: 11155111)

| Contract | Address | Verified |
|----------|---------|----------|
| **Convexo_LPs** | `0x8EFC7e25C12A815329331DA5f0e96AFfB4014472` | ✅ [View](https://sepolia.etherscan.io/address/0x8EFC7e25C12A815329331DA5f0e96AFfB4014472) |
| **Convexo_Vaults** | `0xa932e3EAa0a5e5e65f0567405207603266937618` | ✅ [View](https://sepolia.etherscan.io/address/0xa932e3EAa0a5e5e65f0567405207603266937618) |
| **Convexo_Passport** | `0x2cfa02372782cf20ef8342B0193fd69E4c5B04A8` | ✅ [View](https://sepolia.etherscan.io/address/0x2cfa02372782cf20ef8342B0193fd69E4c5B04A8) |
| **HookDeployer** | `0xecDE45FefB5C2EF6E5CC615291DE9be9A99B46A6` | ✅ [View](https://sepolia.etherscan.io/address/0xecDE45FefB5C2EF6E5CC615291DE9be9A99B46A6) |
| **CompliantLPHook** | `0xe99A49BD81bbe61cDf7F6b7D247f76cACc2e5776` | ✅ [View](https://sepolia.etherscan.io/address/0xe99A49BD81bbe61cDf7F6b7D247f76cACc2e5776) |
| **PoolRegistry** | `0x83Df102F62c4640ac8BE584c2B4E20c8c373dC2E` | ✅ [View](https://sepolia.etherscan.io/address/0x83Df102F62c4640ac8BE584c2B4E20c8c373dC2E) |
| **ReputationManager** | `0x60aFA63fDf17a75534e8218BaAc1D64E7FD93b4a` | ✅ [View](https://sepolia.etherscan.io/address/0x60aFA63fDf17a75534e8218BaAc1D64E7FD93b4a) |
| **PriceFeedManager** | `0x6A9af3B1da3fC07C78c37c380368773b1E830Fac` | ✅ [View](https://sepolia.etherscan.io/address/0x6A9af3B1da3fC07C78c37c380368773b1E830Fac) |
| **ContractSigner** | `0xE6b658c4D1e00a675DF046cA0bAeb86bef7da985` | ✅ [View](https://sepolia.etherscan.io/address/0xE6b658c4D1e00a675DF046cA0bAeb86bef7da985) |
| **VaultFactory** | `0x8c2D66210A43201bae2a7BF924ecA0f53364967f` | ✅ [View](https://sepolia.etherscan.io/address/0x8c2D66210A43201bae2a7BF924ecA0f53364967f) |

### Base Sepolia (Chain ID: 84532)

| Contract | Address | Verified |
|----------|---------|----------|
| **Convexo_LPs** | `0x90caec19973DB5c39373d1f3072a7ED096aBAD84` | ✅ [View](https://sepolia.basescan.org/address/0x90caec19973DB5c39373d1f3072a7ED096aBAD84) |
| **Convexo_Vaults** | `0xD0ECa5Dae7Ba021C75f2Fc69bDe756dd33C26adE` | ✅ [View](https://sepolia.basescan.org/address/0xD0ECa5Dae7Ba021C75f2Fc69bDe756dd33C26adE) |
| **Convexo_Passport** | `0x4A164470586B7e80eEf2734d24f5F784e4f88ad0` | ✅ [View](https://sepolia.basescan.org/address/0x4A164470586B7e80eEf2734d24f5F784e4f88ad0) |
| **HookDeployer** | `0xA0b9E51B51656A6DCaFDEfc7C83167358Be425AB` | ✅ [View](https://sepolia.basescan.org/address/0xA0b9E51B51656A6DCaFDEfc7C83167358Be425AB) |
| **CompliantLPHook** | `0x331C35ba44FE83183eEd913D647F4f18E9BCf785` | ✅ [View](https://sepolia.basescan.org/address/0x331C35ba44FE83183eEd913D647F4f18E9BCf785) |
| **PoolRegistry** | `0xA59C12e996C7224B925A98C35c6dd82464CA1e0d` | ✅ [View](https://sepolia.basescan.org/address/0xA59C12e996C7224B925A98C35c6dd82464CA1e0d) |
| **ReputationManager** | `0x340Fd03C88297A5B0caFD5877FC1faecEffaf159` | ✅ [View](https://sepolia.basescan.org/address/0x340Fd03C88297A5B0caFD5877FC1faecEffaf159) |
| **PriceFeedManager** | `0xD6cfde6525703b625ba1acB5645e2584eb7a702f` | ✅ [View](https://sepolia.basescan.org/address/0xD6cfde6525703b625ba1acB5645e2584eb7a702f) |
| **ContractSigner** | `0xBA579E561aF128d801f1a1A5416Ee73e2094C3A5` | ✅ [View](https://sepolia.basescan.org/address/0xBA579E561aF128d801f1a1A5416Ee73e2094C3A5) |
| **VaultFactory** | `0xE8C890871DE3c0D2fd90ad560ABBa3a25CD5e139` | ✅ [View](https://sepolia.basescan.org/address/0xE8C890871DE3c0D2fd90ad560ABBa3a25CD5e139) |

### Unichain Sepolia (Chain ID: 1301)

| Contract | Address | Verified |
|----------|---------|----------|
| **Convexo_LPs** | `0x76dA1B31497bbD1093F9226Dcad505518CF62ca1` | ✅ [View](https://unichain-sepolia.blockscout.com/address/0x76dA1B31497bbD1093F9226Dcad505518CF62ca1) |
| **Convexo_Vaults** | `0xe542857F76dBA4A53eF7D244cAdC227B454b1502` | ✅ [View](https://unichain-sepolia.blockscout.com/address/0xe542857F76dBA4A53eF7D244cAdC227B454b1502) |
| **Convexo_Passport** | `0xB612dB1FE343C4B5FFa9e8C3f4dde37769F7C5B6` | ✅ [View](https://unichain-sepolia.blockscout.com/address/0xB612dB1FE343C4B5FFa9e8C3f4dde37769F7C5B6) |
| **HookDeployer** | `0xbfba31D3f7B36A78AbD7C7905DAcdECBe6BB97AD` | ✅ [View](https://unichain-sepolia.blockscout.com/address/0xbfba31D3f7B36A78AbD7C7905DAcdECBe6BB97AD) |
| **CompliantLPHook** | `0x2B09a55380E9023B85886005Dc53B600cF6e3f17` | ✅ [View](https://unichain-sepolia.blockscout.com/address/0x2B09a55380E9023B85886005Dc53B600cF6e3f17) |
| **PoolRegistry** | `0xf75AF6F9D586f9c16C5789B2C310Dd7a98dF97Ae` | ✅ [View](https://unichain-sepolia.blockscout.com/address/0xf75AF6F9D586f9c16C5789B2C310Dd7a98dF97Ae) |
| **ReputationManager** | `0xB286824B6F5789BA6a6710A5e9FE487A4CB21F06` | ✅ [View](https://unichain-sepolia.blockscout.com/address/0xB286824B6F5789BA6a6710A5e9FE487A4CB21F06) |
| **PriceFeedManager** | `0x9C60e348dfbb8Bba62F8408cB7Fa85dc88BD9957` | ✅ [View](https://unichain-sepolia.blockscout.com/address/0x9C60e348dfbb8Bba62F8408cB7Fa85dc88BD9957) |
| **ContractSigner** | `0x71E7AAB4d65383fb75Eea51eC58b5d5B999E0aEC` | ✅ [View](https://unichain-sepolia.blockscout.com/address/0x71E7AAB4d65383fb75Eea51eC58b5d5B999E0aEC) |
| **VaultFactory** | `0x0bb2e0Ce69aa107E3f3b7a5dd3D8192C212Ff0D5` | ✅ [View](https://unichain-sepolia.blockscout.com/address/0x0bb2e0Ce69aa107E3f3b7a5dd3D8192C212Ff0D5) |

> **📖 See chain-specific deployment docs: [Ethereum](./ETHEREUM_DEPLOYMENTS.md) | [Base](./BASE_DEPLOYMENTS.md) | [Unichain](./UNICHAIN_DEPLOYMENTS.md)**

---

## 📦 ABIs Location

All contract ABIs are available in the `abis/` directory:

```
abis/
├── Convexo_LPs.json          # Tier 1 NFT
├── Convexo_Vaults.json        # Tier 2 NFT
├── Convexo_Passport.json      # Tier 3 NFT (ZKPassport)
├── HookDeployer.json          # Hook deployment helper
├── CompliantLPHook.json       # Uniswap V4 hook
├── PoolRegistry.json          # Pool tracking
├── ReputationManager.json     # User tier calculation
├── PriceFeedManager.json      # Price feeds
├── ContractSigner.json        # Multi-sig contracts
├── VaultFactory.json          # Vault creation
└── TokenizedBondVault.json    # Individual vault (ERC20 shares)
```

**Total: 12 ABIs** - All contracts ready for frontend integration

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
  ETHEREUM_SEPOLIA: {
    CHAIN_ID: 11155111,
    CONVEXO_LPS: '0x8EFC7e25C12A815329331DA5f0e96AFfB4014472',
    CONVEXO_VAULTS: '0xa932e3EAa0a5e5e65f0567405207603266937618',
    CONVEXO_PASSPORT: '0x2cfa02372782cf20ef8342B0193fd69E4c5B04A8',
    HOOK_DEPLOYER: '0xecDE45FefB5C2EF6E5CC615291DE9be9A99B46A6',
    COMPLIANT_LP_HOOK: '0xe99A49BD81bbe61cDf7F6b7D247f76cACc2e5776',
    POOL_REGISTRY: '0x83Df102F62c4640ac8BE584c2B4E20c8c373dC2E',
    REPUTATION_MANAGER: '0x60aFA63fDf17a75534e8218BaAc1D64E7FD93b4a',
    PRICE_FEED_MANAGER: '0x6A9af3B1da3fC07C78c37c380368773b1E830Fac',
    CONTRACT_SIGNER: '0xE6b658c4D1e00a675DF046cA0bAeb86bef7da985',
    VAULT_FACTORY: '0x8c2D66210A43201bae2a7BF924ecA0f53364967f',
  },
  BASE_SEPOLIA: {
    CHAIN_ID: 84532,
    CONVEXO_LPS: '0x90caec19973DB5c39373d1f3072a7ED096aBAD84',
    CONVEXO_VAULTS: '0xD0ECa5Dae7Ba021C75f2Fc69bDe756dd33C26adE',
    CONVEXO_PASSPORT: '0x4A164470586B7e80eEf2734d24f5F784e4f88ad0',
    HOOK_DEPLOYER: '0xA0b9E51B51656A6DCaFDEfc7C83167358Be425AB',
    COMPLIANT_LP_HOOK: '0x331C35ba44FE83183eEd913D647F4f18E9BCf785',
    POOL_REGISTRY: '0xA59C12e996C7224B925A98C35c6dd82464CA1e0d',
    REPUTATION_MANAGER: '0x340Fd03C88297A5B0caFD5877FC1faecEffaf159',
    PRICE_FEED_MANAGER: '0xD6cfde6525703b625ba1acB5645e2584eb7a702f',
    CONTRACT_SIGNER: '0xBA579E561aF128d801f1a1A5416Ee73e2094C3A5',
    VAULT_FACTORY: '0xE8C890871DE3c0D2fd90ad560ABBa3a25CD5e139',
  },
  UNICHAIN_SEPOLIA: {
    CHAIN_ID: 1301,
    CONVEXO_LPS: '0x76dA1B31497bbD1093F9226Dcad505518CF62ca1',
    CONVEXO_VAULTS: '0xe542857F76dBA4A53eF7D244cAdC227B454b1502',
    CONVEXO_PASSPORT: '0xB612dB1FE343C4B5FFa9e8C3f4dde37769F7C5B6',
    HOOK_DEPLOYER: '0xbfba31D3f7B36A78AbD7C7905DAcdECBe6BB97AD',
    COMPLIANT_LP_HOOK: '0x2B09a55380E9023B85886005Dc53B600cF6e3f17',
    POOL_REGISTRY: '0xf75AF6F9D586f9c16C5789B2C310Dd7a98dF97Ae',
    REPUTATION_MANAGER: '0xB286824B6F5789BA6a6710A5e9FE487A4CB21F06',
    PRICE_FEED_MANAGER: '0x9C60e348dfbb8Bba62F8408cB7Fa85dc88BD9957',
    CONTRACT_SIGNER: '0x71E7AAB4d65383fb75Eea51eC58b5d5B999E0aEC',
    VAULT_FACTORY: '0x0bb2e0Ce69aa107E3f3b7a5dd3D8192C212Ff0D5',
  },
} as const;

// Helper to get contracts for current chain
export function getContracts(chainId: number) {
  switch (chainId) {
    case 11155111:
      return CONTRACTS.ETHEREUM_SEPOLIA;
    case 84532:
      return CONTRACTS.BASE_SEPOLIA;
    case 1301:
      return CONTRACTS.UNICHAIN_SEPOLIA;
    default:
      throw new Error(`Unsupported chain ID: ${chainId}`);
  }
}
```

### 3. Import ABIs

```typescript
// contracts/abis.ts
import ConvexoLPsABI from '../abis/Convexo_LPs.json';
import ConvexoVaultsABI from '../abis/Convexo_Vaults.json';
import ConvexoPassportABI from '../abis/Convexo_Passport.json';
import ReputationManagerABI from '../abis/ReputationManager.json';
import VaultFactoryABI from '../abis/VaultFactory.json';
import TokenizedBondVaultABI from '../abis/TokenizedBondVault.json';
// ... import other ABIs as needed

export {
  ConvexoLPsABI,
  ConvexoVaultsABI,
  ConvexoPassportABI,
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

### Flow 1: Check User Access

```typescript
// 1. Check reputation tier
const reputation = useUserReputation(address);

// 2. Display access level
if (reputation.tier === 0) {
  return <p>❌ No access - Apply for verification</p>;
} else if (reputation.tier === 1) {
  return <p>✅ Tier 1 - Can trade in liquidity pools</p>;
} else if (reputation.tier === 2) {
  return <p>✅ Tier 2 - Can create vaults & trade in pools</p>;
} else if (reputation.tier === 3) {
  return <p>✅ Tier 3 - Can invest in vaults (ZKPassport verified)</p>;
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

### Flow 3: Borrower Creates Vault (Tier 2 Required)

**✨ New in v2.0**: Borrowers create vaults directly if they have Tier 2 NFT (no admin needed).

```typescript
function CreateVaultForm() {
  const { address } = useAccount();
  const { chain } = useNetwork();
  const contracts = getContracts(chain?.id || 84532);
  
  // 1. Check if user has Tier 2 NFT
  const { data: tier } = useContractRead({
    address: contracts.REPUTATION_MANAGER,
    abi: ReputationManagerABI,
    functionName: 'getReputationTier',
    args: [address],
  });
  
  if (!tier || tier < 2) {
    return (
      <div className="alert alert-warning">
        <p>❌ Tier 2 NFT required to create vaults</p>
        <p>Complete credit scoring to receive Tier 2 access</p>
      </div>
    );
  }

  // 2. Create vault (no contract hash needed upfront)
  const { write: createVault, isLoading } = useContractWrite({
    address: contracts.VAULT_FACTORY,
    abi: VaultFactoryABI,
    functionName: 'createVault',
    args: [
      parseUnits('50000', 6),  // 50k USDC principal
      1200,                     // 12% interest rate (12%)
      Math.floor(Date.now() / 1000) + 180 * 24 * 60 * 60, // 180 days maturity
      "My Business Vault",      // Vault name
      "MBV"                     // Vault symbol
    ],
  });

  return (
    <form onSubmit={(e) => { e.preventDefault(); createVault?.(); }}>
      <h3>Create Funding Vault</h3>
      <input type="number" placeholder="Principal Amount (USDC)" />
      <input type="number" placeholder="Interest Rate (%)" defaultValue="12" />
      <input type="number" placeholder="Duration (days)" defaultValue="180" />
      <input type="text" placeholder="Vault Name" />
      <input type="text" placeholder="Vault Symbol" />
      <button disabled={isLoading} type="submit">
        {isLoading ? 'Creating...' : 'Create Vault'}
      </button>
    </form>
  );
}
```

**Key Changes in v2.0:**
- ✅ No `contractHash` parameter needed during creation
- ✅ Borrower creates vault directly (not admin)
- ✅ Contract is attached AFTER vault is fully funded
- ✅ Funds locked until contract is signed by all parties

### Flow 4: Investors Fund Vault

```typescript
function InvestInVault({ vaultAddress }: { vaultAddress: `0x${string}` }) {
  // 1. Get vault info
  const { data: vaultMetrics } = useContractRead({
    address: vaultAddress,
    abi: TokenizedBondVaultABI,
    functionName: 'getVaultMetrics',
  });

  const [totalShares, sharePrice, tvl, target, progress, apy] = vaultMetrics || [];

  // 2. Approve USDC
  const { write: approveUSDC } = useContractWrite({
    address: USDC_ADDRESS,
    abi: ERC20_ABI,
    functionName: 'approve',
    args: [vaultAddress, parseUnits('10000', 6)],
  });

  // 3. Purchase shares
  const { write: purchaseShares } = useContractWrite({
    address: vaultAddress,
    abi: TokenizedBondVaultABI,
    functionName: 'purchaseShares',
    args: [parseUnits('1000', 6)], // 1000 USDC
  });

  return (
    <div>
      <p>Progress: {Number(progress) / 100}%</p>
      <p>APY: {Number(apy) / 100}%</p>
      <button onClick={() => approveUSDC?.()}>1. Approve USDC</button>
      <button onClick={() => purchaseShares?.()}>2. Invest</button>
    </div>
  );
}
```

### Flow 5: Attach Contract & Withdraw Funds

**✨ New in v2.0**: Borrower attaches contract AFTER vault is funded, then withdraws.

```typescript
function VaultManagement({ vaultAddress }: { vaultAddress: `0x${string}` }) {
  const { address } = useAccount();
  
  // 1. Check vault state
  const { data: vaultState } = useContractRead({
    address: vaultAddress,
    abi: TokenizedBondVaultABI,
    functionName: 'getVaultState',
  });

  // 2. Get vault info
  const { data: borrower } = useContractRead({
    address: vaultAddress,
    abi: TokenizedBondVaultABI,
    functionName: 'getVaultBorrower',
  });

  const { data: contractHash } = useContractRead({
    address: vaultAddress,
    abi: TokenizedBondVaultABI,
    functionName: 'contractHash',
  });

  // State: 0=Pending, 1=Funded, 2=Active, 3=Repaying, 4=Completed, 5=Defaulted
  const isPending = vaultState === 0;
  const isFunded = vaultState === 1;
  const isActive = vaultState === 2;
  const isBorrower = borrower?.toLowerCase() === address?.toLowerCase();

  // 3. Attach contract (after funding, before withdrawal)
  const { write: attachContract, isLoading: isAttaching } = useContractWrite({
    address: vaultAddress,
    abi: TokenizedBondVaultABI,
    functionName: 'attachContract',
    args: ['0x...'], // Contract hash from ContractSigner
  });

  // 4. Withdraw funds (after contract is signed)
  const { write: withdrawFunds, isLoading: isWithdrawing } = useContractWrite({
    address: vaultAddress,
    abi: TokenizedBondVaultABI,
    functionName: 'withdrawFunds',
  });

  if (!isBorrower) {
    return <p>Only borrower can manage this vault</p>;
  }

  return (
    <div className="vault-management">
      <h3>Vault Status</h3>
      <p>State: {['Pending', 'Funded', 'Active', 'Repaying', 'Completed', 'Defaulted'][vaultState || 0]}</p>
      
      {isPending && <p>⏳ Waiting for investors to fund vault...</p>}
      
      {isFunded && !contractHash && (
        <div>
          <p>✅ Vault fully funded!</p>
          <p>📝 Next: Create and sign contract with investors</p>
          <button onClick={() => attachContract?.()} disabled={isAttaching}>
            {isAttaching ? 'Attaching...' : 'Attach Signed Contract'}
          </button>
        </div>
      )}
      
      {isFunded && contractHash && (
        <div>
          <p>✅ Contract attached!</p>
          <p>⏳ Waiting for all signatures...</p>
        </div>
      )}
      
      {isActive && (
        <div>
          <p>✅ Contract fully signed!</p>
          <button onClick={() => withdrawFunds?.()} disabled={isWithdrawing}>
            {isWithdrawing ? 'Withdrawing...' : 'Withdraw Funds'}
          </button>
        </div>
      )}
    </div>
  );
}
```

**New Vault Flow:**
1. **Pending** → Vault created, waiting for funding
2. **Funded** → Fully funded, borrower attaches contract hash
3. **Active** → Contract signed, borrower can withdraw
4. **Repaying** → Borrower making repayments
5. **Completed** → Fully repaid
6. **Defaulted** → Past maturity, not fully repaid

### Flow 6: Flexible Repayment System

**✨ New in v2.0**: Borrower can repay anytime, any amount. Each party withdraws independently.

```typescript
function RepaymentInterface({ vaultAddress }: { vaultAddress: `0x${string}` }) {
  const { address } = useAccount();
  
  // 1. Get vault metrics
  const { data: principalAmount } = useContractRead({
    address: vaultAddress,
    abi: TokenizedBondVaultABI,
    functionName: 'getVaultPrincipalAmount',
  });

  const { data: interestRate } = useContractRead({
    address: vaultAddress,
    abi: TokenizedBondVaultABI,
    functionName: 'getVaultInterestRate',
  });

  // Calculate total due: Principal + Interest (12%) + Protocol Fee (2%)
  const principal = principalAmount ? Number(formatUnits(principalAmount, 6)) : 0;
  const interest = principal * (Number(interestRate) / 10000); // 1200 = 12%
  const protocolFee = principal * 0.02; // 2%
  const totalDue = principal + interest + protocolFee;

  // 2. Make repayment (any amount, anytime)
  const [repayAmount, setRepayAmount] = useState('');
  
  const { write: makeRepayment, isLoading } = useContractWrite({
    address: vaultAddress,
    abi: TokenizedBondVaultABI,
    functionName: 'makeRepayment',
    args: [parseUnits(repayAmount || '0', 6)],
  });

  return (
    <div className="repayment-interface">
      <h3>Repayment</h3>
      <div className="repayment-breakdown">
        <p>Principal: ${principal.toLocaleString()} USDC</p>
        <p>Interest (12%): ${interest.toLocaleString()} USDC</p>
        <p>Protocol Fee (2%): ${protocolFee.toLocaleString()} USDC</p>
        <p><strong>Total Due: ${totalDue.toLocaleString()} USDC</strong></p>
      </div>
      
      <div className="repayment-form">
        <input
          type="number"
          placeholder="Amount to repay"
          value={repayAmount}
          onChange={(e) => setRepayAmount(e.target.value)}
        />
        <button onClick={() => makeRepayment?.()} disabled={isLoading}>
          {isLoading ? 'Repaying...' : 'Make Repayment'}
        </button>
        <p className="help-text">
          💡 You can repay any amount, anytime before maturity
        </p>
      </div>
    </div>
  );
}
```

### Flow 7: Independent Withdrawals

**✨ New in v2.2**: Protocol fees are now protected! Investors can only withdraw their portion.

```typescript
function WithdrawalInterface({ vaultAddress }: { vaultAddress: `0x${string}` }) {
  const { address } = useAccount();
  const { chain } = useNetwork();
  const contracts = getContracts(chain?.id || 84532);
  
  // 🔒 NEW in v2.2: Get available funds for investors (excluding protocol fees)
  const { data: availableForInvestors } = useContractRead({
    address: vaultAddress,
    abi: TokenizedBondVaultABI,
    functionName: 'getAvailableForInvestors',
  });
  
  // Check if user is protocol collector
  const isProtocolCollector = address?.toLowerCase() === contracts.PROTOCOL_FEE_COLLECTOR?.toLowerCase();
  
  // 1. Protocol Collector Withdrawal
  const { data: protocolFeesAvailable } = useContractRead({
    address: vaultAddress,
    abi: TokenizedBondVaultABI,
    functionName: 'protocolFeesEarned',
  });

  const { write: withdrawProtocolFees, isLoading: isWithdrawingFees } = useContractWrite({
    address: vaultAddress,
    abi: TokenizedBondVaultABI,
    functionName: 'withdrawProtocolFees',
  });

  // 2. Investor Withdrawal (redeem shares)
  const { data: userShares } = useContractRead({
    address: vaultAddress,
    abi: TokenizedBondVaultABI,
    functionName: 'balanceOf',
    args: [address],
  });

  const { write: redeemShares, isLoading: isRedeeming } = useContractWrite({
    address: vaultAddress,
    abi: TokenizedBondVaultABI,
    functionName: 'redeemShares',
    args: [userShares || 0n],
  });

  return (
    <div className="withdrawal-interface">
      {isProtocolCollector && (
        <div className="protocol-withdrawal">
          <h4>Protocol Fees</h4>
          <p>Available: {formatUnits(protocolFeesAvailable || 0n, 6)} USDC</p>
          <button onClick={() => withdrawProtocolFees?.()} disabled={isWithdrawingFees}>
            {isWithdrawingFees ? 'Withdrawing...' : 'Withdraw Protocol Fees'}
          </button>
        </div>
      )}
      
      {userShares && userShares > 0n && (
        <div className="investor-withdrawal">
          <h4>Your Investment</h4>
          <p>Shares: {formatUnits(userShares, 18)}</p>
          <button onClick={() => redeemShares?.()} disabled={isRedeeming}>
            {isRedeeming ? 'Redeeming...' : 'Redeem All Shares'}
          </button>
          <p className="help-text">
            💡 You'll receive your proportional share of repayments
          </p>
        </div>
      )}
    </div>
  );
}
```

**Key Features:**
- ✅ Borrower pays: Principal + 12% interest + 2% protocol fee
- ✅ Flexible repayment: Any amount, anytime
- ✅ Protocol collector withdraws 2% fee independently
- ✅ Investors redeem shares for principal + 12% returns
- ✅ Funds locked in vault until withdrawn
- ✅ Proportional distribution based on repayments

### Flow 8: Vault Timeline Display

**✨ New in v2.1**: Track all vault milestones with timestamps for complete transparency.

```typescript
interface VaultTimeline {
  createdAt: number;
  fundedAt: number;
  contractAttachedAt: number;
  fundsWithdrawnAt: number;
  actualDueDate: number;
}

function VaultTimelineDisplay({ vaultAddress }: { vaultAddress: `0x${string}` }) {
  // Fetch all timestamps
  const { data: createdAt } = useContractRead({
    address: vaultAddress,
    abi: TokenizedBondVaultABI,
    functionName: 'getVaultCreatedAt',
  });

  const { data: fundedAt } = useContractRead({
    address: vaultAddress,
    abi: TokenizedBondVaultABI,
    functionName: 'getVaultFundedAt',
  });

  const { data: contractAttachedAt } = useContractRead({
    address: vaultAddress,
    abi: TokenizedBondVaultABI,
    functionName: 'getVaultContractAttachedAt',
  });

  const { data: fundsWithdrawnAt } = useContractRead({
    address: vaultAddress,
    abi: TokenizedBondVaultABI,
    functionName: 'getVaultFundsWithdrawnAt',
  });

  const { data: actualDueDate } = useContractRead({
    address: vaultAddress,
    abi: TokenizedBondVaultABI,
    functionName: 'getActualDueDate',
  });

  // Helper to format timestamp
  const formatDate = (timestamp: bigint | undefined) => {
    if (!timestamp || timestamp === 0n) return 'Pending';
    return new Date(Number(timestamp) * 1000).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  // Calculate days remaining
  const getDaysRemaining = () => {
    if (!actualDueDate || actualDueDate === 0n) return null;
    const now = Math.floor(Date.now() / 1000);
    const secondsRemaining = Number(actualDueDate) - now;
    return Math.floor(secondsRemaining / 86400);
  };

  const daysRemaining = getDaysRemaining();

  return (
    <div className="vault-timeline">
      <h3>Vault Timeline</h3>
      
      <div className="timeline-events">
        <div className="timeline-event completed">
          <div className="event-icon">✅</div>
          <div className="event-details">
            <h4>Vault Created</h4>
            <p>{formatDate(createdAt)}</p>
          </div>
        </div>

        <div className={`timeline-event ${fundedAt && fundedAt > 0n ? 'completed' : 'pending'}`}>
          <div className="event-icon">{fundedAt && fundedAt > 0n ? '✅' : '⏳'}</div>
          <div className="event-details">
            <h4>Fully Funded</h4>
            <p>{formatDate(fundedAt)}</p>
          </div>
        </div>

        <div className={`timeline-event ${contractAttachedAt && contractAttachedAt > 0n ? 'completed' : 'pending'}`}>
          <div className="event-icon">{contractAttachedAt && contractAttachedAt > 0n ? '✅' : '⏳'}</div>
          <div className="event-details">
            <h4>Contract Signed</h4>
            <p>{formatDate(contractAttachedAt)}</p>
          </div>
        </div>

        <div className={`timeline-event ${fundsWithdrawnAt && fundsWithdrawnAt > 0n ? 'completed' : 'pending'}`}>
          <div className="event-icon">{fundsWithdrawnAt && fundsWithdrawnAt > 0n ? '✅' : '⏳'}</div>
          <div className="event-details">
            <h4>Funds Withdrawn</h4>
            <p>{formatDate(fundsWithdrawnAt)}</p>
          </div>
        </div>

        <div className={`timeline-event ${daysRemaining !== null && daysRemaining <= 0 ? 'completed' : 'pending'}`}>
          <div className="event-icon">{daysRemaining !== null && daysRemaining <= 0 ? '✅' : '📅'}</div>
          <div className="event-details">
            <h4>Due Date</h4>
            <p>{formatDate(actualDueDate)}</p>
            {daysRemaining !== null && daysRemaining > 0 && (
              <p className="days-remaining">
                {daysRemaining} days remaining
              </p>
            )}
            {daysRemaining !== null && daysRemaining < 0 && (
              <p className="overdue">
                {Math.abs(daysRemaining)} days overdue
              </p>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
```

**Why This Matters:**
- ✅ **Accurate Due Dates**: Due date calculated from withdrawal time, not creation time
- ✅ **Complete Audit Trail**: Immutable timestamps for all major events
- ✅ **Better UX**: Users see exactly when each milestone occurred
- ✅ **Compliance**: Transparent timeline for all parties
- ✅ **Progress Tracking**: Visual representation of vault lifecycle

---

## 📊 Dashboard Components to Build

### 1. User Dashboard

- **NFT Status**: Show if user has Convexo_LPs and/or Convexo_Vaults NFT
- **Reputation Tier**: Display tier and access level
- **Portfolio**: Show all vault investments with real-time returns
- **Created Vaults**: List vaults created by the user (for Tier 2 borrowers)
- **Investments**: List vaults the user has invested in

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

#### Basic Setup
- [ ] Connect wallet to Ethereum/Base/Unichain Sepolia
- [ ] Switch between networks
- [ ] Check user reputation tier
- [ ] Display NFT ownership status

#### Vault Creation (Tier 2 Borrowers)
- [ ] Verify Tier 2 NFT requirement
- [ ] Create new vault
- [ ] View created vault status
- [ ] Monitor funding progress

#### Investment Flow (All Users)
- [ ] List all available vaults
- [ ] Show vault metrics (TVL, APY, progress, etc.)
- [ ] Approve USDC spending
- [ ] Purchase vault shares
- [ ] Display user's investment returns
- [ ] Track share balance

#### Contract Signing Flow (Borrowers)
- [ ] Detect when vault is fully funded
- [ ] Attach contract hash to vault
- [ ] Monitor contract signature status
- [ ] Enable withdrawal when fully signed

#### Repayment & Withdrawal
- [ ] Borrower makes flexible repayments
- [ ] Protocol collector withdraws fees
- [ ] Investors redeem shares
- [ ] Display proportional distributions

#### Liquidity Pools (Tier 1+)
- [ ] Verify pool access with NFT
- [ ] Test USDC/ECOP swaps
- [ ] Display pool liquidity

### Test Accounts Needed:

1. **No NFT Account**: Test restricted access (Tier 0)
2. **Tier 1 Account**: Has Convexo_LPs NFT (pool access)
3. **Tier 2 Account**: Has both NFTs (can create vaults)
4. **Protocol Admin**: For fee collection testing

---

## 📞 Support & Resources

### Documentation
- **Contract Reference**: [CONTRACTS_REFERENCE.md](./CONTRACTS_REFERENCE.md) - Complete contract documentation
- **Ethereum**: [ETHEREUM_DEPLOYMENTS.md](./ETHEREUM_DEPLOYMENTS.md) - All Ethereum deployments
- **Base**: [BASE_DEPLOYMENTS.md](./BASE_DEPLOYMENTS.md) - All Base deployments
- **Unichain**: [UNICHAIN_DEPLOYMENTS.md](./UNICHAIN_DEPLOYMENTS.md) - All Unichain deployments

### Explorers
- **Ethereum Sepolia**: https://sepolia.etherscan.io
- **Base Sepolia**: https://sepolia.basescan.org
- **Unichain Sepolia**: https://unichain-sepolia.blockscout.com

### Key Addresses
- **Admin**: `0x156d3C1648ef2f50A8de590a426360Cf6a89C6f8`
- **USDC (Ethereum)**: `0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238`
- **USDC (Base)**: `0x036CbD53842c5426634e7929541eC2318f3dCF7e`
- **USDC (Unichain)**: `0x31d0220469e10c4E71834a79b1f276d740d3768F`

---

## 🆕 What's New in Version 2.0

### Major Changes
1. **Borrower-Initiated Vaults**
   - Borrowers create vaults directly (requires Tier 2 NFT)
   - No admin intervention needed
   - Contract attached AFTER funding

2. **Flexible Repayment System**
   - Pay anytime, any amount before maturity
   - No fixed payment schedule
   - Real-time tracking of repayments

3. **Independent Withdrawals**
   - Protocol collector withdraws 2% fee independently
   - Investors redeem shares independently
   - Proportional distribution based on repayments
   - Funds locked in vault until withdrawn

4. **New Vault States**
   - `Pending`: Created, waiting for funding
   - `Funded`: Fully funded, waiting for contract
   - `Active`: Contract signed, funds withdrawable
   - `Repaying`: Borrower making repayments
   - `Completed`: Fully repaid
   - `Defaulted`: Past maturity, not fully repaid

5. **Simplified Architecture**
   - Removed `InvoiceFactoring` contract
   - Removed `TokenizedBondCredits` contract
   - Focus on core Tokenized Bond Vaults
   - 9 contracts (down from 11)

### Breaking Changes
- `createVault()` no longer requires `contractHash` parameter
- `VaultFactory` now checks for Tier 2 NFT ownership
- New `attachContract()` function for borrowers
- `withdrawFunds()` replaces `disburseLoan()`
- Separate `withdrawProtocolFees()` and `redeemShares()` functions

---

## 🚀 Next Steps

1. **Set up multi-chain support** with Wagmi
2. **Implement network switching** (Ethereum/Base/Unichain)
3. **Build vault creation flow** for Tier 2 users
4. **Create investment interface** with USDC approval
5. **Add contract signing flow** for borrowers
6. **Implement repayment interface** with flexible amounts
7. **Build withdrawal interfaces** for protocol & investors
8. **Add real-time vault state monitoring**
9. **Implement admin dashboard** for NFT minting

---

## 💡 Pro Tips

1. **Multi-chain Support**: Use Wagmi's `useNetwork()` and `useSwitchNetwork()` hooks
2. **Cache contract reads**: Use SWR or React Query for better UX
3. **Real-time updates**: Listen to contract events with `useContractEvent()`
4. **Error handling**: Parse revert reasons and show user-friendly messages
5. **Loading states**: Show loading spinners during transactions
6. **Gas optimization**: Batch reads with `multicall`
7. **Mobile responsive**: Ensure wallet connection works on mobile
8. **State management**: Track vault states (Pending → Funded → Active → Repaying)
9. **Notifications**: Alert users when vaults are funded or contracts need signing
10. **Analytics**: Track TVL, APY, and user activity across all vaults

---

## 🔗 Useful Links

### Development Tools
- [Viem Docs](https://viem.sh/) - TypeScript interface for Ethereum
- [Wagmi Docs](https://wagmi.sh/) - React hooks for Ethereum
- [RainbowKit](https://www.rainbowkit.com/) - Wallet connection UI
- [ConnectKit](https://docs.family.co/connectkit) - Alternative wallet UI

### Network Documentation
- [Ethereum Docs](https://ethereum.org/developers)
- [Base Docs](https://docs.base.org/)
- [Unichain Docs](https://docs.unichain.org/)
- [Uniswap V4 Docs](https://docs.uniswap.org/contracts/v4/overview)

### Testing Resources
- [Ethereum Sepolia Faucet](https://sepoliafaucet.com/)
- [Base Sepolia Faucet](https://www.coinbase.com/faucets/base-ethereum-goerli-faucet)
- [Unichain Sepolia Faucet](https://faucet.unichain.org/)

---

## ✅ Frontend Handoff Checklist

- [x] All 10 contracts deployed on 3 testnets (v2.0 with ZKPassport)
- [x] All contracts verified on explorers
- [x] 12 ABIs extracted and available
- [x] Contract addresses documented
- [x] Integration examples provided
- [x] New vault flow documented
- [x] Repayment system explained
- [x] Withdrawal flows detailed
- [x] Testing checklist created
- [x] Multi-chain support ready

**Status: ✅ Ready for frontend integration!**

All contracts are deployed, verified, and ready for frontend development. Version 2.0 includes ZKPassport integration for individual investors. 🎉

---

**Questions?** Check [CONTRACTS_REFERENCE.md](./CONTRACTS_REFERENCE.md) for detailed contract documentation.


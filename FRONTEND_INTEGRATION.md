# Convexo Frontend Integration Guide

**Version 2.0** - Updated with new vault flow and all network deployments

## 🎯 Quick Start for Frontend Development

All 9 contracts are deployed, tested, and verified on **3 testnets**:
- ✅ Ethereum Sepolia (Chain ID: 11155111)
- ✅ Base Sepolia (Chain ID: 84532)
- ✅ Unichain Sepolia (Chain ID: 1301)

---

## 📝 Deployed Contract Addresses (v2.2)

### Ethereum Sepolia (Chain ID: 11155111)

| Contract | Address | Verified |
|----------|---------|----------|
| **Convexo_LPs** | `0x2a0d9da5a72dfe20b65b25e9fefc0e6e090ac194` | ✅ [View](https://sepolia.etherscan.io/address/0x2a0d9da5a72dfe20b65b25e9fefc0e6e090ac194) |
| **Convexo_Vaults** | `0x744e39b3eb1be014cb8d14a585c31e22b7f4a9b8` | ✅ [View](https://sepolia.etherscan.io/address/0x744e39b3eb1be014cb8d14a585c31e22b7f4a9b8) |
| **HookDeployer** | `0xb2785f4341b5bf26be07f7e2037550769ce830cd` | ✅ [View](https://sepolia.etherscan.io/address/0xb2785f4341b5bf26be07f7e2037550769ce830cd) |
| **CompliantLPHook** | `0x3738d60fcb27d719fdd5113b855e1158b93a95b1` | ✅ [View](https://sepolia.etherscan.io/address/0x3738d60fcb27d719fdd5113b855e1158b93a95b1) |
| **PoolRegistry** | `0x7ffbee85cb513753fe6ca4f476c7206ad1b3fbff` | ✅ [View](https://sepolia.etherscan.io/address/0x7ffbee85cb513753fe6ca4f476c7206ad1b3fbff) |
| **ReputationManager** | `0xe4a58592171cd0770e6792600ea3098060a42d46` | ✅ [View](https://sepolia.etherscan.io/address/0xe4a58592171cd0770e6792600ea3098060a42d46) |
| **PriceFeedManager** | `0xd7cf4aba5b9b4877419ab8af3979da637493afb1` | ✅ [View](https://sepolia.etherscan.io/address/0xd7cf4aba5b9b4877419ab8af3979da637493afb1) |
| **ContractSigner** | `0x99e9880a08e14112a18c091bd49a2b1713133687` | ✅ [View](https://sepolia.etherscan.io/address/0x99e9880a08e14112a18c091bd49a2b1713133687) |
| **VaultFactory** | `0xf54e26527bec4847f66afb5166a7a5c3d1fd6304` | ✅ [View](https://sepolia.etherscan.io/address/0xf54e26527bec4847f66afb5166a7a5c3d1fd6304) |

### Base Sepolia (Chain ID: 84532)

| Contract | Address | Verified |
|----------|---------|----------|
| **Convexo_LPs** | `0xd05df511dbe7d793d82b7344a955f15485ff0787` | ✅ [View](https://sepolia.basescan.org/address/0xd05df511dbe7d793d82b7344a955f15485ff0787) |
| **Convexo_Vaults** | `0xfb965542aa0b58538a9b50fe020314dd687eb128` | ✅ [View](https://sepolia.basescan.org/address/0xfb965542aa0b58538a9b50fe020314dd687eb128) |
| **HookDeployer** | `0x503f203ce6d6462f433cd04c7ad2b05d61b56548` | ✅ [View](https://sepolia.basescan.org/address/0x503f203ce6d6462f433cd04c7ad2b05d61b56548) |
| **CompliantLPHook** | `0xab83ce760054c1d048d5a9de5194b05398a09d41` | ✅ [View](https://sepolia.basescan.org/address/0xab83ce760054c1d048d5a9de5194b05398a09d41) |
| **PoolRegistry** | `0x18fb358bc74054b0c2530c48ef23f8a8d464cb18` | ✅ [View](https://sepolia.basescan.org/address/0x18fb358bc74054b0c2530c48ef23f8a8d464cb18) |
| **ReputationManager** | `0x50ace0dce54df668477adee4e9d6a6c0df4fedee` | ✅ [View](https://sepolia.basescan.org/address/0x50ace0dce54df668477adee4e9d6a6c0df4fedee) |
| **PriceFeedManager** | `0xa46629011e0b8561a45ea03b822d28c0b2432c3a` | ✅ [View](https://sepolia.basescan.org/address/0xa46629011e0b8561a45ea03b822d28c0b2432c3a) |
| **ContractSigner** | `0x62227ff7ccbdb4d72c3511290b28c3424f1500ef` | ✅ [View](https://sepolia.basescan.org/address/0x62227ff7ccbdb4d72c3511290b28c3424f1500ef) |
| **VaultFactory** | `0x8efc7e25c12a815329331da5f0e96affb4014472` | ✅ [View](https://sepolia.basescan.org/address/0x8efc7e25c12a815329331da5f0e96affb4014472) |

### Unichain Sepolia (Chain ID: 1301)

| Contract | Address | Verified |
|----------|---------|----------|
| **Convexo_LPs** | `0x6ba429488cad3795af1ec65d80be760b70f58e4b` | ✅ [View](https://unichain-sepolia.blockscout.com/address/0x6ba429488cad3795af1ec65d80be760b70f58e4b) |
| **Convexo_Vaults** | `0x64fd5631ffe78e907da7b48542abfb402680891a` | ✅ [View](https://unichain-sepolia.blockscout.com/address/0x64fd5631ffe78e907da7b48542abfb402680891a) |
| **HookDeployer** | `0x1917aac9c182454b3ab80aa8703734d2831adf08` | ✅ [View](https://unichain-sepolia.blockscout.com/address/0x1917aac9c182454b3ab80aa8703734d2831adf08) |
| **CompliantLPHook** | `0x3933f0018fc7d21756b86557640d66b97f514bae` | ✅ [View](https://unichain-sepolia.blockscout.com/address/0x3933f0018fc7d21756b86557640d66b97f514bae) |
| **PoolRegistry** | `0x9fee07c87bcc09b07f76c728cce56e6c8fdffb02` | ✅ [View](https://unichain-sepolia.blockscout.com/address/0x9fee07c87bcc09b07f76c728cce56e6c8fdffb02) |
| **ReputationManager** | `0x7c22db98a3f8da11f8c79d60a78d12df4a18516b` | ✅ [View](https://unichain-sepolia.blockscout.com/address/0x7c22db98a3f8da11f8c79d60a78d12df4a18516b) |
| **PriceFeedManager** | `0x8b346a47413991077f6ad38bfa4bfd3693187e6e` | ✅ [View](https://unichain-sepolia.blockscout.com/address/0x8b346a47413991077f6ad38bfa4bfd3693187e6e) |
| **ContractSigner** | `0x834dbab5c4bf2f9f2c80c9d7513ff986d3a835c8` | ✅ [View](https://unichain-sepolia.blockscout.com/address/0x834dbab5c4bf2f9f2c80c9d7513ff986d3a835c8) |
| **VaultFactory** | `0x5e252bb1642cfa13d4ad93cdfdbabcb9c64ac841` | ✅ [View](https://unichain-sepolia.blockscout.com/address/0x5e252bb1642cfa13d4ad93cdfdbabcb9c64ac841) |

> **📖 See [DEPLOYMENT_SUMMARY.md](./DEPLOYMENT_SUMMARY.md) for complete deployment details**

---

## 📦 ABIs Location

All contract ABIs are available in the `abis/` directory:

```
abis/
├── Convexo_LPs.json          # Tier 1 NFT
├── Convexo_Vaults.json        # Tier 2 NFT
├── HookDeployer.json          # Hook deployment helper
├── CompliantLPHook.json       # Uniswap V4 hook
├── PoolRegistry.json          # Pool tracking
├── ReputationManager.json     # User tier calculation
├── PriceFeedManager.json      # Price feeds
├── ContractSigner.json        # Multi-sig contracts
├── VaultFactory.json          # Vault creation
└── TokenizedBondVault.json    # Individual vault (ERC20 shares)
```

**Total: 10 ABIs** - All contracts ready for frontend integration

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
    CONVEXO_LPS: '0x7fd91438eacffe828f61737d64926ee44cf6695c',
    CONVEXO_VAULTS: '0xf02d84e56da48cec9233cb7982db0ac82f29a973',
    HOOK_DEPLOYER: '0x1843c76dfe7a353d239912d8e23bdebda712f4c9',
    COMPLIANT_LP_HOOK: '0x9fe009296cc964573cc8fb394598a3d5b9800394',
    POOL_REGISTRY: '0x0f0e9e5e7e6a47d35e261dd876438cd144f97f1e',
    REPUTATION_MANAGER: '0x6ba429488cad3795af1ec65d80be760b70f58e4b',
    PRICE_FEED_MANAGER: '0x64fd5631ffe78e907da7b48542abfb402680891a',
    CONTRACT_SIGNER: '0x1917aac9c182454b3ab80aa8703734d2831adf08',
    VAULT_FACTORY: '0x3933f0018fc7d21756b86557640d66b97f514bae',
  },
  BASE_SEPOLIA: {
    CHAIN_ID: 84532,
    CONVEXO_LPS: '0xbABEe8acECC117c1295F8950f51Db59F7a881646',
    CONVEXO_VAULTS: '0xd189d95eE1a126A66fc5A84934372Aa0Fc0bb6d2',
    HOOK_DEPLOYER: '0xE0c0d95701558eF10768A13A944F56311EAD4649',
    COMPLIANT_LP_HOOK: '0xDd973cE09ba55260e217d10f9DeC6D7945D73E79',
    POOL_REGISTRY: '0x24d91b11B0Dd12d6520E58c72F8FCC9dC1C5b935',
    REPUTATION_MANAGER: '0x3770Bb3BBEb0102a36f51aA253E69034058E4F84',
    PRICE_FEED_MANAGER: '0x2Fa95f79Ce8C5c01581f6792ACc4181282aaEFB0',
    CONTRACT_SIGNER: '0xf8dce148AB008f7ae47A26377252673438801712',
    VAULT_FACTORY: '0x3D684Ac58f25a95c107565bCFfffb219B00557C7',
  },
  UNICHAIN_SEPOLIA: {
    CHAIN_ID: 1301,
    CONVEXO_LPS: '0xbb13194b2792e291109402369cb4fc0358aed132',
    CONVEXO_VAULTS: '0xec02a78f2e6db438eb9b75aa173ac0f0d1d3126a',
    HOOK_DEPLOYER: '0xc98bce4617f9708dd1363f21177be5ef21fb4993',
    COMPLIANT_LP_HOOK: '0x85c795fdc63a106fa6c6922d0bfd6cefd04a29d7',
    POOL_REGISTRY: '0x5a1f415986a189d79d19d65cb6e3d6dd7b807268',
    REPUTATION_MANAGER: '0x6b51adc34a503b23db99444048ac7c2dc735a12e',
    PRICE_FEED_MANAGER: '0x5d88bcf0d62f17846d41e161e92e497d4224764d',
    CONTRACT_SIGNER: '0x6a6357c387331e75d6eeb4d4abc0f0200cd32830',
    VAULT_FACTORY: '0xafb16cfaf1389713c59f7aee3c1a08d3cedc3ee3',
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

### Flow 1: Check User Access

```typescript
// 1. Check reputation tier
const reputation = useUserReputation(address);

// 2. Display access level
if (reputation.tier === 0) {
  return <p>❌ No access - Apply for KYB verification</p>;
} else if (reputation.tier === 1) {
  return <p>✅ Tier 1 - Can trade in liquidity pools</p>;
} else if (reputation.tier === 2) {
  return <p>✅ Tier 2 - Can create vaults & trade in pools</p>;
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
- **Contract Reference**: [CONTRACTS_REFERENCE.md](./CONTRACTS_REFERENCE.md) - Detailed contract docs
- **Deployment Summary**: [DEPLOYMENT_SUMMARY.md](./DEPLOYMENT_SUMMARY.md) - All deployments at a glance
- **Ethereum Sepolia**: [ETHEREUM_SEPOLIA_DEPLOYMENT.md](./ETHEREUM_SEPOLIA_DEPLOYMENT.md)
- **Base Sepolia**: [BASE_SEPOLIA_DEPLOYMENT.md](./BASE_SEPOLIA_DEPLOYMENT.md)
- **Unichain Sepolia**: [UNICHAIN_SEPOLIA_DEPLOYMENT.md](./UNICHAIN_SEPOLIA_DEPLOYMENT.md)

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

- [x] All 9 contracts deployed on 3 networks
- [x] All contracts verified on explorers
- [x] 10 ABIs extracted and available
- [x] Contract addresses documented
- [x] Integration examples provided
- [x] New vault flow documented
- [x] Repayment system explained
- [x] Withdrawal flows detailed
- [x] Testing checklist created
- [x] Multi-chain support ready

**Status: ✅ Ready for frontend integration!**

All contracts are deployed, verified, and ready for frontend development. The new vault flow (v2.0) is fully tested with 14/14 tests passing. 🎉

---

**Questions?** Check [CONTRACTS_REFERENCE.md](./CONTRACTS_REFERENCE.md) for detailed contract documentation.


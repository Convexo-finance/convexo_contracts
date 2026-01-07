# Convexo Contracts - Foundry Setup Guide

## 📋 Prerequisites

1. **Foundry** - Ethereum development toolkit
2. **Git** - Version control
3. **Node.js** (optional) - For scripts

## 🚀 Step-by-Step Setup

### Step 1: Install Foundry

If you don't have Foundry installed:

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

Verify installation:
```bash
forge --version
cast --version
anvil --version
```

### Step 2: Navigate to Project Directory

```bash
cd /Users/williammartinez/Documents/convexo/convexoapp/convexo_contracts
```

### Step 3: Install Dependencies

Foundry automatically installs dependencies from `foundry.toml`:

```bash
forge install
```

This will install:
- OpenZeppelin Contracts (v5.5.0)
- Forge Standard Library
- Other dependencies

### Step 4: Build the Project

Compile all contracts:

```bash
forge build
```

Expected output:
```
[⠊] Compiling...
[⠒] Compiling 64 files with Solc 0.8.30
[⠢] Solc 0.8.30 finished in X.XXs
Compiler run successful with warnings
```

### Step 5: Run Tests

#### Run All Tests
```bash
forge test
```

#### Run Tests with Verbosity (shows logs)
```bash
forge test -vvv
```

#### Run Specific Test Contract
```bash
forge test --match-contract ReputationManagerPassportTest -vvv
```

#### Run Specific Test Function
```bash
forge test --match-test test_TierPassport_OnlyPassportNFT -vvv
```

#### Run Tests with Gas Report
```bash
forge test --gas-report
```

### Step 6: Check Test Coverage

```bash
forge coverage
```

### Step 7: Format Code

```bash
forge fmt
```

## 📝 Key Test Contracts

### 1. ReputationManager Tests
Tests the new 3-tier system:
- **Tier 1 (Passport)**: Individual investors - Treasury + Vault investments
- **Tier 2 (LimitedPartner)**: LP holders - Pool access + Vault investments
- **Tier 3 (VaultCreator)**: Vault holders - Vault creation + All privileges

```bash
forge test --match-contract ReputationManager -vvv
```

### 2. VeriffVerifier Tests
Tests human-approved KYC/KYB verification:
```bash
forge test --match-contract VeriffVerifier -vvv
```

### 3. TreasuryFactory Tests
Tests personal USDC treasury system:
```bash
forge test --match-contract TreasuryFactory -vvv
```

### 4. CompliantLPHook Tests
Tests Uniswap V4 hook with Tier 2+ access:
```bash
forge test --match-contract CompliantLPHook -vvv
```

### 5. VaultFlow Tests
Tests end-to-end vault creation and investment:
```bash
forge test --match-contract VaultFlow -vvv
```

## 🔧 Common Commands

### Clean Build Artifacts
```bash
forge clean
```

### Update Dependencies
```bash
forge update
```

### Run Local Blockchain (Anvil)
```bash
anvil
```

### Deploy to Local Network
```bash
forge script script/DeployAll.s.sol --rpc-url http://localhost:8545 --broadcast
```

### Deploy to Testnet (e.g., Base Sepolia)
```bash
forge script script/DeployAll.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $BASESCAN_API_KEY
```

## 📦 Project Structure

```
convexo_contracts/
├── src/
│   ├── contracts/              # Main contracts
│   │   ├── ReputationManager.sol
│   │   ├── VeriffVerifier.sol
│   │   ├── TreasuryFactory.sol
│   │   ├── TreasuryVault.sol
│   │   ├── TokenizedBondVault.sol
│   │   └── Convexo_Passport.sol
│   ├── convexolps.sol          # Convexo_LPs NFT
│   ├── convexovaults.sol       # Convexo_Vaults NFT
│   ├── hooks/                  # Uniswap V4 Hooks
│   │   └── CompliantLPHook.sol
│   └── interfaces/             # Contract interfaces
├── test/                       # Test files
│   ├── ReputationManagerPassport.t.sol
│   ├── VeriffVerifier.t.sol
│   ├── TreasuryFactory.t.sol
│   ├── CompliantLPHook.t.sol
│   └── VaultFlow.t.sol
├── script/                     # Deployment scripts
│   └── DeployAll.s.sol
├── foundry.toml                # Foundry configuration
└── README.md                   # Project documentation
```

## 🎯 New Features (January 2026)

### 1. **Reorganized Tier System**
- Removed mutual exclusivity - users can hold multiple NFTs
- Highest tier wins approach
- Progressive KYC path (individual → business)

### 2. **VeriffVerifier Contract**
- Human-approved KYC/KYB verification
- Admin workflow for approvals
- Mints Convexo_LPs NFT (Tier 2)

### 3. **Treasury System**
- TreasuryFactory for creating personal treasuries
- TreasuryVault with multi-signature support
- USDC reserve management for Tier 1+ users

### 4. **Enhanced Access Control**
- Vault creation requires Tier 3 (was Tier 2)
- Vault investment requires Tier 1+ (was NO restriction!)
- LP pool access requires Tier 2+ (unchanged)

## 🧪 Running Specific Test Suites

### Quick Tests (Core Functionality)
```bash
forge test --match-contract "ReputationManager|VeriffVerifier|TreasuryFactory" -vv
```

### Full Integration Tests
```bash
forge test --match-contract "VaultFlow" -vvv
```

### Gas Optimization Tests
```bash
forge test --gas-report --match-contract "TokenizedBondVault"
```

## 🐛 Troubleshooting

### Issue: "Compiler version not found"
```bash
foundryup
forge build --force
```

### Issue: "Library not found"
```bash
forge install
git submodule update --init --recursive
```

### Issue: "Out of gas"
Increase gas limit in `foundry.toml`:
```toml
[profile.default]
gas_limit = "18446744073709551615"
```

### Issue: "Stack too deep"
Enable via-ir in `foundry.toml`:
```toml
[profile.default]
via_ir = true
```

## 📊 Expected Test Results

After fixing all compilation errors, you should see:

```
Ran 100+ tests for all test suites
Suite result: ok. X passed; 0 failed; 0 skipped
```

### Test Breakdown:
- ✅ ReputationManager: 15 tests
- ✅ VeriffVerifier: 20 tests
- ✅ TreasuryFactory: 9 tests
- ✅ CompliantLPHook: 10 tests
- ✅ VaultFlow: 15+ tests
- ✅ Other tests: 30+ tests

## 🔐 Security Notes

1. **Never commit private keys** - Use environment variables
2. **Test on testnets first** - Before mainnet deployment
3. **Audit contracts** - Get professional security audit
4. **Verify contracts** - On block explorers after deployment

## 📚 Additional Resources

- [Foundry Book](https://book.getfoundry.sh/)
- [Solidity Documentation](https://docs.soliditylang.org/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [Convexo Documentation](./README.md)

## 🆘 Need Help?

If tests are failing:
1. Run `forge clean && forge build`
2. Check compiler version matches `foundry.toml`
3. Ensure all dependencies are installed
4. Review error messages carefully
5. Check the specific test file for setup requirements

---

**Last Updated**: January 2026
**Foundry Version**: Latest
**Solidity Version**: ^0.8.27

# 🚀 Convexo Contracts - Quick Start Guide

## ✅ Step-by-Step Commands

### 1. Install Foundry (if not already installed)
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### 2. Navigate to Project
```bash
cd /Users/williammartinez/Documents/convexo/convexoapp/convexo_contracts
```

### 3. Install Dependencies
```bash
forge install
```

### 4. Build Project
```bash
forge build
```

### 5. Run All Tests
```bash
forge test -vvv
```

## 📊 What's Changed (January 2026 Update)

### New Tier System
| Tier | NFT Required | Access |
|------|--------------|--------|
| **Tier 1** | Convexo_Passport | Treasury creation + Vault investments |
| **Tier 2** | Convexo_LPs | LP pool access + Vault investments |
| **Tier 3** | Convexo_Vaults | Vault creation + All Tier 2 privileges |

**Key Change**: Users can now hold multiple NFTs! Highest tier wins.

### New Contracts
1. **VeriffVerifier.sol** - Human-approved KYC/KYB verification
2. **TreasuryFactory.sol** - Factory for creating personal treasuries
3. **TreasuryVault.sol** - Multi-sig USDC treasury vaults

### Updated Contracts
1. **ReputationManager.sol** - New tier hierarchy + helper functions
2. **TokenizedBondVault.sol** - Added Tier 1+ investment access control
3. **VaultFactory.sol** - Requires Tier 3 for vault creation (was Tier 2)
4. **CompliantLPHook.sol** - Uses ReputationManager for Tier 2+ access

## 🧪 Test Individual Components

```bash
# Test reputation system
forge test --match-contract ReputationManager -vvv

# Test verification system
forge test --match-contract VeriffVerifier -vvv

# Test treasury system
forge test --match-contract TreasuryFactory -vvv

# Test LP pool access control
forge test --match-contract CompliantLPHook -vvv

# Test vault flow (end-to-end)
forge test --match-contract VaultFlow -vvv
```

## 🔥 Common Issues & Fixes

### Error: "Compiler version not found"
```bash
foundryup
forge clean
forge build
```

### Error: "Library not found"
```bash
forge install
```

### Error: "Tests failing"
```bash
forge clean
forge build
forge test -vvv
```

## 📁 Key Files

### Core Contracts
- `src/contracts/ReputationManager.sol` - Tier management
- `src/contracts/VeriffVerifier.sol` - KYC/KYB verification
- `src/contracts/TreasuryFactory.sol` - Treasury creation
- `src/contracts/TokenizedBondVault.sol` - Vault with investment gates

### Tests
- `test/ReputationManagerPassport.t.sol` - 15 tests ✅
- `test/VeriffVerifier.t.sol` - 20 tests ✅
- `test/TreasuryFactory.t.sol` - 9 tests ✅
- `test/CompliantLPHook.t.sol` - 10 tests ✅

## 🎯 Expected Output

After running `forge test`, you should see:

```
Ran 100+ tests
Suite result: ok. X passed; 0 failed; 0 skipped
```

## 📚 Next Steps

1. ✅ **Build & Test** - Ensure all tests pass
2. 📝 **Review Changes** - Check `FOUNDRY_SETUP.md` for details
3. 🚀 **Deploy** - Use deployment scripts in `script/`
4. 🔐 **Verify** - Verify contracts on block explorer

## 🆘 Need Help?

Check these files:
- `FOUNDRY_SETUP.md` - Detailed setup guide
- `README.md` - Project documentation
- `~/.claude/plans/validated-bubbling-frog.md` - Implementation plan

---

**Quick Commands Reference:**
```bash
forge build          # Compile contracts
forge test           # Run all tests
forge test -vvv      # Run tests with verbose output
forge clean          # Clean build artifacts
forge fmt            # Format code
forge coverage       # Check test coverage
```

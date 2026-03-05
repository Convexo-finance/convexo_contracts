 Convexo Contracts — v3.17 Plan
                                               
 Context                                     

 Three improvements bundled into a single
 version bump to v3.17:
 1. faceMatchPassed removal — ZKPassport face
 match creates bad UX. The contract never
 enforced it (no require), so removing the
 param cleans the API and signals to users
 that face match is not a requirement.
 2. Treasury deprecation — TreasuryFactory +
 TreasuryVault duplicate Gnosis Safe
 functionality without unique protocol value.
 Remove entirely to reduce deployment surface.
 3. Arbitrum deployment — Expand to Arbitrum
 Sepolia (421614) + Arbitrum One (42161).
 Uniswap V4 is live on both.
 4. Folder reorganization — Flat
 src/contracts/ → three semantic subfolders:
 identity/, credits/, trading/.

 Version bump: "convexo.v3.16" →
 "convexo.v3.17" = new CREATE2 salt = new
 addresses on ALL chains.
 Note to Frontend Agent: faceMatchPassed param
  is removed from safeMintWithVerification()
 and from VerifiedIdentity struct — update
 types and SDK integration.

 ---
 Files to Delete

 src/contracts/TreasuryFactory.sol
 src/contracts/TreasuryVault.sol

 New Folder Structure for src/contracts/

 src/contracts/
   identity/
     Convexo_Passport.sol
     VeriffVerifier.sol
     SumsubVerifier.sol
     Limited_Partners_Individuals.sol
     Limited_Partners_Business.sol
     ReputationManager.sol
   credits/
     Ecreditscoring.sol
     TokenizedBondVault.sol
     VaultFactory.sol
     ContractSigner.sol
   trading/
     PoolRegistry.sol
     PriceFeedManager.sol
 src/interfaces/ — stays flat (no subfolder
 change).
 src/hooks/ — no change.

 ---
 Step-by-Step Changes

 1. src/interfaces/IConvexoPassport.sol

 - Remove bool faceMatchPassed from
 VerifiedIdentity struct
 - Remove bool faceMatchPassed param from
 safeMintWithVerification() signature
 - Remove bool faceMatchPassed from
 PassportMinted event

 2. src/contracts/Convexo_Passport.sol → move
 to src/contracts/identity/

 - Update import:
 ../interfaces/IConvexoPassport.sol →
 ../../interfaces/IConvexoPassport.sol
 - Remove bool faceMatchPassed param from
 safeMintWithVerification()
 - Remove faceMatchPassed: faceMatchPassed
 from VerifiedIdentity struct assignment
 - Remove faceMatchPassed from PassportMinted
 emit

 3. src/contracts/ReputationManager.sol → move
  to src/contracts/identity/

 - Update import:
 ../interfaces/IConvexoPassport.sol →
 ../../interfaces/IConvexoPassport.sol
 - Remove canCreateTreasury() function and its
  NatSpec comment
 - Update access matrix comment (remove
 Treasury column)

 4. src/contracts/VeriffVerifier.sol → move to
  src/contracts/identity/

 - Update import:
 ../interfaces/ILimitedPartnersIndividuals.sol
  → ../../interfaces/ILimitedPartnersIndividua
 ls.sol

 5. src/contracts/SumsubVerifier.sol → move to
  src/contracts/identity/

 - Update import:
 ../interfaces/ILimitedPartnersBusiness.sol →
 ../../interfaces/ILimitedPartnersBusiness.sol

 6. src/contracts/Limited_Partners_Individuals
 .sol → move to src/contracts/identity/

 - Update import:
 ../interfaces/IVeriffVerifier.sol →
 ../../interfaces/IVeriffVerifier.sol
 - All OZ imports stay as-is (remapping-based,
  not relative)

 7.
 src/contracts/Limited_Partners_Business.sol →
  move to src/contracts/identity/

 - Update import:
 ../interfaces/ISumsubVerifier.sol →
 ../../interfaces/ISumsubVerifier.sol

 8. src/contracts/Ecreditscoring.sol → move to
  src/contracts/credits/

 - Update import:
 ../interfaces/IEcreditscoring.sol →
 ../../interfaces/IEcreditscoring.sol (if
 used)
 - All OZ imports stay as-is

 9. src/contracts/TokenizedBondVault.sol →
 move to src/contracts/credits/

 - Update import:
 ../interfaces/IContractSigner.sol →
 ../../interfaces/IContractSigner.sol
 - Update import: ./ReputationManager.sol →
 ../identity/ReputationManager.sol

 10. src/contracts/VaultFactory.sol → move to
 src/contracts/credits/

 - Update import: ./TokenizedBondVault.sol →
 ./TokenizedBondVault.sol (same folder ✓)
 - Update import: ./ContractSigner.sol →
 ./ContractSigner.sol (same folder ✓)
 - Update import: ./ReputationManager.sol →
 ../identity/ReputationManager.sol

 11. src/contracts/ContractSigner.sol → move
 to src/contracts/credits/

 - No contract imports, only OZ — no changes
 needed

 12. src/contracts/PoolRegistry.sol → move to
 src/contracts/trading/

 - No contract imports, only OZ — no changes
 needed

 13. src/contracts/PriceFeedManager.sol → move
  to src/contracts/trading/

 - Update import:
 ../interfaces/IAggregatorV3.sol →
 ../../interfaces/IAggregatorV3.sol

 ---
 14. script/DeployDeterministic.s.sol

 Update all contract imports:
 // identity/
 import {Convexo_Passport} from "../src/contra
 cts/identity/Convexo_Passport.sol";
 import {Limited_Partners_Individuals} from
 "../src/contracts/identity/Limited_Partners_I
 ndividuals.sol";
 import {Limited_Partners_Business} from
 "../src/contracts/identity/Limited_Partners_B
 usiness.sol";
 import {ReputationManager} from "../src/contr
 acts/identity/ReputationManager.sol";
 import {VeriffVerifier} from "../src/contract
 s/identity/VeriffVerifier.sol";
 import {SumsubVerifier} from "../src/contract
 s/identity/SumsubVerifier.sol";

 // credits/
 import {Ecreditscoring} from "../src/contract
 s/credits/Ecreditscoring.sol";
 import {VaultFactory} from
 "../src/contracts/credits/VaultFactory.sol";
 import {ContractSigner} from "../src/contract
 s/credits/ContractSigner.sol";

 // trading/
 import {PoolRegistry} from
 "../src/contracts/trading/PoolRegistry.sol";
 import {PriceFeedManager} from "../src/contra
 cts/trading/PriceFeedManager.sol";
 Remove: import {TreasuryFactory} and import
 {TreasuryVault} (deleted contracts)

 Bump version:
 string public constant DEFAULT_VERSION =
 "convexo.v3.17";

 Add Arbitrum to getNetworkConfig():
 } else if (chainId == 421614) {
     networkName = "Arbitrum Sepolia";
     poolManager =
 vm.envOr("POOL_MANAGER_ADDRESS_ARBSEPOLIA",
 0xFB3e0C6F74eB1a21CC1Da29aeC80D2Dfe6C9a317);
     usdc =
 vm.envOr("USDC_ADDRESS_ARBSEPOLIA",
 0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d);
 } else if (chainId == 42161) {
     networkName = "Arbitrum One";
     poolManager =
 vm.envOr("POOL_MANAGER_ADDRESS_ARBONE",
 0x360e68faccca8ca495c1b759fd9eee466db9fb32);
     usdc = vm.envOr("USDC_ADDRESS_ARBONE",
 0xaf88d065e77c8cC2239327C5EDb3A432268e5831);
 }
 Remove from run(): treasuryFactory deploy
 block (the if (usdc != address(0)) {
 treasuryFactory = deployIfNeeded(...) }
 section — keep vaultFactory block, only
 remove treasuryFactory)
 Remove: console.log("TreasuryFactory:",
 treasuryFactory) from summary

 ---
 15. foundry.toml

 Add under [rpc_endpoints]:
 arbitrum_sepolia =
 "${ARBITRUM_SEPOLIA_RPC_URL}"
 arbitrum_mainnet =
 "${ARBITRUM_MAINNET_RPC_URL}"
 Add under [etherscan]:
 arbitrum_sepolia = { key =
 "${ARBISCAN_API_KEY}", chain = 421614, url =
 "https://api-sepolia.arbiscan.io/api" }
 arbitrum_mainnet = { key =
 "${ARBISCAN_API_KEY}", chain = 42161, url =
 "https://api.arbiscan.io/api" }

 ---
 16. scripts/deploy.sh

 Add two cases to the case $NETWORK in block:
 "arbitrum-sepolia")
     CHAIN_NAME="Arbitrum Sepolia"
     CHAIN_ID="421614"
     RPC_VAR="ARBITRUM_SEPOLIA_RPC_URL"
     RPC_FALLBACK="https://sepolia-rollup.arbi
 trum.io/rpc"
     EXPLORER="https://sepolia.arbiscan.io"
     IS_MAINNET=false
     EXTRA_FLAGS=""
     ;;
 "arbitrum")
     CHAIN_NAME="Arbitrum One"
     CHAIN_ID="42161"
     RPC_VAR="ARBITRUM_MAINNET_RPC_URL"

 RPC_FALLBACK="https://arb1.arbitrum.io/rpc"
     EXPLORER="https://arbiscan.io"
     IS_MAINNET=true
     EXTRA_FLAGS=""
     ;;
 Update usage help text to list
 arbitrum-sepolia and arbitrum.

 ---
 17. scripts/verify-all.sh

 Add to case $CHAIN_ID in block:
 42161|421614)
     API_KEY="$ARBISCAN_API_KEY"
     VERIFIER="etherscan"
     ;;
 Remove TREASURY_FACTORY variable and its
 verify_contract call.
 Fix existing bug: Passport constructor args
 use wrong 3-arg encode — should be:
 ARGS=$(cast abi-encode
 "constructor(address,string)" "$ADMIN"
 "$METADATA_URI")
 Update all src/contracts/ContractName.sol
 paths to include subfolder (e.g.
 src/contracts/identity/Convexo_Passport.sol).

 ---
 18. .env.example

 Add:
 ARBITRUM_SEPOLIA_RPC_URL=
 ARBITRUM_MAINNET_RPC_URL=
 ARBISCAN_API_KEY=

 ---
 19. Test files in test/

 Update imports in all 7 test files to new
 subfolder paths:
 - ConvexoPassport.t.sol → ../src/contracts/id
 entity/Convexo_Passport.sol
 - Ecreditscoring.t.sol →
 ../src/contracts/credits/Ecreditscoring.sol
 - LimitedPartnersBusiness.t.sol → ../src/cont
 racts/identity/Limited_Partners_Business.sol
 - LimitedPartnersIndividuals.t.sol →
 ../src/contracts/identity/Limited_Partners_In
 dividuals.sol
 - ReputationManager.t.sol → ../src/contracts/
 identity/ReputationManager.sol
 - SumsubVerifier.t.sol →
 ../src/contracts/identity/SumsubVerifier.sol
 - VeriffVerifier.t.sol →
 ../src/contracts/identity/VeriffVerifier.sol

 Remove any test calls to canCreateTreasury()
 in ReputationManager tests.
 Update safeMintWithVerification() calls in
 ConvexoPassport.t.sol to drop the
 faceMatchPassed arg.

 ---
 20. README.md

 - Update version badge: 3.0 → 3.17
 - Update badges: add Arbitrum One + Arbitrum
 Sepolia deployed badges
 - Remove "Personal Treasuries" section from
 Key Features
 - Update Deployments section (add Arbitrum
 table rows with contract counts and explorer
 links after deployment)
 - Remove treasury_factory from contract count
  references

 ---
 21. CONTRACTS_REFERENCE.md

 - Remove TreasuryFactory and TreasuryVault
 sections
 - Remove canCreateTreasury from
 ReputationManager read functions table
 - Update safeMintWithVerification() signature
  (remove faceMatchPassed)
 - Remove faceMatchPassed from
 VerifiedIdentity struct docs
 - Remove faceMatchPassed from PassportMinted
 event docs

 ---
 22. FRONTEND_INTEGRATION.md +
 ZKPASSPORT_FRONTEND_INTEGRATION.md

 - Update safeMintWithVerification() code
 examples — remove faceMatchPassed param
 - Remove TreasuryFactory/TreasuryVault
 import/hook examples
 - Add note: "Arbitrum One (42161) and
 Arbitrum Sepolia (421614) now supported"

 ---
 23. addresses.json (after deployment)

 Add entries for chainId "421614" and "42161"
 with version "convexo.v3.17".
 Also update existing 5 chains to version
 "convexo.v3.17" and new addresses after
 redeploy.
 Remove treasury_factory key from all chain
 entries.

 ---
 24. Update Contracts Agent memory
 (/memory/contracts-agent.md)

 After everything is done:
 - Remove faceMatchPassed from function
 signature docs
 - Remove TreasuryFactory / TreasuryVault
 entries
 - Remove canCreateTreasury from
 ReputationManager section
 - Add Arbitrum chains to supported chains
 table
 - Add Arbitrum pool manager addresses
 - Update contract count to 12 (was 14, minus
 2 Treasury)

 ---
 Deployment Order After Code Changes

 1. forge build  (verify no compile errors)
 2. forge test   (all 87 tests should pass,
 minus Treasury tests if any)
 3. ./scripts/deploy.sh arbitrum-sepolia
 4. ./scripts/update-addresses.sh 421614
 5. ./scripts/verify-all.sh 421614
 6. ./scripts/deploy.sh arbitrum   (mainnet -
 requires manual confirmation)
 7. ./scripts/update-addresses.sh 42161
 8. ./scripts/verify-all.sh 42161
 9. Redeploy existing 5 chains with v3.17
 (addresses will change due to version bump)
    ./scripts/deploy.sh unichain-sepolia
    ./scripts/deploy.sh base-sepolia
    ./scripts/deploy.sh ethereum-sepolia
    ./scripts/deploy.sh unichain
    ./scripts/deploy.sh base
 10. ./scripts/extract-abis.sh  (regenerate
 abis/ folder)

 Verification Checklist

 - forge build — zero errors
 - forge test — all tests pass
 - cast call <passport> "safeMintWithVerificat
 ion(string,bytes32,bool,bool,string)" ... — 5
  args (no faceMatchPassed)
 - cast call <reputation>
 "canCreateTreasury(address)" — reverts
 (function removed)
 - Arbitrum Sepolia: all 12 contracts
 deployed, verified on sepolia.arbiscan.io
 - Arbitrum One: all 12 contracts deployed,
 verified on arbiscan.io
 - addresses.json contains chainId 421614 and
 42161 with correct addresses
 - abis/ updated (Convexo_Passport.json no
 longer has faceMatchPassed in ABI)

 Frontend Agent coordination needed

 After implementation, notify Frontend Agent
 of:
 1. safeMintWithVerification() now takes 5
 args (drop faceMatchPassed)
 2. VerifiedIdentity struct no longer has
 faceMatchPassed field
 3. Two new supported chains: 42161, 421614
 4. canCreateTreasury() removed from
 ReputationManager ABI
 5. New contract addresses on all chains
 (v3.17 salt change)
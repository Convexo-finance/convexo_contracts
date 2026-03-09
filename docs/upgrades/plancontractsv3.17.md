 Convexo Contracts — v3.17 Plan

 Context

 Five improvements bundled into a single
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
 5. ZKPassport on-chain verification (TRUSTLESS
 SELF-CLAIM) — The critical security upgrade.
 Replace safeMintWithVerification() trusted
 boolean values with on-chain ZK proof
 verification via IZKPassportVerifier.
 The Convexo_Passport can ONLY be self-claimed
 by users holding a valid ZKPassport ZK proof.
 No MINTER_ROLE exists for Convexo_Passport —
 no admin can mint on behalf of a user.
 The ZKPassport verifier contract at
 0x1D000001000EFD9a6371f4d90bB8920D5431c0D8
 validates the ZK proof cryptographically.
 The proof is bound to msg.sender + block.chainid
 preventing replay attacks and cross-chain reuse.
 uniqueIdentifier returned by verifier (bytes32)
 — not from caller input — sybil resistance is
 now cryptographic, not just a string check.
 Chain strategy: verifier deployed on Base +
 Ethereum. Contracts exist on all 8 chains so
 claimPassport will work as ZKPassport expands
 their verifier. Frontend gated to Base/Ethereum.

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
 ZK ON-CHAIN VERIFICATION (Change #5)
 Steps 25–31 — Must complete BEFORE deployment

 ---
 25. NEW FILE: src/interfaces/IZKPassportVerifier.sol

 Create complete interface with all structs and
 interfaces used by claimPassport():

 Structs to define:
   struct ProofVerificationParams {
     bytes32 version;
     ProofVerificationData proofVerificationData;
     bytes committedInputs;
     ServiceConfig serviceConfig;
   }
   struct ProofVerificationData {
     bytes32 vkeyHash;
     bytes proof;
     bytes32[] publicInputs;
   }
   struct ServiceConfig {
     uint256 validityPeriodInSeconds;
     string domain;
     string scope;
     bool devMode;
   }
   struct BoundData {
     address senderAddress;
     uint256 chainId;
     string customData;
   }

 Interfaces to define:
   interface IZKPassportVerifier {
     function verify(ProofVerificationParams calldata)
       external returns (
         bool verified,
         bytes32 uniqueIdentifier,
         IZKPassportHelper helper
       );
   }
   interface IZKPassportHelper {
     function verifyScopes(bytes32[] calldata, string calldata, string calldata) external pure returns (bool);
     function getBoundData(bytes calldata) external pure returns (BoundData memory);
     function isAgeAboveOrEqual(uint8, bytes calldata) external pure returns (bool);
     function isSanctionsRootValid(uint256, bool, bytes calldata) external pure returns (bool);
     function isExpiryDateAfterOrEqual(uint256, bytes calldata) external pure returns (bool);
     function isNationalityOut(string[] memory, bytes calldata) external pure returns (bool);
     function getProofTimestamp(bytes32[] calldata) external pure returns (uint256);
   }

 ---
 26. src/interfaces/IConvexoPassport.sol

 Add import:
   import {IZKPassportVerifier, ProofVerificationParams} from "./IZKPassportVerifier.sol";

 Update VerifiedIdentity struct — add new fields
 that capture all 4 ZKPassport verification docs:
   struct VerifiedIdentity {
     bytes32 identifierHash;      // uniqueIdentifier from verifier (personhood.md)
     bytes32 personhoodProof;     // vkeyHash from proof (personhood.md)
     uint256 verifiedAt;          // block.timestamp
     uint256 zkPassportTimestamp; // from helper.getProofTimestamp() (age18.md)
     bool isActive;
     bool kycVerified;            // sanctionsPassed && isOver18 (kyc.md)
     bool sanctionsPassed;        // helper.isSanctionsRootValid() (kyc.md)
     bool isOver18;               // helper.isAgeAboveOrEqual(18) (age18.md)
     bool nationalityCompliant;   // helper.isNationalityOut(SANCTIONED_COUNTRIES) (nationality.md)
   }

 Replace safeMintWithVerification signature with:
   function claimPassport(
     ProofVerificationParams calldata zkParams,
     bool isIDCard,
     string calldata ipfsMetadataHash
   ) external returns (uint256 tokenId);

 Update isIdentifierUsed to accept bytes32 directly:
   function isIdentifierUsed(bytes32 identifierHash)
     external view returns (bool);
   (verifier already returns bytes32 — no need
   for the contract to re-hash a string)

 ---
 27. src/contracts/identity/Convexo_Passport.sol

 A) Constants and immutable:
   IZKPassportVerifier public immutable ZKPASSPORT_VERIFIER;
   string public constant APP_DOMAIN = "protocol.convexo.xyz";
   string public constant APP_SCOPE  = "convexo-passport-identity";

   // Hardcoded sanctioned countries list (same as
   // SANCTIONED_COUNTRIES from @zkpassport/sdk)
   // Used in isNationalityOut() helper call
   string[] private _SANCTIONED_COUNTRIES = [
     "AFG","BLR","CAF","COD","CUB","IRN","IRQ",
     "LBY","MLI","MMR","NIC","PRK","RUS","SDN",
     "SOM","SSD","SYR","VEN","YEM","ZWE"
   ];
   (Exact list to verify against SDK source)

 B) Constructor — add verifier param:
   constructor(
     address admin,
     string memory initialBaseURI,
     address _zkPassportVerifier
   )
   Remove MINTER_ROLE entirely — no admin minting
   path for Convexo_Passport.

 C) Replace safeMintWithVerification with:
   function claimPassport(
     ProofVerificationParams calldata zkParams,
     bool isIDCard,
     string calldata ipfsMetadataHash
   ) external returns (uint256 tokenId) {

     // 1. On-chain ZK proof verification
     (bool verified, bytes32 uniqueIdentifier, IZKPassportHelper helper)
       = ZKPASSPORT_VERIFIER.verify(zkParams);
     if (!verified) revert ProofVerificationFailed();

     // 2. Domain + scope binding (proves proof is for Convexo)
     require(
       helper.verifyScopes(
         zkParams.proofVerificationData.publicInputs,
         APP_DOMAIN, APP_SCOPE
       ), "InvalidScope"
     );

     // 3. Address binding (proof belongs to this specific caller)
     BoundData memory bound = helper.getBoundData(zkParams.committedInputs);
     require(bound.senderAddress == msg.sender, "InvalidSender");

     // 4. Chain binding (no cross-chain replay)
     require(bound.chainId == block.chainid, "InvalidChain");

     // 5. Age verification — from age18.md (no birthdate stored)
     bool isOver18 = helper.isAgeAboveOrEqual(18, zkParams.committedInputs);
     if (!isOver18) revert AgeVerificationFailed();

     // 6. Sanctions check — from kyc.md (US, UK, EU, CH lists)
     uint256 proofTimestamp = helper.getProofTimestamp(
       zkParams.proofVerificationData.publicInputs
     );
     bool sanctionsPassed = helper.isSanctionsRootValid(
       proofTimestamp, false, zkParams.committedInputs
     );
     if (!sanctionsPassed) revert SanctionsCheckFailed();

     // 7. Nationality exclusion — from nationality.md
     // Proves not from sanctioned country without disclosing nationality
     bool nationalityCompliant = helper.isNationalityOut(
       _SANCTIONED_COUNTRIES, zkParams.committedInputs
     );
     if (!nationalityCompliant) revert NationalityNotCompliant();

     // 8. Document expiry — proof that passport is not expired
     // Not stored — just enforced. From zkpassport expiry check.
     require(
       helper.isExpiryDateAfterOrEqual(block.timestamp, zkParams.committedInputs),
       "PassportExpired"
     );

     // 9. Sybil resistance — uniqueIdentifier from verifier
     // (not from caller input — cryptographically unforgeable)
     if (passportIdentifierToAddress[uniqueIdentifier] != address(0))
       revert IdentifierAlreadyUsed();
     if (balanceOf(msg.sender) > 0)
       revert AlreadyHasPassport();

     // 10. Mint
     tokenId = _nextTokenId++;
     _safeMint(msg.sender, tokenId);
     if (bytes(ipfsMetadataHash).length > 0) {
       _setTokenURI(tokenId, string(abi.encodePacked(
         "https://lime-famous-condor-7.mypinata.cloud/ipfs/",
         ipfsMetadataHash
       )));
     }

     // 11. Store enriched VerifiedIdentity (4-doc coverage, zero PII)
     verifiedUsers[msg.sender] = VerifiedIdentity({
       identifierHash:      uniqueIdentifier,           // personhood.md
       personhoodProof:     zkParams.proofVerificationData.vkeyHash, // personhood.md
       verifiedAt:          block.timestamp,
       zkPassportTimestamp: proofTimestamp,             // age18.md
       isActive:            true,
       kycVerified:         sanctionsPassed && isOver18, // kyc.md
       sanctionsPassed:     sanctionsPassed,             // kyc.md
       isOver18:            isOver18,                    // age18.md
       nationalityCompliant: nationalityCompliant        // nationality.md
     });

     passportIdentifierToAddress[uniqueIdentifier] = msg.sender;
     activePassportCount++;

     emit PassportMinted(
       msg.sender, tokenId,
       uniqueIdentifier,
       zkParams.proofVerificationData.vkeyHash,
       true, sanctionsPassed, isOver18
     );
   }

 D) Update isIdentifierUsed to accept bytes32:
   function isIdentifierUsed(bytes32 identifierHash)
     external view returns (bool) {
     return passportIdentifierToAddress[identifierHash] != address(0);
   }

 E) New custom errors:
   error AgeVerificationFailed();
   error SanctionsCheckFailed();
   error NationalityNotCompliant();

 F) Remove: MINTER_ROLE bytes32 constant and
    all _grantRole(MINTER_ROLE, ...) calls.

 ---
 28. script/DeployDeterministic.s.sol

 Update Convexo_Passport deployment:
   passport = Convexo_Passport(deployIfNeeded(
     "Convexo_Passport",
     abi.encodePacked(
       type(Convexo_Passport).creationCode,
       abi.encode(
         admin,
         METADATA_URI_PASSPORT,
         address(0x1D000001000EFD9a6371f4d90bB8920D5431c0D8) // ZKPassport verifier
       )
     )
   ));

 The verifier address is deterministic (same on
 all chains where ZKPassport is deployed).
 On chains without verifier yet (Unichain,
 Arbitrum), claimPassport() will revert with
 a low-level call failure — frontend gates
 those chains so users never see the error.

 ---
 29. Frontend: app/digital-id/humanity/verify/page.tsx

 A) Add mode and document_type to queryBuilder:
   const queryBuilder = await zkPassport.request({
     name: 'CONVEXO PASSPORT Verification',
     logo: ...,
     purpose: 'Verify identity for CONVEXO PASSPORT',
     scope: APP_SCOPE_STRING,
     mode: 'compressed-evm',   // ← REQUIRED for on-chain
   });

   let capturedProof: any;    // typed as ProofResult

   const { url, onProofGenerated, onResult } = queryBuilder
     .gte('age', 18)                        // age18.md
     .sanctions()                           // kyc.md
     .out('nationality', SANCTIONED_COUNTRIES) // nationality.md
     .disclose('document_type')             // needed for isIDCard
     .bind('user_address', address)         // anti-replay
     .bind('chain', zkChainName)            // anti cross-chain replay
     .done();

   // CRITICAL: capture proof in onProofGenerated,
   // NOT in onResult (current code gets undefined)
   onProofGenerated((proofResult) => {
     capturedProof = proofResult;
   });

 B) In onResult callback:
   onResult(({ verified, result, uniqueIdentifier }) => {
     if (!verified) { setError('...'); return; }

     // isIDCard from disclosed document_type
     const isIDCard =
       result?.document_type?.disclose?.result !== 'passport';

     // Compute verifier params for contract call
     const verifierParams = zkPassport.getSolidityVerifierParameters({
       proof: capturedProof,
       scope: APP_SCOPE_STRING,
       devMode: false,
     });

     // Store for minting step
     setMintParams({ verifierParams, isIDCard, uniqueIdentifier });
     setStep('verified');
   });

 C) Map chainId to ZKPassport chain name:
   const ZK_CHAIN_NAMES: Record<number, string> = {
     1:     'ethereum',
     11155111: 'ethereum',
     8453:  'base',
     84532: 'base',   // base sepolia (verifier not deployed but chain name ok)
   };
   const zkChainName = ZK_CHAIN_NAMES[chainId] ?? 'ethereum';

 D) handleMint — call claimPassport:
   mintPassport({
     address: contracts.CONVEXO_PASSPORT,
     abi: ConvexoPassportABI,
     functionName: 'claimPassport',
     args: [
       mintParams.verifierParams,   // ProofVerificationParams struct
       mintParams.isIDCard,         // bool
       ipfsMetadataHash             // string
     ],
   });

 E) Update IPFS metadata (pinata.ts):
   Enrich PassportTraits with nationalityCompliant: true
   Add to NFT metadata attributes:
     { trait_type: 'Nationality Compliant', value: 'Yes' }
     { trait_type: 'Document Valid', value: 'Yes' }
   Remove: faceMatchPassed trait (already done in v3.17)

 F) Add import from @zkpassport/sdk:
   import { ZKPassport, SANCTIONED_COUNTRIES } from '@zkpassport/sdk';

 G) Remove state: passportTraits, identifierInput
    Replace with: mintParams { verifierParams, isIDCard, uniqueIdentifier }
    Remove: manual boolean extraction from onResult
    Remove: identifierUsed read contract (bytes32 lookup now)

 H) Add chain gate: show ZKPassport flow only on
    chainId 1, 11155111, 8453, 84532 (where ZKPassport
    verifier is deployed or frontend is configured).
    Show message for other chains.

 ---
 30. ABI updates after contract changes

 abis/Convexo_Passport.json:
   - Remove safeMintWithVerification entry
   - Add claimPassport(ProofVerificationParams,bool,string) entry
     (ProofVerificationParams is a tuple with nested structs)
   - Add nationalityCompliant field to getVerifiedIdentity struct
   - Update isIdentifierUsed input from string to bytes32
   - Add new errors: AgeVerificationFailed, SanctionsCheckFailed,
     NationalityNotCompliant

 abis/combined.json:
   - Sync all above changes

 lib/contracts/abis.ts:
   - Add ProofVerificationParams TypeScript type
   - Update ConvexoPassportABI array
   - Update VerifiedIdentity interface (add nationalityCompliant: bool)
   - Export ProofVerificationParams type for verify/page.tsx

 ---
 31. test/ConvexoPassport.t.sol

 A) Deploy MockZKPassportVerifier in setUp():
   - Mock returns (true, testUniqueId, mockHelper)
   - mockHelper returns:
     - verifyScopes: true
     - getBoundData: BoundData(testUser, block.chainid, "")
     - isAgeAboveOrEqual(18): true
     - isSanctionsRootValid: true
     - isNationalityOut: true
     - isExpiryDateAfterOrEqual: true
     - getProofTimestamp: block.timestamp

 B) Update all test calls:
   - Replace safeMintWithVerification(string,...) calls
     with claimPassport(mockParams, false, "ipfsHash")
   - Add test: wrong sender → revert InvalidSender
   - Add test: wrong chainId → revert InvalidChain
   - Add test: age fail → revert AgeVerificationFailed
   - Add test: sanctions fail → revert SanctionsCheckFailed
   - Add test: nationality fail → revert NationalityNotCompliant
   - Add test: expired passport → revert
   - Existing sybil test: same uniqueId → IdentifierAlreadyUsed
   - Existing duplicate test: same wallet → AlreadyHasPassport

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
 - Document claimPassport() replacing
   safeMintWithVerification()
 - Document IZKPassportVerifier interface
 - Document 4-doc enrichment of VerifiedIdentity

 ---
 Deployment Order After Code Changes

 1. forge build  (verify no compile errors)
 2. forge test   (all tests pass incl. mock ZK)
 3. ./scripts/deploy.sh ethereum-sepolia
 4. ./scripts/deploy.sh base-sepolia
 5. ./scripts/update-addresses.sh 11155111
 6. ./scripts/update-addresses.sh 84532
 7. Validate claimPassport() works on testnet
    (E2E: ZKPassport app → proof → contract)
 8. ./scripts/deploy.sh base
 9. ./scripts/deploy.sh ethereum
 10. ./scripts/deploy.sh unichain-sepolia
 11. ./scripts/deploy.sh unichain
 12. ./scripts/deploy.sh arbitrum-sepolia
 13. ./scripts/deploy.sh arbitrum
 14. ./scripts/update-addresses.sh for all chains
 15. ./scripts/verify-all.sh for all chains
 16. ./scripts/extract-abis.sh

 Note: Deploy Base+Ethereum first (ZKPassport
 verifier live there) for E2E testing before
 deploying to chains where verifier is pending.

 Verification Checklist

 - forge build — zero errors
 - forge test — all tests pass (new mock ZK tests)
 - cast call <passport> "claimPassport(...)" —
   reverts with ProofVerificationFailed (no valid proof)
 - cast call <passport> "safeMintWithVerification(...)" —
   reverts (function removed)
 - E2E test on Base Sepolia: ZKPassport app →
   scan → proof → claimPassport tx → NFT minted
 - getVerifiedIdentity returns nationalityCompliant: true
 - isIdentifierUsed(bytes32) works correctly
 - Reputation tier 1 gated correctly post-mint
 - Arbitrum Sepolia: all 12 contracts deployed,
   verified on sepolia.arbiscan.io
 - Arbitrum One: all 12 contracts deployed,
   verified on arbiscan.io
 - addresses.json contains chainId 421614 and
   42161 with correct addresses
 - abis/ updated (claimPassport in ABI, not
   safeMintWithVerification)

 Frontend Agent coordination needed

 After implementation, notify Frontend Agent of:
 1. safeMintWithVerification() REMOVED entirely
    — replaced by claimPassport(ProofVerificationParams, bool, string)
 2. VerifiedIdentity struct has new field:
    nationalityCompliant: bool
 3. isIdentifierUsed() now takes bytes32 (not string)
 4. Two new supported chains: 42161, 421614
 5. canCreateTreasury() removed from ReputationManager ABI
 6. New contract addresses on all chains (v3.17 salt)
 7. Frontend must add mode:"compressed-evm" + bindings
    + onProofGenerated capture + SANCTIONED_COUNTRIES import
 8. ZKPassport minting gated to Base + Ethereum only
    (chainId 1, 11155111, 8453, 84532)

 ZKPassport On-Chain Security Model Summary

 BEFORE (v3.16):
   User controls: uniqueIdentifier (string), sanctionsPassed (bool),
   isOver18 (bool) — all trusted from frontend, zero on-chain proof.
   Attack: call safeMintWithVerification("x", 0x0, true, true, "ipfs")
   directly on-chain. No ZKPassport needed.

 AFTER (v3.17):
   User controls: ProofVerificationParams (ZK proof blob), isIDCard, ipfsHash
   Contract calls ZKPassport verifier at 0x1D000001000EFD9a6371f4d90bB8920D5431c0D8
   Cryptographic guarantees:
   - uniqueIdentifier from verifier (Poseidon2 of passport data + domain + scope)
   - msg.sender bound in proof (no proxy minting)
   - block.chainid bound in proof (no cross-chain replay)
   - age >= 18 verified by ZK circuit (no birthdate stored)
   - sanctions checked against US/UK/EU/CH lists (kyc.md)
   - nationality not in sanctioned countries (nationality.md)
   - passport not expired (document validity enforced)
   - 1 passport document = 1 NFT (sybil resistance via identifierHash)
   No admin can bypass — no MINTER_ROLE on Convexo_Passport.

 ---
 Vault Economics Redesign (COMPLETED — 122 tests passing)

 Problem with previous design:
   - No share quantity defined by borrower (share price was implicit)
   - No minimum investment floor
   - purchaseShares/redeemShares were synchronous — not ERC-7540
   - Redemption was only possible after 100% repayment
   - convertToAssets used vault USDC balance → price affected by redemptions

 Solution implemented:

 VaultFactory.createVault() now takes:
   totalShareSupply — number of whole shares (e.g. 1000)
   minInvestment    — minimum USDC per deposit (e.g. 100e6 = $100)

 Share price model (3 prices, all deterministic):
   baseSharePrice        = principalAmount / totalShareSupply
   expectedFinalPrice    = (principal + interest - fee) / totalShareSupply
   currentSharePrice     = basePrice + (finalPrice - basePrice) × repaidFraction
     repaidFraction      = totalRepaid / totalDue
     → price rises monotonically; unaffected by redemptions

 ERC-7540 async redemption:
   requestRedeem(shares) → locks shares (requestId = 0 always)
   claimableRedeemRequest(0, controller) → returns remainingLockedShares
   redeem(shares, receiver, controller):
     claimableNow = totalEntitlement × repaidFraction - assetsClaimed
     sharesToBurn = remainingLockedShares × assets / remainingEntitlement
     → proportional burn prevents stranded funds
     → can call multiple times as repayments accumulate

 Guards added to VaultFactory:
   principalAmount >= totalShareSupply × 1e6  (share price ≥ $1)
   totalShareSupply > 0
   minInvestment > 0

 Files changed:
   src/contracts/credits/TokenizedBondVault.sol — full rewrite
   src/contracts/credits/VaultFactory.sol       — createVault() + guards
   src/interfaces/ITokenizedBondVault.sol        — new full interface
   test/TokenizedBondVault.t.sol                 — 28 tests
   test/VaultFactory.t.sol                       — 7 tests
   abis/ (all regenerated via extract-abis.sh)
   convexo_frontend/abis/ (synced)
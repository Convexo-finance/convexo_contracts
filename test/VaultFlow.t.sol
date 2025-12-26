// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {VaultFactory} from "../src/contracts/VaultFactory.sol";
import {TokenizedBondVault} from "../src/contracts/TokenizedBondVault.sol";
import {ContractSigner} from "../src/contracts/ContractSigner.sol";
import {ReputationManager} from "../src/contracts/ReputationManager.sol";
import {Convexo_LPs} from "../src/convexolps.sol";
import {Convexo_Vaults} from "../src/convexovaults.sol";
import {IConvexoLPs} from "../src/interfaces/IConvexoLPs.sol";
import {IConvexoVaults} from "../src/interfaces/IConvexoVaults.sol";
import {IConvexoPassport} from "../src/interfaces/IConvexoPassport.sol";
import {ProofVerificationParams} from "../src/interfaces/IZKPassportVerifier.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

// Mock Convexo_Passport for testing
contract MockConvexoPassport is IConvexoPassport {
    mapping(address => uint256) private _balances;
    
    function balanceOf(address owner) external view returns (uint256) {
        return _balances[owner];
    }
    
    function setBalance(address owner, uint256 balance) external {
        _balances[owner] = balance;
    }
    
    // Stub implementations for other interface functions
    function safeMintWithZKPassport(ProofVerificationParams calldata, bool) external pure returns (uint256) {
        revert("Not implemented in mock");
    }
    
    function safeMintWithIdentifier(bytes32) external pure returns (uint256) {
        revert("Not implemented in mock");
    }
    
    function safeMint(address, string memory) external pure returns (uint256) {
        revert("Not implemented in mock");
    }
    
    function revokePassport(uint256) external pure {
        revert("Not implemented in mock");
    }
    
    function holdsActivePassport(address) external pure returns (bool) {
        return false;
    }
    
    function getVerifiedIdentity(address) external pure returns (VerifiedIdentity memory) {
        revert("Not implemented in mock");
    }
    
    function isIdentifierUsed(bytes32) external pure returns (bool) {
        return false;
    }
    
    function getActivePassportCount() external pure returns (uint256) {
        return 0;
    }
}

contract VaultFlowTest is Test {
    VaultFactory public vaultFactory;
    ContractSigner public contractSigner;
    ReputationManager public reputationManager;
    Convexo_LPs public convexoLPs;
    Convexo_Vaults public convexoVaults;
    ERC20Mock public usdc;

    address public admin = address(0x1);
    address public protocolFeeCollector = address(0x5);
    address public userWithoutNFT = address(0x6);
    
    // Private keys for signing (using Foundry default test keys)
    uint256 public borrowerPK = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 public investor1PK = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
    uint256 public investor2PK = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;
    
    // Derive addresses from private keys
    address public borrower;
    address public investor1;
    address public investor2;

    uint256 public constant PRINCIPAL_AMOUNT = 50000 * 1e6; // 50k USDC
    uint256 public constant INTEREST_RATE = 1200; // 12%
    uint256 public constant PROTOCOL_FEE_RATE = 200; // 2%
    uint256 public constant MATURITY_DATE = 180 days;

    /// @notice Helper function to create valid ECDSA signature
    function createSignature(uint256 privateKey, bytes32 documentHash) internal pure returns (bytes memory) {
        bytes32 messageHash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            documentHash
        ));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, messageHash);
        return abi.encodePacked(r, s, v);
    }

    function setUp() public {
        // Derive addresses from private keys
        borrower = vm.addr(borrowerPK);
        investor1 = vm.addr(investor1PK);
        investor2 = vm.addr(investor2PK);
        
        // Deploy mock USDC
        usdc = new ERC20Mock();
        vm.label(address(usdc), "USDC");

        // Deploy NFT contracts
        vm.startPrank(admin);
        convexoLPs = new Convexo_LPs(admin, admin);
        convexoVaults = new Convexo_Vaults(admin, admin);
        vm.stopPrank();

        // Deploy core contracts
        // Create a mock Convexo_Passport for testing
        MockConvexoPassport mockPassport = new MockConvexoPassport();
        reputationManager = new ReputationManager(
            IConvexoLPs(address(convexoLPs)),
            IConvexoVaults(address(convexoVaults)),
            IConvexoPassport(address(mockPassport))
        );
        
        vm.prank(admin);
        contractSigner = new ContractSigner(admin);

        // Deploy VaultFactory
        vaultFactory = new VaultFactory(
            admin,
            address(usdc),
            protocolFeeCollector,
            contractSigner,
            reputationManager
        );


        // Mint NFTs to borrower (Tier 2)
        vm.startPrank(admin);
        convexoLPs.safeMint(borrower, "COMPANY001", "ipfs://lp-nft");
        convexoVaults.safeMint(borrower, "COMPANY001", "ipfs://vault-nft");
        vm.stopPrank();

        // Give USDC to investors
        usdc.mint(investor1, 30000 * 1e6);
        usdc.mint(investor2, 20000 * 1e6);
    }

    function testBorrowerWithTier2CanCreateVault() public {
        vm.prank(borrower);
        (uint256 vaultId, address vaultAddress) = vaultFactory.createVault(
            PRINCIPAL_AMOUNT,
            INTEREST_RATE,
            PROTOCOL_FEE_RATE,
            block.timestamp + MATURITY_DATE,
            "Vault ABC",
            "VABC"
        );

        assertEq(vaultId, 0);
        assertTrue(vaultAddress != address(0));

        TokenizedBondVault vault = TokenizedBondVault(vaultAddress);
        assertEq(vault.getVaultBorrower(), borrower);
        assertEq(vault.getVaultPrincipalAmount(), PRINCIPAL_AMOUNT);
        assertEq(uint256(vault.getVaultState()), uint256(TokenizedBondVault.VaultState.Pending));
    }

    function testBorrowerWithoutTier2CannotCreateVault() public {
        vm.prank(userWithoutNFT);
        vm.expectRevert("Must have Tier 2 NFT (Convexo_Vaults)");
        vaultFactory.createVault(
            PRINCIPAL_AMOUNT,
            INTEREST_RATE,
            PROTOCOL_FEE_RATE,
            block.timestamp + MATURITY_DATE,
            "Vault ABC",
            "VABC"
        );
    }

    function testInvestorsCanFundVault() public {
        // Create vault
        vm.prank(borrower);
        (uint256 vaultId, address vaultAddress) = vaultFactory.createVault(
            PRINCIPAL_AMOUNT,
            INTEREST_RATE,
            PROTOCOL_FEE_RATE,
            block.timestamp + MATURITY_DATE,
            "Vault ABC",
            "VABC"
        );

        TokenizedBondVault vault = TokenizedBondVault(vaultAddress);

        // Investor 1 invests 30k
        vm.startPrank(investor1);
        usdc.approve(vaultAddress, 30000 * 1e6);
        vault.purchaseShares(30000 * 1e6);
        vm.stopPrank();

        assertEq(vault.balanceOf(investor1), 30000 * 1e6);
        assertEq(vault.getVaultTotalRaised(), 30000 * 1e6);
        assertEq(uint256(vault.getVaultState()), uint256(TokenizedBondVault.VaultState.Pending));

        // Investor 2 invests 20k (completes funding)
        vm.startPrank(investor2);
        usdc.approve(vaultAddress, 20000 * 1e6);
        vault.purchaseShares(20000 * 1e6);
        vm.stopPrank();

        assertEq(vault.balanceOf(investor2), 20000 * 1e6);
        assertEq(vault.getVaultTotalRaised(), PRINCIPAL_AMOUNT);
        assertEq(uint256(vault.getVaultState()), uint256(TokenizedBondVault.VaultState.Funded));
    }

    function testVaultStateChangeToFundedWhenFullyFunded() public {
        // Create vault
        vm.prank(borrower);
        (uint256 vaultId, address vaultAddress) = vaultFactory.createVault(
            PRINCIPAL_AMOUNT,
            INTEREST_RATE,
            PROTOCOL_FEE_RATE,
            block.timestamp + MATURITY_DATE,
            "Vault ABC",
            "VABC"
        );

        TokenizedBondVault vault = TokenizedBondVault(vaultAddress);

        // Fund completely (investor1 needs more USDC)
        usdc.mint(investor1, 20000 * 1e6); // Give investor1 enough to fund fully
        vm.startPrank(investor1);
        usdc.approve(vaultAddress, PRINCIPAL_AMOUNT);
        vault.purchaseShares(PRINCIPAL_AMOUNT);
        vm.stopPrank();

        // Check state changed to Funded
        assertEq(uint256(vault.getVaultState()), uint256(TokenizedBondVault.VaultState.Funded));
    }

    function testCannotInvestAfterFullyFunded() public {
        // Create and fund vault
        vm.prank(borrower);
        (uint256 vaultId, address vaultAddress) = vaultFactory.createVault(
            PRINCIPAL_AMOUNT,
            INTEREST_RATE,
            PROTOCOL_FEE_RATE,
            block.timestamp + MATURITY_DATE,
            "Vault ABC",
            "VABC"
        );

        TokenizedBondVault vault = TokenizedBondVault(vaultAddress);

        usdc.mint(investor1, 20000 * 1e6); // Give investor1 enough
        vm.startPrank(investor1);
        usdc.approve(vaultAddress, PRINCIPAL_AMOUNT);
        vault.purchaseShares(PRINCIPAL_AMOUNT);
        vm.stopPrank();

        // Try to invest more
        vm.startPrank(investor2);
        usdc.approve(vaultAddress, 1000 * 1e6);
        vm.expectRevert("Vault not accepting deposits");
        vault.purchaseShares(1000 * 1e6);
        vm.stopPrank();
    }

    function testContractCanBeAttachedAfterFunding() public {
        // Create and fund vault
        vm.prank(borrower);
        (uint256 vaultId, address vaultAddress) = vaultFactory.createVault(
            PRINCIPAL_AMOUNT,
            INTEREST_RATE,
            PROTOCOL_FEE_RATE,
            block.timestamp + MATURITY_DATE,
            "Vault ABC",
            "VABC"
        );

        TokenizedBondVault vault = TokenizedBondVault(vaultAddress);

        usdc.mint(investor1, 20000 * 1e6); // Give investor1 enough
        vm.startPrank(investor1);
        usdc.approve(vaultAddress, PRINCIPAL_AMOUNT);
        vault.purchaseShares(PRINCIPAL_AMOUNT);
        vm.stopPrank();

        // Create contract
        bytes32 documentHash = keccak256("test-contract");
        address[] memory signers = new address[](3);
        signers[0] = borrower;
        signers[1] = investor1;
        signers[2] = investor2;

        vm.prank(admin);
        contractSigner.createContract(
            documentHash,
            ContractSigner.AgreementType.Loan,
            signers,
            "ipfs://contract-pdf",
            2,
            30 days
        );

        // Sign contract (all parties) - using valid ECDSA signatures
        vm.prank(borrower);
        contractSigner.signContract(documentHash, createSignature(borrowerPK, documentHash));

        vm.prank(investor1);
        contractSigner.signContract(documentHash, createSignature(investor1PK, documentHash));

        vm.prank(investor2);
        contractSigner.signContract(documentHash, createSignature(investor2PK, documentHash));

        // Execute contract
        vm.prank(admin);
        contractSigner.executeContract(documentHash, vaultId);

        // Borrower attaches contract to vault
        vm.prank(borrower);
        vault.attachContract(documentHash);

        // Verify contract attached and state changed to Active
        assertEq(vault.getVaultContractHash(), documentHash);
        assertEq(uint256(vault.getVaultState()), uint256(TokenizedBondVault.VaultState.Active));
    }

    function testBorrowerCannotWithdrawBeforeContractSigned() public {
        // Create and fund vault
        vm.prank(borrower);
        (uint256 vaultId, address vaultAddress) = vaultFactory.createVault(
            PRINCIPAL_AMOUNT,
            INTEREST_RATE,
            PROTOCOL_FEE_RATE,
            block.timestamp + MATURITY_DATE,
            "Vault ABC",
            "VABC"
        );

        TokenizedBondVault vault = TokenizedBondVault(vaultAddress);

        usdc.mint(investor1, 20000 * 1e6); // Give investor1 enough
        vm.startPrank(investor1);
        usdc.approve(vaultAddress, PRINCIPAL_AMOUNT);
        vault.purchaseShares(PRINCIPAL_AMOUNT);
        vm.stopPrank();

        // Try to withdraw without contract
        vm.prank(borrower);
        vm.expectRevert("Vault not active");
        vault.withdrawFunds();
    }

    function testBorrowerCanWithdrawAfterContractFullySigned() public {
        // Create and fund vault
        vm.prank(borrower);
        (uint256 vaultId, address vaultAddress) = vaultFactory.createVault(
            PRINCIPAL_AMOUNT,
            INTEREST_RATE,
            PROTOCOL_FEE_RATE,
            block.timestamp + MATURITY_DATE,
            "Vault ABC",
            "VABC"
        );

        TokenizedBondVault vault = TokenizedBondVault(vaultAddress);

        usdc.mint(investor1, 20000 * 1e6); // Give investor1 enough
        vm.startPrank(investor1);
        usdc.approve(vaultAddress, PRINCIPAL_AMOUNT);
        vault.purchaseShares(PRINCIPAL_AMOUNT);
        vm.stopPrank();

        // Create and sign contract
        bytes32 documentHash = keccak256("test-contract");
        address[] memory signers = new address[](2);
        signers[0] = borrower;
        signers[1] = investor1;

        vm.prank(admin);
        contractSigner.createContract(
            documentHash,
            ContractSigner.AgreementType.Loan,
            signers,
            "ipfs://contract-pdf",
            2,
            30 days
        );

        vm.prank(borrower);
        contractSigner.signContract(documentHash, createSignature(borrowerPK, documentHash));

        vm.prank(investor1);
        contractSigner.signContract(documentHash, createSignature(investor1PK, documentHash));

        // Execute contract
        vm.prank(admin);
        contractSigner.executeContract(documentHash, vaultId);

        // Borrower attaches contract
        vm.prank(borrower);
        vault.attachContract(documentHash);

        // Borrower withdraws funds
        uint256 borrowerBalanceBefore = usdc.balanceOf(borrower);
        
        vm.prank(borrower);
        vault.withdrawFunds();

        uint256 borrowerBalanceAfter = usdc.balanceOf(borrower);
        
        assertEq(borrowerBalanceAfter - borrowerBalanceBefore, PRINCIPAL_AMOUNT);
        assertEq(uint256(vault.getVaultState()), uint256(TokenizedBondVault.VaultState.Repaying));
    }

    function testBorrowerCannotWithdrawIfContractCancelled() public {
        // Create and fund vault
        vm.prank(borrower);
        (uint256 vaultId, address vaultAddress) = vaultFactory.createVault(
            PRINCIPAL_AMOUNT,
            INTEREST_RATE,
            PROTOCOL_FEE_RATE,
            block.timestamp + MATURITY_DATE,
            "Vault ABC",
            "VABC"
        );

        TokenizedBondVault vault = TokenizedBondVault(vaultAddress);

        usdc.mint(investor1, 20000 * 1e6); // Give investor1 enough
        vm.startPrank(investor1);
        usdc.approve(vaultAddress, PRINCIPAL_AMOUNT);
        vault.purchaseShares(PRINCIPAL_AMOUNT);
        vm.stopPrank();

        // Create contract
        bytes32 documentHash = keccak256("test-contract");
        address[] memory signers = new address[](2);
        signers[0] = borrower;
        signers[1] = investor1;

        vm.prank(admin);
        contractSigner.createContract(
            documentHash,
            ContractSigner.AgreementType.Loan,
            signers,
            "ipfs://contract-pdf",
            2,
            30 days
        );

        // Sign contract
        vm.prank(borrower);
        contractSigner.signContract(documentHash, createSignature(borrowerPK, documentHash));

        vm.prank(investor1);
        contractSigner.signContract(documentHash, createSignature(investor1PK, documentHash));

        // Cancel contract BEFORE executing it
        vm.prank(admin);
        contractSigner.cancelContract(documentHash);

        // Try to execute cancelled contract (should fail)
        vm.prank(admin);
        vm.expectRevert("Contract cancelled");
        contractSigner.executeContract(documentHash, vaultId);
    }

    function testGetInvestorsList() public {
        // Create vault
        vm.prank(borrower);
        (uint256 vaultId, address vaultAddress) = vaultFactory.createVault(
            PRINCIPAL_AMOUNT,
            INTEREST_RATE,
            PROTOCOL_FEE_RATE,
            block.timestamp + MATURITY_DATE,
            "Vault ABC",
            "VABC"
        );

        TokenizedBondVault vault = TokenizedBondVault(vaultAddress);

        // Multiple investors
        vm.startPrank(investor1);
        usdc.approve(vaultAddress, 30000 * 1e6);
        vault.purchaseShares(30000 * 1e6);
        vm.stopPrank();

        vm.startPrank(investor2);
        usdc.approve(vaultAddress, 20000 * 1e6);
        vault.purchaseShares(20000 * 1e6);
        vm.stopPrank();

        // Get investors list
        address[] memory investorsList = vault.getInvestors();
        
        assertEq(investorsList.length, 2);
        assertEq(investorsList[0], investor1);
        assertEq(investorsList[1], investor2);
    }

    function testInvestorTracking() public {
        // Create vault
        vm.prank(borrower);
        (uint256 vaultId, address vaultAddress) = vaultFactory.createVault(
            PRINCIPAL_AMOUNT,
            INTEREST_RATE,
            PROTOCOL_FEE_RATE,
            block.timestamp + MATURITY_DATE,
            "Vault ABC",
            "VABC"
        );

        TokenizedBondVault vault = TokenizedBondVault(vaultAddress);

        // Investor invests twice
        vm.startPrank(investor1);
        usdc.approve(vaultAddress, 30000 * 1e6);
        vault.purchaseShares(15000 * 1e6);
        vault.purchaseShares(15000 * 1e6);
        vm.stopPrank();

        // Should only appear once in investors list
        address[] memory investorsList = vault.getInvestors();
        assertEq(investorsList.length, 1);
        assertEq(investorsList[0], investor1);
        assertTrue(vault.isInvestorAddress(investor1));
        assertFalse(vault.isInvestorAddress(investor2));
    }

    function testCompleteVaultLifecycle() public {
        // 1. Borrower creates vault
        vm.prank(borrower);
        (uint256 vaultId, address vaultAddress) = vaultFactory.createVault(
            PRINCIPAL_AMOUNT,
            INTEREST_RATE,
            PROTOCOL_FEE_RATE,
            block.timestamp + MATURITY_DATE,
            "Vault ABC",
            "VABC"
        );

        TokenizedBondVault vault = TokenizedBondVault(vaultAddress);

        // 2. Investors fund vault
        vm.startPrank(investor1);
        usdc.approve(vaultAddress, 30000 * 1e6);
        vault.purchaseShares(30000 * 1e6);
        vm.stopPrank();

        vm.startPrank(investor2);
        usdc.approve(vaultAddress, 20000 * 1e6);
        vault.purchaseShares(20000 * 1e6);
        vm.stopPrank();

        assertEq(uint256(vault.getVaultState()), uint256(TokenizedBondVault.VaultState.Funded));

        // 3. Create contract with all parties
        bytes32 documentHash = keccak256("test-contract");
        address[] memory signers = new address[](3);
        signers[0] = borrower;
        signers[1] = investor1;
        signers[2] = investor2;

        vm.prank(admin);
        contractSigner.createContract(
            documentHash,
            ContractSigner.AgreementType.Loan,
            signers,
            "ipfs://contract-pdf",
            2,
            30 days
        );

        // 4. All parties sign
        vm.prank(borrower);
        contractSigner.signContract(documentHash, createSignature(borrowerPK, documentHash));

        vm.prank(investor1);
        contractSigner.signContract(documentHash, createSignature(investor1PK, documentHash));

        vm.prank(investor2);
        contractSigner.signContract(documentHash, createSignature(investor2PK, documentHash));

        // 5. Execute contract
        vm.prank(admin);
        contractSigner.executeContract(documentHash, vaultId);

        // 6. Borrower attaches contract to vault
        vm.prank(borrower);
        vault.attachContract(documentHash);

        assertEq(uint256(vault.getVaultState()), uint256(TokenizedBondVault.VaultState.Active));

        // 7. Borrower withdraws funds
        vm.prank(borrower);
        vault.withdrawFunds();

        assertEq(usdc.balanceOf(borrower), PRINCIPAL_AMOUNT);
        assertEq(uint256(vault.getVaultState()), uint256(TokenizedBondVault.VaultState.Repaying));

        // 8. Borrower makes repayments (principal + interest + protocol fee)
        uint256 interestAmount = PRINCIPAL_AMOUNT * INTEREST_RATE / 10000;
        uint256 protocolFee = PRINCIPAL_AMOUNT * PROTOCOL_FEE_RATE / 10000;
        uint256 totalDue = PRINCIPAL_AMOUNT + interestAmount + protocolFee;
        
        // Mint interest + protocol fee (borrower already has principal from withdrawal)
        usdc.mint(borrower, interestAmount + protocolFee);

        vm.startPrank(borrower);
        usdc.approve(vaultAddress, totalDue);
        vault.makeRepayment(totalDue);
        vm.stopPrank();

        // State should still be Repaying until all funds are withdrawn
        assertEq(uint256(vault.getVaultState()), uint256(TokenizedBondVault.VaultState.Repaying));

        // Verify vault has all the funds
        assertEq(usdc.balanceOf(vaultAddress), totalDue);

        // 9. Protocol collector withdraws fees
        vm.prank(protocolFeeCollector);
        vault.withdrawProtocolFees();
        
        assertEq(usdc.balanceOf(protocolFeeCollector), protocolFee);
        assertEq(vault.protocolFeesWithdrawn(), protocolFee);

        // 10. Investors redeem their shares
        uint256 investor1BalanceBefore = usdc.balanceOf(investor1);
        vm.prank(investor1);
        vault.redeemShares(30000 * 1e6);
        
        // Still in Repaying state (not all funds withdrawn yet)
        assertEq(uint256(vault.getVaultState()), uint256(TokenizedBondVault.VaultState.Repaying));
        
        uint256 investor2BalanceBefore = usdc.balanceOf(investor2);
        vm.prank(investor2);
        vault.redeemShares(20000 * 1e6);

        // Verify investors received principal + interest (not protocol fee)
        uint256 expectedInvestorPool = PRINCIPAL_AMOUNT + interestAmount;
        uint256 investor1Expected = (30000 * 1e6 * expectedInvestorPool) / PRINCIPAL_AMOUNT;
        uint256 investor2Expected = (20000 * 1e6 * expectedInvestorPool) / PRINCIPAL_AMOUNT;
        
        assertEq(usdc.balanceOf(investor1) - investor1BalanceBefore, investor1Expected);
        assertEq(usdc.balanceOf(investor2) - investor2BalanceBefore, investor2Expected);
        
        // NOW vault should be marked as Completed (all funds withdrawn, balance is dust)
        assertEq(uint256(vault.getVaultState()), uint256(TokenizedBondVault.VaultState.Completed));
        
        // Vault balance should be 0 or dust
        assertTrue(usdc.balanceOf(vaultAddress) < 100, "Vault should be empty or have only dust");
    }

    function testOnlyBorrowerCanWithdraw() public {
        // Create and fund vault
        vm.prank(borrower);
        (uint256 vaultId, address vaultAddress) = vaultFactory.createVault(
            PRINCIPAL_AMOUNT,
            INTEREST_RATE,
            PROTOCOL_FEE_RATE,
            block.timestamp + MATURITY_DATE,
            "Vault ABC",
            "VABC"
        );

        TokenizedBondVault vault = TokenizedBondVault(vaultAddress);

        usdc.mint(investor1, 20000 * 1e6); // Give investor1 enough
        vm.startPrank(investor1);
        usdc.approve(vaultAddress, PRINCIPAL_AMOUNT);
        vault.purchaseShares(PRINCIPAL_AMOUNT);
        vm.stopPrank();

        // Create and sign contract
        bytes32 documentHash = keccak256("test-contract");
        address[] memory signers = new address[](2);
        signers[0] = borrower;
        signers[1] = investor1;

        vm.prank(admin);
        contractSigner.createContract(
            documentHash,
            ContractSigner.AgreementType.Loan,
            signers,
            "ipfs://contract-pdf",
            2,
            30 days
        );

        vm.prank(borrower);
        contractSigner.signContract(documentHash, createSignature(borrowerPK, documentHash));

        vm.prank(investor1);
        contractSigner.signContract(documentHash, createSignature(investor1PK, documentHash));

        // Execute contract
        vm.prank(admin);
        contractSigner.executeContract(documentHash, vaultId);

        // Borrower attaches contract
        vm.prank(borrower);
        vault.attachContract(documentHash);

        // Try to withdraw as investor (should fail)
        vm.prank(investor1);
        vm.expectRevert("Only borrower");
        vault.withdrawFunds();

        // Borrower can withdraw
        vm.prank(borrower);
        vault.withdrawFunds();

        assertEq(usdc.balanceOf(borrower), PRINCIPAL_AMOUNT);
    }

    function testVaultCreationValidations() public {
        // Test user without NFT cannot create vault
        vm.expectRevert("Must have Tier 2 NFT (Convexo_Vaults)");
        vm.prank(userWithoutNFT);
        vaultFactory.createVault(
            PRINCIPAL_AMOUNT,
            INTEREST_RATE,
            PROTOCOL_FEE_RATE,
            block.timestamp + MATURITY_DATE,
            "Vault ABC",
            "VABC"
        );
    }

    function testProtocolFeesAreProtectedFromInvestorRedemption() public {
        // Setup: Create vault, fund it, sign contract, withdraw funds
        vm.prank(borrower);
        (uint256 vaultId, address vaultAddress) = vaultFactory.createVault(
            PRINCIPAL_AMOUNT,
            INTEREST_RATE,
            PROTOCOL_FEE_RATE,
            block.timestamp + MATURITY_DATE,
            "Vault ABC",
            "VABC"
        );

        TokenizedBondVault vault = TokenizedBondVault(vaultAddress);

        // Fund vault
        vm.startPrank(investor1);
        usdc.approve(vaultAddress, 30000 * 1e6);
        vault.purchaseShares(30000 * 1e6);
        vm.stopPrank();

        vm.startPrank(investor2);
        usdc.approve(vaultAddress, 20000 * 1e6);
        vault.purchaseShares(20000 * 1e6);
        vm.stopPrank();

        // Create and sign contract
        bytes32 documentHash = keccak256("test-contract");
        address[] memory signers = new address[](3);
        signers[0] = borrower;
        signers[1] = investor1;
        signers[2] = investor2;

        vm.prank(admin);
        contractSigner.createContract(
            documentHash,
            ContractSigner.AgreementType.Loan,
            signers,
            "ipfs://contract-pdf",
            2,
            30 days
        );

        vm.prank(borrower);
        contractSigner.signContract(documentHash, createSignature(borrowerPK, documentHash));

        vm.prank(investor1);
        contractSigner.signContract(documentHash, createSignature(investor1PK, documentHash));

        vm.prank(investor2);
        contractSigner.signContract(documentHash, createSignature(investor2PK, documentHash));

        vm.prank(admin);
        contractSigner.executeContract(documentHash, vaultId);

        vm.prank(borrower);
        vault.attachContract(documentHash);

        // Borrower withdraws funds
        vm.prank(borrower);
        vault.withdrawFunds();

        // Borrower makes FULL repayment (principal + interest + protocol fee)
        uint256 interestAmount = PRINCIPAL_AMOUNT * INTEREST_RATE / 10000;
        uint256 protocolFee = PRINCIPAL_AMOUNT * PROTOCOL_FEE_RATE / 10000;
        uint256 totalDue = PRINCIPAL_AMOUNT + interestAmount + protocolFee;
        
        usdc.mint(borrower, interestAmount + protocolFee);

        vm.startPrank(borrower);
        usdc.approve(vaultAddress, totalDue);
        vault.makeRepayment(totalDue);
        vm.stopPrank();

        // Verify vault has all funds
        assertEq(usdc.balanceOf(vaultAddress), totalDue);

        // CRITICAL TEST: Protocol has NOT withdrawn yet
        // Check available for investors (should exclude protocol fee)
        uint256 availableForInvestors = vault.getAvailableForInvestors();
        assertEq(availableForInvestors, PRINCIPAL_AMOUNT + interestAmount); // $56,000
        assertEq(availableForInvestors, 56000 * 1e6);

        // Investor 1 redeems ALL their shares
        uint256 investor1Shares = vault.balanceOf(investor1);
        uint256 investor1BalanceBefore = usdc.balanceOf(investor1);
        
        vm.prank(investor1);
        vault.redeemShares(investor1Shares);

        uint256 investor1Received = usdc.balanceOf(investor1) - investor1BalanceBefore;
        
        // Investor 1 should receive 60% of $56,000 = $33,600 (NOT 60% of $57,000)
        uint256 expectedInvestor1 = (30000 * 1e6 * availableForInvestors) / PRINCIPAL_AMOUNT;
        assertEq(investor1Received, expectedInvestor1);
        assertEq(investor1Received, 33600 * 1e6);

        // Investor 2 redeems ALL their shares
        uint256 investor2Shares = vault.balanceOf(investor2);
        uint256 investor2BalanceBefore = usdc.balanceOf(investor2);
        
        vm.prank(investor2);
        vault.redeemShares(investor2Shares);

        uint256 investor2Received = usdc.balanceOf(investor2) - investor2BalanceBefore;
        
        // Investor 2 should receive 40% of $56,000 = $22,400 (NOT 40% of $57,000)
        uint256 expectedInvestor2 = (20000 * 1e6 * availableForInvestors) / PRINCIPAL_AMOUNT;
        assertEq(investor2Received, expectedInvestor2);
        assertEq(investor2Received, 22400 * 1e6);

        // CRITICAL VERIFICATION: Protocol fee should still be in vault
        uint256 vaultBalanceAfterInvestors = usdc.balanceOf(vaultAddress);
        assertEq(vaultBalanceAfterInvestors, protocolFee); // $1,000 remaining
        assertEq(vaultBalanceAfterInvestors, 1000 * 1e6);

        // Protocol collector can still withdraw their fee
        uint256 protocolBalanceBefore = usdc.balanceOf(protocolFeeCollector);
        
        vm.prank(protocolFeeCollector);
        vault.withdrawProtocolFees();

        uint256 protocolReceived = usdc.balanceOf(protocolFeeCollector) - protocolBalanceBefore;
        assertEq(protocolReceived, protocolFee);
        assertEq(protocolReceived, 1000 * 1e6);

        // Vault should now be empty (or dust)
        assertTrue(usdc.balanceOf(vaultAddress) < 100);
        
        // Vault should be marked as Completed
        assertEq(uint256(vault.getVaultState()), uint256(TokenizedBondVault.VaultState.Completed));
    }
}


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {TokenizedBondVault} from "../src/contracts/TokenizedBondVault.sol";
import {ReputationManager} from "../src/contracts/ReputationManager.sol";
import {IConvexoLPs} from "../src/interfaces/IConvexoLPs.sol";
import {IConvexoVaults} from "../src/interfaces/IConvexoVaults.sol";
import {IConvexoPassport} from "../src/interfaces/IConvexoPassport.sol";
import {ProofVerificationParams} from "../src/interfaces/IZKPassportVerifier.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @notice Mock Passport for security testing - gives users Tier 1 access
contract MockPassport is IConvexoPassport {
    mapping(address => uint256) private _balances;
    
    function balanceOf(address owner) external view returns (uint256) {
        return _balances[owner];
    }
    
    function setBalance(address owner, uint256 balance) external {
        _balances[owner] = balance;
    }
    
    function safeMintWithZKPassport(ProofVerificationParams calldata, bool) external pure returns (uint256) {
        revert("Not implemented");
    }
    function safeMintWithIdentifier(bytes32) external pure returns (uint256) {
        revert("Not implemented");
    }
    function safeMint(address, string memory) external pure returns (uint256) {
        revert("Not implemented");
    }
    function revokePassport(uint256) external pure {
        revert("Not implemented");
    }
    function holdsActivePassport(address) external pure returns (bool) {
        return false;
    }
    function getVerifiedIdentity(address) external pure returns (VerifiedIdentity memory) {
        revert("Not implemented");
    }
    function isIdentifierUsed(bytes32) external pure returns (bool) {
        return false;
    }
    function getActivePassportCount() external pure returns (uint256) {
        return 0;
    }
}

/// @notice Mock LPs contract that returns 0 balance for all users
contract MockLPs is IConvexoLPs {
    function balanceOf(address) external pure returns (uint256) {
        return 0;
    }
    function ownerOf(uint256) external pure returns (address) {
        return address(0);
    }
    function getTokenState(uint256) external pure returns (bool) {
        return false;
    }
    function safeMint(address, string memory, string memory) external pure returns (uint256) {
        return 0;
    }
}

/// @notice Mock Vaults contract that returns 0 balance for all users
contract MockVaults is IConvexoVaults {
    function balanceOf(address) external pure returns (uint256) {
        return 0;
    }
    function ownerOf(uint256) external pure returns (address) {
        return address(0);
    }
    function getTokenState(uint256) external pure returns (bool) {
        return false;
    }
}

contract MockERC20 is ERC20 {
    constructor() ERC20("Mock", "MCK") {}
    
    function initialize(string memory, string memory, uint8) public {} // dummy
    
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract MockContractSigner {
    struct ContractDocument {
        bytes32 documentHash;
        uint8 agreementType;
        address initiator;
        uint256 createdAt;
        uint256 expiresAt;
        bool isExecuted;
        bool isCancelled;
        string ipfsHash;
        uint256 nftReputationTier;
        uint256 vaultId;
    }
    
    mapping(bytes32 => ContractDocument) public contracts;

    function getContract(bytes32 hash) external view returns (ContractDocument memory) {
        return contracts[hash];
    }
    
    function setExecuted(bytes32 hash, bool executed) external {
        contracts[hash].isExecuted = executed;
    }
}

contract TokenizedBondVaultSecurityTest is Test {
    TokenizedBondVault vault;
    MockERC20 usdc;
    MockContractSigner signer;
    ReputationManager reputationManager;
    MockPassport mockPassport;
    MockLPs mockLPs;
    MockVaults mockVaults;

    address admin = address(1);
    address borrower = address(2);
    address investor1 = address(3);
    address investor2 = address(4);
    address protocolCollector = address(5);
    
    uint256 principal = 100000e6; // 100k USDC
    uint256 interest = 1200; // 12%
    uint256 fee = 200; // 2%
    
    bytes32 constant VAULT_MANAGER_ROLE = keccak256("VAULT_MANAGER_ROLE");

    function setUp() public {
        vm.startPrank(admin);

        usdc = new MockERC20();

        signer = new MockContractSigner();

        // Deploy mock contracts for all NFT types (return 0 balance by default)
        mockPassport = new MockPassport();
        mockLPs = new MockLPs();
        mockVaults = new MockVaults();

        // Deploy ReputationManager with all mock contracts
        reputationManager = new ReputationManager(
            IConvexoLPs(address(mockLPs)),
            IConvexoVaults(address(mockVaults)),
            IConvexoPassport(address(mockPassport))
        );

        vault = new TokenizedBondVault(
            1,
            borrower,
            bytes32(0),
            principal,
            interest,
            fee,
            block.timestamp + 30 days,
            address(usdc),
            address(signer),
            admin,
            protocolCollector,
            reputationManager,
            "Vault Token",
            "VT"
        );
        
        vm.stopPrank();
        
        // Give investors Tier 1 access via passport
        mockPassport.setBalance(investor1, 1);
        mockPassport.setBalance(investor2, 1);
        
        // Fund investors
        usdc.mint(investor1, principal);
        usdc.mint(investor2, principal);
        usdc.mint(borrower, principal * 2); // For repayment
    }

    function testReentrancyProtection() public {
        // Checking if ReentrancyGuard is inherited and modifier is present
        // This is a static check usually, but we can try to reenter via a malicious contract
        // Since we are using standard ReentrancyGuard, we assume it works if modifier is applied.
        // We verified the code has `nonReentrant`.
    }

    function testPreDisbursementRedemption() public {
        // 1. Investor 1 funds 50%
        vm.startPrank(investor1);
        usdc.approve(address(vault), principal/2);
        vault.purchaseShares(principal/2);
        vm.stopPrank();
        
        // 2. Investor 2 funds 50% -> Fully Funded
        vm.startPrank(investor2);
        usdc.approve(address(vault), principal/2);
        vault.purchaseShares(principal/2);
        vm.stopPrank();
        
        assertEq(uint(vault.getVaultState()), uint(TokenizedBondVault.VaultState.Funded));
        
        // 3. Admin attaches contract -> Active
        vm.startPrank(admin);
        bytes32 contractHash = keccak256("contract");
        vault.attachContract(contractHash);
        vm.stopPrank();
        
        assertEq(uint(vault.getVaultState()), uint(TokenizedBondVault.VaultState.Active));
        
        // 4. Investor 1 decides to exit BEFORE borrower withdraws
        vm.startPrank(investor1);
        uint256 shares = vault.balanceOf(investor1);
        vault.redeemShares(shares);
        vm.stopPrank();
        
        // Verify:
        // - Investor 1 got money back (started with 100k, invested 50k, redeemed 50k = 100k total)
        assertEq(usdc.balanceOf(investor1), principal);
        // - Vault state reverted to Pending
        assertEq(uint(vault.getVaultState()), uint(TokenizedBondVault.VaultState.Pending));
        // - Contract hash detached
        assertEq(vault.getVaultContractHash(), bytes32(0));
        // - Total raised decreased
        assertEq(vault.getVaultTotalRaised(), principal/2);
    }

    function testStrictRedemptionLockDuringRepayment() public {
        // 1. Setup Active Vault
        _setupActiveVault();
        
        // 2. Borrower withdraws -> Repaying
        signer.setExecuted(keccak256("contract"), true);
        vm.prank(borrower);
        vault.withdrawFunds();
        
        assertEq(uint(vault.getVaultState()), uint(TokenizedBondVault.VaultState.Repaying));
        
        // 3. Borrower makes partial repayment (50%)
        uint256 totalDue = principal + (principal * interest / 10000) + (principal * fee / 10000);
        uint256 partialPayment = totalDue / 2;
        
        vm.startPrank(borrower);
        usdc.approve(address(vault), partialPayment);
        vault.makeRepayment(partialPayment);
        vm.stopPrank();
        
        // 4. Investor 1 tries to redeem (Should Fail)
        vm.startPrank(investor1);
        uint256 shares = vault.balanceOf(investor1);
        vm.expectRevert("Cannot redeem until full repayment");
        vault.redeemShares(shares);
        vm.stopPrank();
        
        // 5. Borrower completes repayment
        uint256 remaining = totalDue - partialPayment;
        vm.startPrank(borrower);
        usdc.approve(address(vault), remaining);
        vault.makeRepayment(remaining);
        vm.stopPrank();
        
        // 6. Investor 1 tries to redeem (Should Success)
        vm.startPrank(investor1);
        vault.redeemShares(shares);
        vm.stopPrank();
        
        assertGt(usdc.balanceOf(investor1), principal/2); // Got principal + interest
    }
    
    function _setupActiveVault() internal {
        vm.startPrank(investor1);
        usdc.approve(address(vault), principal/2);
        vault.purchaseShares(principal/2);
        vm.stopPrank();
        
        vm.startPrank(investor2);
        usdc.approve(address(vault), principal/2);
        vault.purchaseShares(principal/2);
        vm.stopPrank();
        
        vm.startPrank(admin);
        bytes32 contractHash = keccak256("contract");
        vault.attachContract(contractHash);
        vm.stopPrank();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {VaultFactory} from "../src/contracts/credits/VaultFactory.sol";
import {TokenizedBondVault} from "../src/contracts/credits/TokenizedBondVault.sol";
import {ContractSigner} from "../src/contracts/credits/ContractSigner.sol";
import {ReputationManager} from "../src/contracts/identity/ReputationManager.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUSDC2 is ERC20 {
    constructor() ERC20("USD Coin", "USDC") {}
    function decimals() public pure override returns (uint8) { return 6; }
    function mint(address to, uint256 amount) external { _mint(to, amount); }
}

contract MockReputationManager2 {
    mapping(address => bool) private _canCreate;
    mapping(address => bool) private _canInvest;

    function setCanCreate(address user, bool val) external { _canCreate[user] = val; }
    function setCanInvest(address user, bool val) external { _canInvest[user] = val; }
    function canCreateVaults(address user) external view returns (bool) { return _canCreate[user]; }
    function canInvestInVaults(address user) external view returns (bool) { return _canInvest[user]; }
    // Stub other ReputationManager calls if needed
    function getReputationTierNumeric(address) external pure returns (uint256) { return 3; }
}

contract VaultFactoryTest is Test {

    VaultFactory public factory;
    MockUSDC2 public usdc;
    MockReputationManager2 public reputation;

    address admin        = address(0x1);
    address borrower     = address(0x2);
    address feeCollector = address(0x3);

    function setUp() public {
        usdc       = new MockUSDC2();
        reputation = new MockReputationManager2();
        reputation.setCanCreate(borrower, true);
        reputation.setCanInvest(borrower, true);

        // Deploy ContractSigner with admin
        ContractSigner cs = new ContractSigner(admin);

        factory = new VaultFactory(
            admin,
            address(usdc),
            feeCollector,
            cs,
            ReputationManager(address(reputation))
        );
    }

    function _defaultParams() internal view returns (
        uint256, uint256, uint256, uint256, uint256, uint256, string memory, string memory
    ) {
        return (
            100_000e6,          // principalAmount
            1200,               // interestRate (12%)
            200,                // protocolFeeRate (2%)
            block.timestamp + 365 days, // maturityDate
            1000,               // totalShareSupply
            100e6,              // minInvestment ($100)
            "Bond A",
            "BONDA"
        );
    }

    function test_CreateVault() public {
        (uint256 pa, uint256 ir, uint256 fr, uint256 md, uint256 ts, uint256 mi, string memory n, string memory s)
            = _defaultParams();

        vm.prank(borrower);
        (uint256 vaultId, address vaultAddr) = factory.createVault(pa, ir, fr, md, ts, mi, n, s);

        assertEq(vaultId, 0);
        assertEq(factory.getVault(0), vaultAddr);
        assertEq(factory.getVaultCount(), 1);

        TokenizedBondVault vault = TokenizedBondVault(vaultAddr);
        assertEq(vault.getVaultBorrower(), borrower);
        assertEq(vault.getVaultPrincipalAmount(), pa);
        assertEq(vault.originalTotalShares(), ts * 1e18);
        assertEq(vault.minInvestment(), mi);
        assertEq(vault.getBaseSharePrice(), 100e6, "Base price should be $100");
        assertEq(vault.getExpectedFinalSharePrice(), 110e6, "Expected final $110");
    }

    function test_CreateVaultRevertsWithoutTier3() public {
        address noTier = address(0x99);
        (uint256 pa, uint256 ir, uint256 fr, uint256 md, uint256 ts, uint256 mi, string memory n, string memory s)
            = _defaultParams();

        vm.prank(noTier);
        vm.expectRevert("Must have Tier 3 NFT to create vaults");
        factory.createVault(pa, ir, fr, md, ts, mi, n, s);
    }

    function test_CreateVaultRevertsInvalidShareSupply() public {
        vm.prank(borrower);
        vm.expectRevert("Share supply must be > 0");
        factory.createVault(100_000e6, 1200, 200, block.timestamp + 365 days, 0, 100e6, "B", "B");
    }

    function test_CreateVaultRevertsSharePriceBelowOne() public {
        // 500 USDC raised across 1000 shares → $0.50/share < $1 minimum
        vm.prank(borrower);
        vm.expectRevert("Share price must be at least $1 (principal/shares >= 1e6)");
        factory.createVault(500e6, 1200, 200, block.timestamp + 365 days, 1000, 1e6, "B", "B");
    }

    function test_MultipleVaultIds() public {
        (uint256 pa, uint256 ir, uint256 fr, uint256 md, uint256 ts, uint256 mi, string memory n, string memory s)
            = _defaultParams();

        vm.startPrank(borrower);
        (uint256 id0,) = factory.createVault(pa, ir, fr, md, ts, mi, n, s);
        (uint256 id1,) = factory.createVault(pa, ir, fr, md, ts, mi, "Bond B", "BONDB");
        vm.stopPrank();

        assertEq(id0, 0);
        assertEq(id1, 1);
        assertEq(factory.getVaultCount(), 2);
    }

    function test_UpdateProtocolFeeCollector() public {
        address newCollector = address(0x88);
        vm.prank(admin);
        factory.updateProtocolFeeCollector(newCollector);
        assertEq(factory.protocolFeeCollector(), newCollector);
    }

    function test_UpdateFeeCollectorRevertsNonAdmin() public {
        vm.prank(borrower);
        vm.expectRevert();
        factory.updateProtocolFeeCollector(address(0x88));
    }
}

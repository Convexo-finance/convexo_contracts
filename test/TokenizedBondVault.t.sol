// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test, console2} from "forge-std/Test.sol";
import {TokenizedBondVault} from "../src/contracts/credits/TokenizedBondVault.sol";
import {ReputationManager} from "../src/contracts/identity/ReputationManager.sol";
import {IContractSigner} from "../src/interfaces/IContractSigner.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// ─── Mocks ────────────────────────────────────────────────────────────────────

contract MockUSDC is ERC20 {
    constructor() ERC20("USD Coin", "USDC") {}
    function decimals() public pure override returns (uint8) { return 6; }
    function mint(address to, uint256 amount) external { _mint(to, amount); }
}

contract MockContractSigner {
    mapping(bytes32 => bool) private _executed;
    mapping(bytes32 => bool) private _cancelled;

    function setDoc(bytes32 hash, bool executed, bool cancelled) external {
        _executed[hash] = executed;
        _cancelled[hash] = cancelled;
    }

    function getContract(bytes32 hash) external view returns (IContractSigner.ContractDocument memory) {
        return IContractSigner.ContractDocument({
            documentHash: hash,
            agreementType: IContractSigner.AgreementType.TokenizedBondCredits,
            initiator: address(0),
            createdAt: 0,
            expiresAt: 0,
            isExecuted: _executed[hash],
            isCancelled: _cancelled[hash],
            ipfsHash: "",
            nftReputationTier: 3,
            vaultId: 0
        });
    }
}

contract MockReputationManager {
    mapping(address => bool) public canInvest;
    mapping(address => bool) public canCreate;

    function setCanInvest(address user, bool val) external { canInvest[user] = val; }
    function setCanCreate(address user, bool val) external { canCreate[user] = val; }
    function canInvestInVaults(address user) external view returns (bool) { return canInvest[user]; }
    function canCreateVaults(address user) external view returns (bool) { return canCreate[user]; }
}

// ─── Test ─────────────────────────────────────────────────────────────────────

contract TokenizedBondVaultTest is Test {

    TokenizedBondVault public vault;
    MockUSDC public usdc;
    MockContractSigner public signer;
    MockReputationManager public reputation;

    address admin     = address(0x1);
    address borrower  = address(0x2);
    address investorA = address(0x3);
    address investorB = address(0x4);
    address feeCollector = address(0x5);

    // Vault params
    uint256 constant PRINCIPAL      = 100_000e6;  // $100,000 USDC
    uint256 constant INTEREST_RATE  = 1200;        // 12%
    uint256 constant FEE_RATE       = 200;         // 2%
    uint256 constant TOTAL_SHARES   = 1000;        // 1000 whole shares → $100/share
    uint256 constant MIN_INVESTMENT = 100e6;       // $100 minimum
    uint256 MATURITY;

    // Derived
    uint256 constant TOTAL_INTEREST = PRINCIPAL * INTEREST_RATE / 10000; // $12,000
    uint256 constant TOTAL_FEE      = PRINCIPAL * FEE_RATE / 10000;      // $2,000
    uint256 constant TOTAL_DUE      = PRINCIPAL + TOTAL_INTEREST + TOTAL_FEE; // $114,000
    uint256 constant NET_INVESTORS  = PRINCIPAL + TOTAL_INTEREST - TOTAL_FEE; // $110,000

    bytes32 constant CONTRACT_HASH = keccak256("test-contract");

    function setUp() public {
        MATURITY = block.timestamp + 365 days;

        usdc     = new MockUSDC();
        signer   = new MockContractSigner();
        reputation = new MockReputationManager();

        reputation.setCanInvest(investorA, true);
        reputation.setCanInvest(investorB, true);

        vault = new TokenizedBondVault(
            0,
            borrower,
            PRINCIPAL,
            INTEREST_RATE,
            FEE_RATE,
            MATURITY,
            TOTAL_SHARES,
            MIN_INVESTMENT,
            address(usdc),
            address(signer),
            admin,
            feeCollector,
            ReputationManager(address(reputation)),
            "Convexo Bond A",
            "CBOND-A"
        );

        // Fund investors
        usdc.mint(investorA, 200_000e6);
        usdc.mint(investorB, 200_000e6);
        vm.prank(investorA); usdc.approve(address(vault), type(uint256).max);
        vm.prank(investorB); usdc.approve(address(vault), type(uint256).max);

        // Fund borrower for repayments
        usdc.mint(borrower, 200_000e6);
        vm.prank(borrower); usdc.approve(address(vault), type(uint256).max);
    }

    // ─── Share Price ──────────────────────────────────────────────

    function test_BaseSharePrice() public view {
        // $100,000 / 1000 shares = $100/share
        assertEq(vault.getBaseSharePrice(), 100e6, "Base share price should be $100");
    }

    function test_ExpectedFinalSharePrice() public view {
        // $110,000 / 1000 shares = $110/share
        assertEq(vault.getExpectedFinalSharePrice(), 110e6, "Expected final price should be $110");
    }

    function test_InitialCurrentSharePriceEqualsBase() public view {
        assertEq(vault.getCurrentSharePrice(), vault.getBaseSharePrice());
    }

    // ─── Deposit ──────────────────────────────────────────────────

    function test_DepositMintsCorrectShares() public {
        // $10,000 → 100 shares (10% of supply)
        vm.prank(investorA);
        uint256 shares = vault.deposit(10_000e6, investorA);

        assertEq(shares, 100 * 1e18, "Should mint 100 shares");
        assertEq(vault.balanceOf(investorA), 100 * 1e18);
        assertEq(vault.getVaultTotalRaised(), 10_000e6);
    }

    function test_DepositRevertsBeforeMinimum() public {
        vm.prank(investorA);
        vm.expectRevert("Below minimum investment");
        vault.deposit(50e6, investorA); // $50 < $100 min
    }

    function test_DepositRevertsWithoutTier1() public {
        address noTier = address(0x99);
        usdc.mint(noTier, 10_000e6);
        vm.prank(noTier); usdc.approve(address(vault), type(uint256).max);

        vm.prank(noTier);
        vm.expectRevert("Tier 1+ required to invest");
        vault.deposit(10_000e6, noTier);
    }

    function test_DepositRevertsExceedingTarget() public {
        vm.prank(investorA);
        vm.expectRevert("Exceeds funding target");
        vault.deposit(PRINCIPAL + 1e6, investorA);
    }

    function test_FullFundingTransitionsToFunded() public {
        // A deposits 40%, B deposits 60%
        vm.prank(investorA); vault.deposit(40_000e6, investorA);

        assertEq(uint8(vault.getVaultState()), uint8(TokenizedBondVault.VaultState.Pending));

        vm.prank(investorB); vault.deposit(60_000e6, investorB);

        assertEq(uint8(vault.getVaultState()), uint8(TokenizedBondVault.VaultState.Funded));
        assertEq(vault.getVaultFundedAt(), block.timestamp);
    }

    function test_ConvertToSharesAndBack() public view {
        uint256 assets = 5_000e6;
        uint256 shares = vault.convertToShares(assets);
        // 5000 / 100000 * 1000 = 50 shares
        assertEq(shares, 50 * 1e18);
        // convertToAssets during pending = principalAmount proportional
        assertEq(vault.convertToAssets(shares), assets);
    }

    // ─── Early Exit ───────────────────────────────────────────────

    function test_EarlyExitReturnsPrincipal() public {
        vm.prank(investorA); vault.deposit(40_000e6, investorA);
        vm.prank(investorB); vault.deposit(60_000e6, investorB);
        // State = Funded

        uint256 balBefore = usdc.balanceOf(investorA);
        vm.prank(investorA);
        vault.earlyExit(400 * 1e18); // 400 of 400 shares ($40k worth)

        uint256 returned = usdc.balanceOf(investorA) - balBefore;
        assertEq(returned, 40_000e6, "Should return $40k");
        assertEq(uint8(vault.getVaultState()), uint8(TokenizedBondVault.VaultState.Pending));
    }

    function test_EarlyExitRevertsInRepaying() public {
        _fundAndActivate();
        _borrowerWithdraws();

        vm.prank(investorA);
        vm.expectRevert("Early exit only before disbursement");
        vault.earlyExit(400 * 1e18);
    }

    // ─── Vault Lifecycle ─────────────────────────────────────────

    function test_AttachContractAndWithdraw() public {
        _fundAndActivate();

        // Borrower withdraws
        uint256 borrowerBalBefore = usdc.balanceOf(borrower);
        _borrowerWithdraws();

        assertEq(usdc.balanceOf(borrower) - borrowerBalBefore, PRINCIPAL, "Borrower should receive principal");
        assertEq(uint8(vault.getVaultState()), uint8(TokenizedBondVault.VaultState.Repaying));
    }

    function test_WithdrawRevertsIfContractNotSigned() public {
        _fundVault();
        signer.setDoc(CONTRACT_HASH, false, false); // not executed

        vm.prank(admin);
        vault.attachContract(CONTRACT_HASH);

        vm.prank(borrower);
        vm.expectRevert("Contract not fully signed");
        vault.withdrawFunds();
    }

    // ─── Repayment ────────────────────────────────────────────────

    function test_MakeRepaymentUpdatesTotal() public {
        _fundAndActivate();
        _borrowerWithdraws();

        vm.prank(borrower);
        vault.makeRepayment(57_000e6); // 50% of totalDue

        assertEq(vault.getVaultTotalRepaid(), 57_000e6);
    }

    function test_MakeRepaymentRevertsWhenNotRepaying() public {
        _fundAndActivate();
        // Not repaying yet

        vm.prank(borrower);
        vm.expectRevert("Not in repaying state");
        vault.makeRepayment(10_000e6);
    }

    // ─── ERC-7540 Async Redeem ────────────────────────────────────

    function test_RequestRedeemLocksShares() public {
        _fullLifecycleToRepaying();

        // investorA has 400 shares
        vm.prank(investorA);
        uint256 requestId = vault.requestRedeem(400 * 1e18, investorA, investorA);

        assertEq(requestId, 0, "requestId must be 0");
        assertEq(vault.balanceOf(investorA), 0, "Shares should be gone from investorA");
        assertEq(vault.claimableRedeemRequest(0, investorA), 400 * 1e18, "Locked shares should be 400");
        assertEq(vault.pendingRedeemRequest(0, investorA), 0, "Pending always 0");
    }

    function test_RequestRedeemRevertsInPending() public {
        vm.prank(investorA); vault.deposit(40_000e6, investorA);

        vm.prank(investorA);
        vm.expectRevert("Not in repaying state");
        vault.requestRedeem(400 * 1e18, investorA, investorA);
    }

    function test_RedeemProportionalAt50Percent() public {
        _fullLifecycleToRepaying();

        // 50% repayment
        uint256 halfDue = TOTAL_DUE / 2; // $57,000
        vm.prank(borrower); vault.makeRepayment(halfDue);

        // investorA (40% of shares = 400) requests redeem
        vm.prank(investorA);
        vault.requestRedeem(400 * 1e18, investorA, investorA);

        (,, , uint256 claimableNow) = vault.getRedeemState(investorA);

        // entitlement = 400/1000 * $110k = $44k
        // repaidFraction = 50%
        // claimable = $44k * 0.5 = $22k
        assertApproxEqAbs(claimableNow, 22_000e6, 10, "Should be ~$22k claimable at 50%");

        uint256 balBefore = usdc.balanceOf(investorA);
        vm.prank(investorA);
        vault.redeem(400 * 1e18, investorA, investorA);

        uint256 received = usdc.balanceOf(investorA) - balBefore;
        assertApproxEqAbs(received, 22_000e6, 10, "Should receive ~$22k");
    }

    function test_RedeemFullAtComplete() public {
        _fullLifecycleToRepaying();

        // Full repayment
        vm.prank(borrower); vault.makeRepayment(TOTAL_DUE);

        // investorA requests and redeems all
        vm.prank(investorA);
        vault.requestRedeem(400 * 1e18, investorA, investorA);

        uint256 balBefore = usdc.balanceOf(investorA);
        vm.prank(investorA);
        vault.redeem(400 * 1e18, investorA, investorA);

        uint256 received = usdc.balanceOf(investorA) - balBefore;
        // entitlement = 400/1000 * $110k = $44k
        assertApproxEqAbs(received, 44_000e6, 10, "Should receive $44k at full repayment");
    }

    function test_MultipleRedeemCallsAsRepaymentAccumulates() public {
        _fullLifecycleToRepaying();

        // investorB (60% = 600 shares, entitlement = $66k) locks all shares upfront
        vm.prank(investorB);
        vault.requestRedeem(600 * 1e18, investorB, investorB);

        // First claim at 50% repayment — pass ALL locked shares to get max available now
        vm.prank(borrower); vault.makeRepayment(TOTAL_DUE / 2);

        uint256 lockedNow = vault.claimableRedeemRequest(0, investorB);
        uint256 balBefore = usdc.balanceOf(investorB);
        vm.prank(investorB);
        vault.redeem(lockedNow, investorB, investorB);
        uint256 firstClaim = usdc.balanceOf(investorB) - balBefore;
        // entitlement $66k × 50% = $33k
        assertApproxEqAbs(firstClaim, 33_000e6, 100, "Should receive ~$33k at 50%");

        // Second claim at 100% repayment — claim all remaining locked shares
        vm.prank(borrower); vault.makeRepayment(TOTAL_DUE - TOTAL_DUE / 2);

        uint256 remainingLocked = vault.claimableRedeemRequest(0, investorB);
        assertGt(remainingLocked, 0, "Should have remaining locked shares");

        balBefore = usdc.balanceOf(investorB);
        vm.prank(investorB);
        vault.redeem(remainingLocked, investorB, investorB);
        uint256 secondClaim = usdc.balanceOf(investorB) - balBefore;

        uint256 total = firstClaim + secondClaim;
        assertApproxEqAbs(total, 66_000e6, 100, "Total should be ~$66k");
    }

    function test_RedeemRevertsNothingClaimable() public {
        _fullLifecycleToRepaying();
        // No repayments yet

        vm.prank(investorA);
        vault.requestRedeem(400 * 1e18, investorA, investorA);

        vm.prank(investorA);
        vm.expectRevert("Nothing claimable yet");
        vault.redeem(400 * 1e18, investorA, investorA);
    }

    function test_PriceDoesNotDecreaseForRemainingInvestorAfterRedeem() public {
        _fullLifecycleToRepaying();

        vm.prank(borrower); vault.makeRepayment(TOTAL_DUE / 2);

        uint256 priceBefore = vault.getCurrentSharePrice();

        // A locks all 400 shares and redeems at 50% repayment (gets ~50% of entitlement)
        vm.prank(investorA);
        vault.requestRedeem(400 * 1e18, investorA, investorA);
        uint256 lockedA = vault.claimableRedeemRequest(0, investorA);
        vm.prank(investorA);
        vault.redeem(lockedA, investorA, investorA);

        uint256 priceAfter = vault.getCurrentSharePrice();

        // Price for remaining investors should not decrease.
        // With entitlement-based redemptions, early exiters claim at a slight discount
        // leaving the remaining pool slightly richer per share.
        assertGe(priceAfter, priceBefore, "Remaining investors should not lose value");
    }

    // ─── ERC-7540 Operators ───────────────────────────────────────

    function test_OperatorCanRequestRedeemOnBehalf() public {
        _fullLifecycleToRepaying();
        vm.prank(borrower); vault.makeRepayment(TOTAL_DUE);

        address operator = address(0xAA);
        vm.prank(investorA);
        vault.setOperator(operator, true);

        assertTrue(vault.isOperator(investorA, operator));

        vm.prank(operator);
        vault.requestRedeem(400 * 1e18, investorA, investorA);

        assertEq(vault.claimableRedeemRequest(0, investorA), 400 * 1e18);
    }

    // ─── Protocol Fees ────────────────────────────────────────────

    function test_WithdrawProtocolFees() public {
        _fullLifecycleToRepaying();

        // 50% repayment
        vm.prank(borrower); vault.makeRepayment(TOTAL_DUE / 2);

        uint256 balBefore = usdc.balanceOf(feeCollector);
        vm.prank(feeCollector);
        vault.withdrawProtocolFees();
        uint256 feeReceived = usdc.balanceOf(feeCollector) - balBefore;

        // Expected: $2000 * 50% = $1000
        assertApproxEqAbs(feeReceived, 1_000e6, 10, "Should receive ~$1k fees at 50%");
    }

    function test_RepaymentStatusIncludesFee() public view {
        (uint256 totalDue,,, uint256 protocolFee) = vault.getRepaymentStatus();
        assertEq(totalDue, TOTAL_DUE, "totalDue must include protocol fee");
        assertEq(protocolFee, TOTAL_FEE);
    }

    // ─── Default ──────────────────────────────────────────────────

    function test_MarkDefaulted() public {
        _fullLifecycleToRepaying();

        vm.warp(MATURITY + 1);
        vm.prank(admin);
        vault.markAsDefaulted();

        assertEq(uint8(vault.getVaultState()), uint8(TokenizedBondVault.VaultState.Defaulted));
    }

    // ─── Admin ────────────────────────────────────────────────────

    function test_SetMinInvestment() public {
        vm.prank(admin);
        vault.setMinInvestment(500e6);
        assertEq(vault.minInvestment(), 500e6);
    }

    // ─── ERC-165 ─────────────────────────────────────────────────

    function test_SupportsERC7540Interfaces() public view {
        assertTrue(vault.supportsInterface(0xe3bc4e65), "ERC-7540 operator");
        assertTrue(vault.supportsInterface(0x620ee8e4), "ERC-7540 async redeem");
    }

    // ─── Internal Helpers ─────────────────────────────────────────

    function _fundVault() internal {
        vm.prank(investorA); vault.deposit(40_000e6, investorA); // 400 shares
        vm.prank(investorB); vault.deposit(60_000e6, investorB); // 600 shares
    }

    function _fundAndActivate() internal {
        _fundVault();
        signer.setDoc(CONTRACT_HASH, true, false);
        vm.prank(admin);
        vault.attachContract(CONTRACT_HASH);
    }

    function _borrowerWithdraws() internal {
        vm.prank(borrower);
        vault.withdrawFunds();
    }

    function _fullLifecycleToRepaying() internal {
        _fundAndActivate();
        _borrowerWithdraws();
    }
}

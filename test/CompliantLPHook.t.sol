// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {CompliantLPHook} from "../src/hooks/CompliantLPHook.sol";
import {HookDeployer} from "../src/hooks/HookDeployer.sol";
import {IConvexoPassport} from "../src/interfaces/IConvexoPassport.sol";
import {ProofVerificationParams} from "../src/interfaces/IZKPassportVerifier.sol";
import {IHooks, PoolKey, BeforeSwapDelta, ModifyLiquidityParams, SwapParams, BalanceDelta} from "../src/interfaces/IHooks.sol";
import {IPoolManager} from "../src/interfaces/IPoolManager.sol";

/// @notice Mock Convexo Passport for testing
contract MockConvexoPassport is IConvexoPassport {
    mapping(address => bool) private _hasPassport;

    function setHasPassport(address user, bool has) external {
        _hasPassport[user] = has;
    }

    function holdsActivePassport(address holder) external view returns (bool) {
        return _hasPassport[holder];
    }

    function balanceOf(address holder) external view returns (uint256) {
        return _hasPassport[holder] ? 1 : 0;
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

    function getVerifiedIdentity(address) external pure returns (VerifiedIdentity memory) {
        return VerifiedIdentity({
            uniqueIdentifier: bytes32(0),
            personhoodProof: bytes32(0),
            verifiedAt: 0,
            zkPassportTimestamp: 0,
            isActive: false,
            kycVerified: false,
            faceMatchPassed: false,
            sanctionsPassed: false,
            isOver18: false
        });
    }

    function isIdentifierUsed(bytes32) external pure returns (bool) {
        return false;
    }

    function getActivePassportCount() external pure returns (uint256) {
        return 0;
    }
}

/// @notice Mock PoolManager for testing
contract MockPoolManager is IPoolManager {
    function initialize(PoolKey memory, uint160) external pure returns (int24) {
        return 0;
    }

    function modifyLiquidity(PoolKey memory, ModifyLiquidityParams memory, bytes calldata)
        external
        pure
        returns (BalanceDelta, BalanceDelta)
    {
        return (BalanceDelta.wrap(0), BalanceDelta.wrap(0));
    }

    function swap(PoolKey memory, SwapParams memory, bytes calldata) external pure returns (BalanceDelta) {
        return BalanceDelta.wrap(0);
    }
}

contract CompliantLPHookTest is Test {
    CompliantLPHook public hook;
    MockConvexoPassport public passport;
    MockPoolManager public poolManager;
    HookDeployer public deployer;

    address public passportHolder = address(0x1);
    address public noPassportUser = address(0x2);

    PoolKey public testPool;

    function setUp() public {
        // Deploy mocks
        passport = new MockConvexoPassport();
        poolManager = new MockPoolManager();

        // Deploy hook
        hook = new CompliantLPHook(IPoolManager(address(poolManager)), IConvexoPassport(address(passport)));

        // Deploy hook deployer
        deployer = new HookDeployer();

        // Setup test pool
        testPool = PoolKey({
            currency0: address(0x1000),
            currency1: address(0x2000),
            fee: 3000,
            tickSpacing: 60,
            hooks: address(hook)
        });

        // Give passport to one user
        passport.setHasPassport(passportHolder, true);
    }

    // ============ Setup Tests ============

    function test_Setup() public view {
        assertEq(address(hook.convexoPassport()), address(passport));
        assertEq(address(hook.poolManager()), address(poolManager));
        assertTrue(hook.hasPassportAccess(passportHolder));
        assertFalse(hook.hasPassportAccess(noPassportUser));
    }

    function test_HookPermissions() public view {
        CompliantLPHook.Permissions memory perms = hook.getHookPermissions();
        assertTrue(perms.beforeSwap);
        assertTrue(perms.beforeAddLiquidity);
        assertTrue(perms.beforeRemoveLiquidity);
        assertFalse(perms.afterSwap);
        assertFalse(perms.afterAddLiquidity);
        assertFalse(perms.afterRemoveLiquidity);
    }

    // ============ Swap Tests ============

    function test_BeforeSwap_WithPassport_Succeeds() public {
        SwapParams memory params = SwapParams({zeroForOne: true, amountSpecified: 1000, sqrtPriceLimitX96: 0});

        vm.prank(passportHolder);
        (bytes4 selector,,) = hook.beforeSwap(passportHolder, testPool, params, "");

        assertEq(selector, IHooks.beforeSwap.selector);
    }

    function test_BeforeSwap_WithoutPassport_Reverts() public {
        SwapParams memory params = SwapParams({zeroForOne: true, amountSpecified: 1000, sqrtPriceLimitX96: 0});

        vm.prank(noPassportUser);
        vm.expectRevert(CompliantLPHook.MustHoldActivePassport.selector);
        hook.beforeSwap(noPassportUser, testPool, params, "");
    }

    // ============ Add Liquidity Tests ============

    function test_BeforeAddLiquidity_WithPassport_Succeeds() public {
        ModifyLiquidityParams memory params =
            ModifyLiquidityParams({tickLower: -60, tickUpper: 60, liquidityDelta: 1000000, salt: bytes32(0)});

        vm.prank(passportHolder);
        bytes4 selector = hook.beforeAddLiquidity(passportHolder, testPool, params, "");

        assertEq(selector, IHooks.beforeAddLiquidity.selector);
    }

    function test_BeforeAddLiquidity_WithoutPassport_Reverts() public {
        ModifyLiquidityParams memory params =
            ModifyLiquidityParams({tickLower: -60, tickUpper: 60, liquidityDelta: 1000000, salt: bytes32(0)});

        vm.prank(noPassportUser);
        vm.expectRevert(CompliantLPHook.MustHoldActivePassport.selector);
        hook.beforeAddLiquidity(noPassportUser, testPool, params, "");
    }

    // ============ Remove Liquidity Tests ============

    function test_BeforeRemoveLiquidity_WithPassport_Succeeds() public {
        ModifyLiquidityParams memory params =
            ModifyLiquidityParams({tickLower: -60, tickUpper: 60, liquidityDelta: -1000000, salt: bytes32(0)});

        vm.prank(passportHolder);
        bytes4 selector = hook.beforeRemoveLiquidity(passportHolder, testPool, params, "");

        assertEq(selector, IHooks.beforeRemoveLiquidity.selector);
    }

    function test_BeforeRemoveLiquidity_WithoutPassport_Reverts() public {
        ModifyLiquidityParams memory params =
            ModifyLiquidityParams({tickLower: -60, tickUpper: 60, liquidityDelta: -1000000, salt: bytes32(0)});

        vm.prank(noPassportUser);
        vm.expectRevert(CompliantLPHook.MustHoldActivePassport.selector);
        hook.beforeRemoveLiquidity(noPassportUser, testPool, params, "");
    }

    // ============ Access Change Tests ============

    function test_UserGainsPassport_GainsAccess() public {
        // User starts without passport
        assertFalse(hook.hasPassportAccess(noPassportUser));

        SwapParams memory params = SwapParams({zeroForOne: true, amountSpecified: 1000, sqrtPriceLimitX96: 0});

        // Should fail
        vm.prank(noPassportUser);
        vm.expectRevert(CompliantLPHook.MustHoldActivePassport.selector);
        hook.beforeSwap(noPassportUser, testPool, params, "");

        // Give passport
        passport.setHasPassport(noPassportUser, true);
        assertTrue(hook.hasPassportAccess(noPassportUser));

        // Should now succeed
        vm.prank(noPassportUser);
        (bytes4 selector,,) = hook.beforeSwap(noPassportUser, testPool, params, "");
        assertEq(selector, IHooks.beforeSwap.selector);
    }

    function test_UserLosesPassport_LosesAccess() public {
        // User starts with passport
        assertTrue(hook.hasPassportAccess(passportHolder));

        SwapParams memory params = SwapParams({zeroForOne: true, amountSpecified: 1000, sqrtPriceLimitX96: 0});

        // Should succeed
        vm.prank(passportHolder);
        (bytes4 selector,,) = hook.beforeSwap(passportHolder, testPool, params, "");
        assertEq(selector, IHooks.beforeSwap.selector);

        // Revoke passport
        passport.setHasPassport(passportHolder, false);
        assertFalse(hook.hasPassportAccess(passportHolder));

        // Should now fail
        vm.prank(passportHolder);
        vm.expectRevert(CompliantLPHook.MustHoldActivePassport.selector);
        hook.beforeSwap(passportHolder, testPool, params, "");
    }

    // ============ Event Tests ============

    function test_AccessGranted_Event_OnSwap() public {
        SwapParams memory params = SwapParams({zeroForOne: true, amountSpecified: 1000, sqrtPriceLimitX96: 0});

        vm.expectEmit(true, false, false, true);
        emit CompliantLPHook.AccessGranted(passportHolder, "swap");

        vm.prank(passportHolder);
        hook.beforeSwap(passportHolder, testPool, params, "");
    }

    function test_AccessGranted_Event_OnAddLiquidity() public {
        ModifyLiquidityParams memory params =
            ModifyLiquidityParams({tickLower: -60, tickUpper: 60, liquidityDelta: 1000000, salt: bytes32(0)});

        vm.expectEmit(true, false, false, true);
        emit CompliantLPHook.AccessGranted(passportHolder, "addLiquidity");

        vm.prank(passportHolder);
        hook.beforeAddLiquidity(passportHolder, testPool, params, "");
    }

    // ============ Constructor Tests ============

    function test_Constructor_InvalidPassport_Reverts() public {
        vm.expectRevert(CompliantLPHook.InvalidPassportContract.selector);
        new CompliantLPHook(IPoolManager(address(poolManager)), IConvexoPassport(address(0)));
    }

    // ============ HookDeployer Tests ============

    function test_HookDeployer_ComputeAddress() public view {
        bytes32 salt = bytes32(uint256(1));
        address predicted = deployer.computeAddress(IPoolManager(address(poolManager)), IConvexoPassport(address(passport)), salt);
        assertTrue(predicted != address(0));
    }

    function test_HookDeployer_Deploy() public {
        bytes32 salt = bytes32(uint256(12345));
        
        CompliantLPHook deployedHook = deployer.deploy(
            IPoolManager(address(poolManager)),
            IConvexoPassport(address(passport)),
            salt
        );

        assertEq(address(deployedHook.poolManager()), address(poolManager));
        assertEq(address(deployedHook.convexoPassport()), address(passport));
    }

    function test_HookDeployer_IsValidHookAddress() public view {
        // Address with all required bits set and no unwanted bits
        // Bits: 157, 155, 153 should be set (beforeAddLiquidity, beforeRemoveLiquidity, beforeSwap)
        // This is a simplified check - in reality the address validation is more complex
        address validAddress = address(uint160(1 << 157 | 1 << 155 | 1 << 153));
        assertTrue(deployer.isValidHookAddress(validAddress));

        // Address with unwanted bits set should fail
        address invalidAddress = address(uint160(1 << 159)); // beforeInitialize set
        assertFalse(deployer.isValidHookAddress(invalidAddress));
    }
}

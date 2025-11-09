// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {CompliantLPHook} from "../src/hooks/CompliantLPHook.sol";
import {Convexo_LPs} from "../src/convexolps.sol";
import {IHooks, PoolKey, BeforeSwapDelta, ModifyLiquidityParams, SwapParams} from "../src/interfaces/IHooks.sol";
import {IPoolManager, BalanceDelta} from "../src/interfaces/IPoolManager.sol";
import {IConvexoLPs} from "../src/interfaces/IConvexoLPs.sol";

contract CompliantLPHookTest is Test {
    CompliantLPHook public hook;
    Convexo_LPs public convexoLPs;
    MockPoolManager public poolManager;
    
    address public admin = address(0x156d3C1648ef2f50A8de590a426360Cf6a89C6f8);
    address public minter = address(0x2);
    address public userWithNFT = address(0x3);
    address public userWithoutNFT = address(0x4);
    address public userWithInactiveNFT = address(0x5);
    
    PoolKey public testPool;
    
    function setUp() public {
        // Deploy Convexo_LPs NFT contract
        vm.prank(admin);
        convexoLPs = new Convexo_LPs(admin, minter);
        
        // Deploy mock PoolManager
        poolManager = new MockPoolManager();
        
        // Deploy CompliantLPHook
        hook = new CompliantLPHook(IPoolManager(address(poolManager)), IConvexoLPs(address(convexoLPs)));
        
        // Setup test pool
        testPool = PoolKey({
            currency0: address(0x1000),
            currency1: address(0x2000),
            fee: 3000,
            tickSpacing: 60,
            hooks: address(hook)
        });
        
        // Mint NFT to userWithNFT
        vm.prank(minter);
        uint256 tokenId1 = convexoLPs.safeMint(
            userWithNFT,
            "COMPANY123",
            "ipfs://test1"
        );
        
        // Mint NFT to userWithInactiveNFT and then deactivate it
        vm.prank(minter);
        uint256 tokenId2 = convexoLPs.safeMint(
            userWithInactiveNFT,
            "COMPANY456",
            "ipfs://test2"
        );
        
        // Deactivate the second NFT
        vm.prank(admin);
        convexoLPs.setTokenState(tokenId2, false);
    }
    
    function test_Setup() public view {
        // Verify setup
        assertEq(convexoLPs.balanceOf(userWithNFT), 1);
        assertEq(convexoLPs.balanceOf(userWithoutNFT), 0);
        assertEq(convexoLPs.balanceOf(userWithInactiveNFT), 1);
        
        // Verify hook has correct convexoLPs address
        assertEq(address(hook.convexoLPs()), address(convexoLPs));
    }
    
    function test_BeforeSwap_WithNFT_Succeeds() public {
        // User with NFT should be able to swap
        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: 1000,
            sqrtPriceLimitX96: 0
        });
        
        vm.prank(userWithNFT);
        (bytes4 selector, BeforeSwapDelta delta, uint24 fee) = hook.beforeSwap(
            userWithNFT,
            testPool,
            params,
            ""
        );
        
        assertEq(selector, IHooks.beforeSwap.selector);
    }
    
    function test_BeforeSwap_WithoutNFT_Reverts() public {
        // User without NFT should not be able to swap
        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: 1000,
            sqrtPriceLimitX96: 0
        });
        
        vm.prank(userWithoutNFT);
        vm.expectRevert(CompliantLPHook.MustHoldConvexoLPsNFT.selector);
        hook.beforeSwap(
            userWithoutNFT,
            testPool,
            params,
            ""
        );
    }
    
    function test_BeforeAddLiquidity_WithNFT_Succeeds() public {
        // User with NFT should be able to add liquidity
        ModifyLiquidityParams memory params = ModifyLiquidityParams({
            tickLower: -60,
            tickUpper: 60,
            liquidityDelta: 1000000,
            salt: bytes32(0)
        });
        
        vm.prank(userWithNFT);
        bytes4 selector = hook.beforeAddLiquidity(
            userWithNFT,
            testPool,
            params,
            ""
        );
        
        assertEq(selector, IHooks.beforeAddLiquidity.selector);
    }
    
    function test_BeforeAddLiquidity_WithoutNFT_Reverts() public {
        // User without NFT should not be able to add liquidity
        ModifyLiquidityParams memory params = ModifyLiquidityParams({
            tickLower: -60,
            tickUpper: 60,
            liquidityDelta: 1000000,
            salt: bytes32(0)
        });
        
        vm.prank(userWithoutNFT);
        vm.expectRevert(CompliantLPHook.MustHoldConvexoLPsNFT.selector);
        hook.beforeAddLiquidity(
            userWithoutNFT,
            testPool,
            params,
            ""
        );
    }
    
    function test_BeforeRemoveLiquidity_WithNFT_Succeeds() public {
        // User with NFT should be able to remove liquidity
        ModifyLiquidityParams memory params = ModifyLiquidityParams({
            tickLower: -60,
            tickUpper: 60,
            liquidityDelta: -1000000,
            salt: bytes32(0)
        });
        
        vm.prank(userWithNFT);
        bytes4 selector = hook.beforeRemoveLiquidity(
            userWithNFT,
            testPool,
            params,
            ""
        );
        
        assertEq(selector, IHooks.beforeRemoveLiquidity.selector);
    }
    
    function test_BeforeRemoveLiquidity_WithoutNFT_Reverts() public {
        // User without NFT should not be able to remove liquidity
        ModifyLiquidityParams memory params = ModifyLiquidityParams({
            tickLower: -60,
            tickUpper: 60,
            liquidityDelta: -1000000,
            salt: bytes32(0)
        });
        
        vm.prank(userWithoutNFT);
        vm.expectRevert(CompliantLPHook.MustHoldConvexoLPsNFT.selector);
        hook.beforeRemoveLiquidity(
            userWithoutNFT,
            testPool,
            params,
            ""
        );
    }
    
    function test_AccessGranted_Event() public {
        // Check that AccessGranted event is emitted
        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: 1000,
            sqrtPriceLimitX96: 0
        });
        
        vm.expectEmit(true, false, false, true);
        emit CompliantLPHook.AccessGranted(userWithNFT, 1);
        
        vm.prank(userWithNFT);
        hook.beforeSwap(userWithNFT, testPool, params, "");
    }
    
    function test_AccessDenied_Reverts() public {
        // Check that access is denied and reverts (no event emitted before revert)
        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: 1000,
            sqrtPriceLimitX96: 0
        });
        
        vm.prank(userWithoutNFT);
        vm.expectRevert(CompliantLPHook.MustHoldConvexoLPsNFT.selector);
        hook.beforeSwap(userWithoutNFT, testPool, params, "");
    }
    
    function test_UserLosesNFT_LosesAccess() public {
        // User with NFT burns it and loses access
        vm.prank(userWithNFT);
        convexoLPs.burn(0); // Burn the first token (tokenId 0)
        
        assertEq(convexoLPs.balanceOf(userWithNFT), 0);
        
        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: 1000,
            sqrtPriceLimitX96: 0
        });
        
        vm.prank(userWithNFT);
        vm.expectRevert(CompliantLPHook.MustHoldConvexoLPsNFT.selector);
        hook.beforeSwap(userWithNFT, testPool, params, "");
    }
    
    function test_UserGainsNFT_GainsAccess() public {
        // User without NFT gets one and gains access
        assertEq(convexoLPs.balanceOf(userWithoutNFT), 0);
        
        vm.prank(minter);
        convexoLPs.safeMint(
            userWithoutNFT,
            "COMPANY789",
            "ipfs://test3"
        );
        
        assertEq(convexoLPs.balanceOf(userWithoutNFT), 1);
        
        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: 1000,
            sqrtPriceLimitX96: 0
        });
        
        vm.prank(userWithoutNFT);
        (bytes4 selector,,) = hook.beforeSwap(userWithoutNFT, testPool, params, "");
        assertEq(selector, IHooks.beforeSwap.selector);
    }
    
    function test_MultipleNFTs_StillWorks() public {
        // User with multiple NFTs should still have access
        vm.prank(minter);
        convexoLPs.safeMint(
            userWithNFT,
            "COMPANY999",
            "ipfs://test4"
        );
        
        assertEq(convexoLPs.balanceOf(userWithNFT), 2);
        
        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: 1000,
            sqrtPriceLimitX96: 0
        });
        
        vm.prank(userWithNFT);
        (bytes4 selector,,) = hook.beforeSwap(userWithNFT, testPool, params, "");
        assertEq(selector, IHooks.beforeSwap.selector);
    }
}

/// @notice Mock PoolManager for testing
contract MockPoolManager is IPoolManager {
    // Minimal mock implementation - just needs to exist for constructor
    
    function initialize(PoolKey memory, uint160) external pure returns (int24) {
        return 0;
    }
    
    function modifyLiquidity(
        PoolKey memory,
        ModifyLiquidityParams memory,
        bytes calldata
    ) external pure returns (BalanceDelta, BalanceDelta) {
        return (BalanceDelta.wrap(0), BalanceDelta.wrap(0));
    }
    
    function swap(PoolKey memory, SwapParams memory, bytes calldata)
        external
        pure
        returns (BalanceDelta)
    {
        return BalanceDelta.wrap(0);
    }
}

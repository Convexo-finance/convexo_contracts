// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {Actions} from "v4-periphery/src/libraries/Actions.sol";

/// @title RemoveLiquidity
/// @notice Withdraws all liquidity from positions in the OLD pool (before hook redeploy).
///         Works because deployer holds LP_Individuals NFT (Tier 2 ≥ Tier 1 check on old hook).
///
/// Step 1 — Find your position token IDs:
///   cast call <POSITION_MANAGER> "balanceOf(address)(uint256)" <DEPLOYER> --rpc-url <RPC>
///   cast call <POSITION_MANAGER> "tokenByIndex(uint256)(uint256)" 0 --rpc-url <RPC>
///   cast call <POSITION_MANAGER> "tokenByIndex(uint256)(uint256)" 1 --rpc-url <RPC>
///
///   Or if PositionManager doesn't support enumerable, check the AddLiquidity broadcast:
///     jq '.[].logs[] | select(.topics[0] == "Transfer event sig")' broadcast/AddLiquidity.s.sol/11155111/run-latest.json
///
///   POSITION_MANAGER on ETH Sepolia: 0x429ba70129df741B2Ca2a85BC3A2a3328e5c09b4
///
/// Step 2 — Run this script:
///   PRIVATE_KEY=... \
///   OLD_HOOK=0xA4c7d0f1bb255460C7b3CBE9910318CB57Cb8A80 \
///   TOKEN0=0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238 \
///   TOKEN1=0x19ac2612e560b2bbedf88660a2566ef53c0a15a1 \
///   TOKEN_IDS=<id1>,<id2> \
///   forge script script/RemoveLiquidity.s.sol \
///     --rpc-url https://eth-sepolia.g.alchemy.com/v2/<key> \
///     --broadcast -vv
contract RemoveLiquidity is Script {
    uint24 constant FEE          = 500;
    int24  constant TICK_SPACING = 10;

    function getPositionManager() internal view returns (address) {
        if (block.chainid == 11155111) return vm.envOr("POSITION_MANAGER", 0x429ba70129df741B2Ca2a85BC3A2a3328e5c09b4);
        if (block.chainid == 84532)   return vm.envOr("POSITION_MANAGER", 0x4B2C77d209D3405F41a037Ec6c77F7F5b8e2ca80);
        revert("Unsupported chain");
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer           = vm.addr(deployerPrivateKey);
        address hookAddress        = vm.envAddress("OLD_HOOK");
        address token0Env          = vm.envAddress("TOKEN0");
        address token1Env          = vm.envAddress("TOKEN1");
        string  memory tokenIdsCsv = vm.envString("TOKEN_IDS");

        // V4 requires currency0 < currency1
        (address currency0, address currency1) = token0Env < token1Env
            ? (token0Env, token1Env)
            : (token1Env, token0Env);

        address positionManager = getPositionManager();

        // Parse TOKEN_IDS — comma-separated list of uint256
        uint256[] memory tokenIds = _parseIds(tokenIdsCsv);

        console.log("=== RemoveLiquidity (old pool) ===");
        console.log("Chain:", block.chainid);
        console.log("Deployer:", deployer);
        console.log("Old hook:", hookAddress);
        console.log("Currency0:", currency0);
        console.log("Currency1:", currency1);
        console.log("Positions to remove:", tokenIds.length);

        PoolKey memory key = PoolKey({
            currency0:   Currency.wrap(currency0),
            currency1:   Currency.wrap(currency1),
            fee:         FEE,
            tickSpacing: TICK_SPACING,
            hooks:       IHooks(hookAddress)
        });

        vm.startBroadcast(deployerPrivateKey);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            console.log("Removing position tokenId:", tokenId);

            // BURN_POSITION removes ALL liquidity + burns the NFT in one action.
            // No need to query liquidity amount first.
            // hookData = abi.encode(deployer): hook checks deployer has LP_Individuals NFT (Tier 2 >= Tier 1).
            bytes memory actions = abi.encodePacked(
                uint8(Actions.BURN_POSITION),
                uint8(Actions.TAKE_PAIR)
            );

            bytes[] memory params = new bytes[](2);
            params[0] = abi.encode(
                tokenId,
                uint128(0),           // amount0Min — no slippage protection on testnet
                uint128(0),           // amount1Min
                abi.encode(deployer)  // hookData: deployer = user (has LP_Individuals NFT)
            );
            params[1] = abi.encode(
                Currency.wrap(currency0),
                Currency.wrap(currency1),
                deployer  // recipient
            );

            (bool success, bytes memory returnData) = positionManager.call(
                abi.encodeWithSignature(
                    "modifyLiquidities(bytes,uint256)",
                    abi.encode(actions, params),
                    block.timestamp + 120
                )
            );

            if (!success) {
                console.log("  [WARN] modifyLiquidities failed for tokenId", tokenId);
                if (returnData.length > 0) {
                    console.logBytes(returnData);
                }
            } else {
                console.log("  [OK] Liquidity removed for tokenId", tokenId);
            }
        }

        vm.stopBroadcast();

        // Log balances
        uint256 bal0 = IERC20(currency0).balanceOf(deployer);
        uint256 bal1 = IERC20(currency1).balanceOf(deployer);
        console.log("\n=== Deployer balances after removal ===");
        console.log("Currency0 (raw):", bal0);
        console.log("Currency1 (raw):", bal1);
        console.log("USDC (6 dec):   ", bal0 / 1e6, ".", (bal0 % 1e6) / 1000);
        console.log("\nTokens ready to seed new pool.");
    }

    /// @dev Parse "123,456,789" → [123, 456, 789]
    function _parseIds(string memory csv) internal pure returns (uint256[] memory) {
        // Count commas
        bytes memory b = bytes(csv);
        uint256 count = 1;
        for (uint256 i = 0; i < b.length; i++) {
            if (b[i] == ",") count++;
        }

        uint256[] memory ids = new uint256[](count);
        uint256 idx = 0;
        uint256 cur = 0;

        for (uint256 i = 0; i <= b.length; i++) {
            if (i == b.length || b[i] == ",") {
                ids[idx++] = cur;
                cur = 0;
            } else {
                require(b[i] >= "0" && b[i] <= "9", "Invalid char in TOKEN_IDS");
                cur = cur * 10 + (uint8(b[i]) - 48);
            }
        }
        return ids;
    }
}

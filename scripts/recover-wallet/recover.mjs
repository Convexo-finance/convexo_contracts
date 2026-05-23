/**
 * Recovery script for Alchemy Modular Account 0x3894953E...
 * Chain: ETH Sepolia (11155111)
 *
 * Prerequisites:
 *   1. Copy .env.example → .env and fill in the values
 *   2. npm install
 *   3. npm run recover
 */

import { createAlchemySmartAccountClient, alchemy } from "@account-kit/infra";
import { createMultiOwnerModularAccount } from "@account-kit/smart-contracts";
import { LocalAccountSigner } from "@aa-sdk/core";
import { sepolia } from "viem/chains";
import { encodeFunctionData } from "viem";

// ─── Config ──────────────────────────────────────────────────────────────────

const SMART_WALLET   = "0x3894953E46dBc64002917907502Cf9DAd033E356";
const USDC           = "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238";
const ECOP           = "0x19ac2612E560B2BbeDF88660a2566eF53C0a15A1";
const USDC_BALANCE   = 880_000000n;                      // 880 USDC  (6 decimals)
const ECOP_BALANCE   = 5429537981736300277203608n;        // full balance (18 decimals)

const ERC20_TRANSFER_ABI = [{
  name: "transfer",
  type: "function",
  inputs: [
    { name: "to",     type: "address" },
    { name: "amount", type: "uint256" },
  ],
  outputs: [{ name: "", type: "bool" }],
}];

// ─── Env validation ───────────────────────────────────────────────────────────

const { EOA_PRIVATE_KEY, ALCHEMY_API_KEY, DESTINATION_WALLET } = process.env;

if (!EOA_PRIVATE_KEY || !ALCHEMY_API_KEY || !DESTINATION_WALLET) {
  console.error("❌  Missing env vars. Copy .env.example → .env and fill in:");
  console.error("    EOA_PRIVATE_KEY, ALCHEMY_API_KEY, DESTINATION_WALLET");
  process.exit(1);
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function recover() {
  console.log("🔑  Building signer from EOA private key...");
  const signer = LocalAccountSigner.privateKeyToAccountSigner(EOA_PRIVATE_KEY);
  const signerAddress = await signer.getAddress();
  console.log("    EOA address:", signerAddress);

  console.log("\n🔌  Connecting to existing smart wallet...");
  const account = await createMultiOwnerModularAccount({
    transport: alchemy({ apiKey: ALCHEMY_API_KEY }),
    chain: sepolia,
    signer,
    accountAddress: SMART_WALLET,
  });

  const client = await createAlchemySmartAccountClient({
    transport: alchemy({ apiKey: ALCHEMY_API_KEY }),
    chain: sepolia,
    account,
  });

  const connectedAddress = await client.getAddress();
  console.log("    Smart wallet:", connectedAddress);

  if (connectedAddress.toLowerCase() !== SMART_WALLET.toLowerCase()) {
    console.error("❌  Address mismatch — wrong EOA private key for this smart wallet.");
    process.exit(1);
  }

  console.log("\n📦  Destination wallet:", DESTINATION_WALLET);
  console.log("    USDC to transfer:  880 USDC");
  console.log("    ECOP to transfer:  5,429,537.98 ECOP");

  // Batch both transfers into a single UserOperation
  console.log("\n🚀  Sending batched UserOperation...");
  const { hash: uoHash } = await client.sendUserOperation({
    uo: [
      {
        target: USDC,
        data: encodeFunctionData({
          abi: ERC20_TRANSFER_ABI,
          functionName: "transfer",
          args: [DESTINATION_WALLET, USDC_BALANCE],
        }),
      },
      {
        target: ECOP,
        data: encodeFunctionData({
          abi: ERC20_TRANSFER_ABI,
          functionName: "transfer",
          args: [DESTINATION_WALLET, ECOP_BALANCE],
        }),
      },
    ],
  });

  console.log("    UserOperation hash:", uoHash);
  console.log("\n⏳  Waiting for inclusion...");

  const receipt = await client.waitForUserOperationReceipt({ hash: uoHash });
  console.log("    Transaction hash:", receipt.receipt.transactionHash);
  console.log("\n✅  Recovery complete!");
  console.log(`    View on Etherscan: https://sepolia.etherscan.io/tx/${receipt.receipt.transactionHash}`);
}

recover().catch((err) => {
  console.error("❌  Error:", err.message ?? err);
  process.exit(1);
});

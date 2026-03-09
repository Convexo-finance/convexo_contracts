// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/// @title ITokenizedBondVault
/// @notice Interface for TokenizedBondVault — ERC-4626 base + ERC-7540 async redeem
interface ITokenizedBondVault {

    // ─── Types ───────────────────────────────────────────────────

    enum VaultState { Pending, Funded, Active, Repaying, Completed, Defaulted }

    struct RedeemState {
        uint256 originalLockedShares;
        uint256 remainingLockedShares;
        uint256 assetsClaimed;
    }

    // ─── Events ──────────────────────────────────────────────────

    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);
    event Withdraw(address indexed sender, address indexed receiver, address indexed owner, uint256 assets, uint256 shares);
    event RedeemRequest(address indexed controller, address indexed owner, uint256 indexed requestId, address sender, uint256 shares);
    event OperatorSet(address indexed controller, address indexed operator, bool approved);
    event VaultStateChanged(VaultState newState);
    event VaultFullyFunded(uint256 indexed vaultId, uint256 timestamp);
    event ContractAttached(uint256 indexed vaultId, bytes32 contractHash);
    event FundsWithdrawn(address indexed borrower, uint256 amount);
    event RepaymentMade(address indexed payer, uint256 amount, uint256 totalRepaid);
    event ProtocolFeesCollected(uint256 amount);
    event MinInvestmentUpdated(uint256 oldMin, uint256 newMin);

    // ─── ERC-4626 ────────────────────────────────────────────────

    function asset() external view returns (address);
    function totalAssets() external view returns (uint256);
    function convertToShares(uint256 assets) external view returns (uint256);
    function convertToAssets(uint256 shares) external view returns (uint256);
    function maxDeposit(address receiver) external view returns (uint256);
    function previewDeposit(uint256 assets) external view returns (uint256);
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    // ─── Share Price ──────────────────────────────────────────────

    /// @notice Initial price per whole share (principalAmount / totalShareSupply)
    function getBaseSharePrice() external view returns (uint256);

    /// @notice Expected price per whole share at full repayment
    function getExpectedFinalSharePrice() external view returns (uint256);

    /// @notice Current price per whole share (rises as repayments arrive)
    function getCurrentSharePrice() external view returns (uint256);

    // ─── ERC-7540 Async Redeem ────────────────────────────────────

    /// @notice Lock shares for async redemption (Repaying/Completed state)
    function requestRedeem(uint256 shares, address controller, address owner) external returns (uint256 requestId);

    /// @notice Shares in pending state (always 0 — all requests immediately claimable)
    function pendingRedeemRequest(uint256 requestId, address controller) external view returns (uint256);

    /// @notice Locked shares claimable by controller
    function claimableRedeemRequest(uint256 requestId, address controller) external view returns (uint256);

    /// @notice Claim USDC for locked shares proportional to repayments made
    function redeem(uint256 shares, address receiver, address controller) external returns (uint256 assets);

    /// @notice Grant or revoke operator permission
    function setOperator(address operator, bool approved) external returns (bool);

    /// @notice Check if operator is approved for controller
    function isOperator(address controller, address operator) external view returns (bool);

    // ─── Early Exit ───────────────────────────────────────────────

    /// @notice Exit before borrower withdraws — returns principal at base price
    function earlyExit(uint256 shares) external;

    // ─── Vault Lifecycle ─────────────────────────────────────────

    function attachContract(bytes32 contractHash) external;
    function withdrawFunds() external;
    function makeRepayment(uint256 amount) external;
    function markAsDefaulted() external;
    function withdrawProtocolFees() external;
    function setMinInvestment(uint256 newMin) external;

    // ─── Views ────────────────────────────────────────────────────

    function originalTotalShares() external view returns (uint256);
    function minInvestment() external view returns (uint256);
    function protocolFeeCollector() external view returns (address);
    function protocolFeesWithdrawn() external view returns (uint256);
    function getAvailableForInvestors() external view returns (uint256);

    function getRepaymentStatus()
        external
        view
        returns (uint256 totalDue, uint256 totalPaid, uint256 remaining, uint256 protocolFee);

    function getVaultMetrics()
        external
        view
        returns (
            uint256 totalShares,
            uint256 sharePrice,
            uint256 totalValueLocked,
            uint256 targetAmount,
            uint256 fundingProgress,
            uint256 expectedFinalSharePrice
        );

    function getInvestorReturn(address investor)
        external
        view
        returns (
            uint256 invested,
            uint256 currentValue,
            uint256 profit,
            uint256 expectedAtMaturity
        );

    function getRedeemState(address controller)
        external
        view
        returns (
            uint256 originalLockedShares,
            uint256 remainingLockedShares,
            uint256 assetsClaimed,
            uint256 claimableNow
        );

    function getVaultState() external view returns (VaultState);
    function getVaultBalance() external view returns (uint256);
    function getVaultBorrower() external view returns (address);
    function getVaultPrincipalAmount() external view returns (uint256);
    function getVaultTotalRaised() external view returns (uint256);
    function getVaultTotalRepaid() external view returns (uint256);
    function getVaultContractHash() external view returns (bytes32);
    function getVaultFundedAt() external view returns (uint256);
    function getVaultFundsWithdrawnAt() external view returns (uint256);
    function getActualDueDate() external view returns (uint256);
    function getInvestors() external view returns (address[] memory);
    function isInvestorAddress(address account) external view returns (bool);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

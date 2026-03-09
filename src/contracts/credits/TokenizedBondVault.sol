// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IContractSigner} from "../../interfaces/IContractSigner.sol";
import {ReputationManager} from "../identity/ReputationManager.sol";

/// @title TokenizedBondVault
/// @notice Fixed-term tokenized bond vault with configurable share supply.
///
/// @dev Economic model:
///   - Borrower defines `totalShareSupply` (e.g. 1000 shares).
///   - initialSharePrice  = principalAmount / totalShareSupply   (e.g. $100/share)
///   - expectedFinalPrice = (principal + interest - fee) / totalShareSupply  (e.g. $110/share)
///   - currentSharePrice  = availableForInvestors / currentTotalSupply  (rises as repayments arrive)
///
/// @dev ERC-7540 Async Redemption:
///   State lifecycle maps to ERC-7540:
///     Pending/Funded/Active  → Deposit phase (synchronous)
///     Repaying               → requestRedeem is open; claimable = entitlement × repaidFraction
///     Completed              → All debt repaid; final claims possible
///
///   Redemption flow:
///     1. investor calls requestRedeem(shares) → shares locked in vault
///     2. investor calls redeem(shares, receiver, controller) → claims proportional USDC;
///        shares burned proportionally to fraction of entitlement claimed.
///        Multiple calls possible as repayments accumulate.
///
/// @dev ERC-165 interface IDs:
///   0xe3bc4e65 = ERC-7540 operator methods
///   0x620ee8e4 = ERC-7540 async redeem
contract TokenizedBondVault is ERC20, AccessControl, ReentrancyGuard {
    using Math for uint256;

    bytes32 public constant VAULT_MANAGER_ROLE = keccak256("VAULT_MANAGER_ROLE");

    // ─────────────────────────────────────────────────────────────
    // Types
    // ─────────────────────────────────────────────────────────────

    enum VaultState {
        Pending,    // Accepting investments
        Funded,     // Fully funded, awaiting contract signature
        Active,     // Contract signed, borrower can withdraw
        Repaying,   // Funds disbursed, borrower making repayments
        Completed,  // All debt repaid and all investor claims settled
        Defaulted   // Maturity passed without full repayment
    }

    struct VaultInfo {
        uint256 vaultId;
        address borrower;
        bytes32 contractHash;
        uint256 principalAmount;      // USDC (6 decimals)
        uint256 interestRate;         // Basis points (e.g. 1200 = 12%)
        uint256 protocolFeeRate;      // Basis points (e.g. 200 = 2%)
        uint256 maturityDate;         // Timestamp: deadline for full repayment
        VaultState state;
        uint256 totalRaised;
        uint256 totalRepaid;
        uint256 createdAt;
        uint256 fundedAt;
        uint256 contractAttachedAt;
        uint256 fundsWithdrawnAt;
    }

    /// @notice Per-controller ERC-7540 redemption state
    struct RedeemState {
        uint256 originalLockedShares; // Total shares locked via requestRedeem (never decreases)
        uint256 remainingLockedShares;// Shares still locked in vault (decreases as burned)
        uint256 assetsClaimed;        // Total USDC claimed so far
    }

    // ─────────────────────────────────────────────────────────────
    // Immutables & Storage
    // ─────────────────────────────────────────────────────────────

    /// @notice Total shares ever issuable (in share-wei = totalShareSupply × 1e18)
    uint256 public immutable originalTotalShares;

    /// @notice Minimum USDC per deposit (6 decimals, settable by VAULT_MANAGER_ROLE)
    uint256 public minInvestment;

    VaultInfo public vaultInfo;

    IERC20 public immutable usdc;
    address public immutable contractSigner;
    ReputationManager public immutable reputationManager;
    address public protocolFeeCollector;
    uint256 public protocolFeesWithdrawn;

    /// @notice ERC-7540 operator approvals
    mapping(address controller => mapping(address operator => bool)) public isOperator;

    /// @notice ERC-7540 redemption state per controller
    mapping(address => RedeemState) private _redeemRequests;

    address[] private _investors;
    mapping(address => bool) private _isInvestor;

    // ─────────────────────────────────────────────────────────────
    // Events
    // ─────────────────────────────────────────────────────────────

    // ERC-4626
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);
    event Withdraw(address indexed sender, address indexed receiver, address indexed owner, uint256 assets, uint256 shares);

    // ERC-7540
    event RedeemRequest(address indexed controller, address indexed owner, uint256 indexed requestId, address sender, uint256 shares);
    event OperatorSet(address indexed controller, address indexed operator, bool approved);

    // Vault lifecycle
    event VaultStateChanged(VaultState newState);
    event VaultFullyFunded(uint256 indexed vaultId, uint256 timestamp);
    event ContractAttached(uint256 indexed vaultId, bytes32 contractHash);
    event FundsWithdrawn(address indexed borrower, uint256 amount);
    event RepaymentMade(address indexed payer, uint256 amount, uint256 totalRepaid);
    event ProtocolFeesCollected(uint256 amount);
    event MinInvestmentUpdated(uint256 oldMin, uint256 newMin);

    // ─────────────────────────────────────────────────────────────
    // Constructor
    // ─────────────────────────────────────────────────────────────

    constructor(
        uint256 _vaultId,
        address _borrower,
        uint256 _principalAmount,
        uint256 _interestRate,
        uint256 _protocolFeeRate,
        uint256 _maturityDate,
        uint256 _totalShareSupply,  // Whole-share count (e.g. 1000)
        uint256 _minInvestment,     // USDC min per deposit (6 decimals)
        address _usdc,
        address _contractSigner,
        address _admin,
        address _protocolFeeCollector,
        ReputationManager _reputationManager,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        require(_principalAmount > 0, "Invalid principal");
        require(_totalShareSupply > 0, "Invalid share supply");
        require(_interestRate <= 10000, "Invalid interest rate");
        require(_protocolFeeRate <= 1000, "Protocol fee too high");
        require(_maturityDate > block.timestamp, "Maturity must be future");
        require(_minInvestment > 0, "Min investment must be > 0");
        require(_borrower != address(0), "Invalid borrower");
        require(_admin != address(0), "Invalid admin");

        vaultInfo = VaultInfo({
            vaultId: _vaultId,
            borrower: _borrower,
            contractHash: bytes32(0),
            principalAmount: _principalAmount,
            interestRate: _interestRate,
            protocolFeeRate: _protocolFeeRate,
            maturityDate: _maturityDate,
            state: VaultState.Pending,
            totalRaised: 0,
            totalRepaid: 0,
            createdAt: block.timestamp,
            fundedAt: 0,
            contractAttachedAt: 0,
            fundsWithdrawnAt: 0
        });

        originalTotalShares = _totalShareSupply * 1e18;
        minInvestment = _minInvestment;
        usdc = IERC20(_usdc);
        contractSigner = _contractSigner;
        reputationManager = _reputationManager;
        protocolFeeCollector = _protocolFeeCollector;

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(VAULT_MANAGER_ROLE, _admin);
    }

    // ─────────────────────────────────────────────────────────────
    // ERC-4626: View Functions
    // ─────────────────────────────────────────────────────────────

    /// @notice The underlying USDC token
    function asset() external view returns (address) {
        return address(usdc);
    }

    /// @notice Total USDC held in this vault
    function totalAssets() public view returns (uint256) {
        return usdc.balanceOf(address(this));
    }

    /// @notice Shares minted for a given USDC deposit amount (valid during Pending)
    function convertToShares(uint256 assets) public view returns (uint256) {
        if (vaultInfo.principalAmount == 0) return 0;
        return assets.mulDiv(originalTotalShares, vaultInfo.principalAmount);
    }

    /// @notice USDC value of given shares at current state
    function convertToAssets(uint256 shares) public view returns (uint256) {
        // Before disbursement: base price (doesn't depend on current supply)
        if (
            vaultInfo.state == VaultState.Pending ||
            vaultInfo.state == VaultState.Funded ||
            vaultInfo.state == VaultState.Active
        ) {
            if (originalTotalShares == 0) return 0;
            return shares.mulDiv(vaultInfo.principalAmount, originalTotalShares);
        }
        // During/after repayment: use current interpolated share price
        uint256 price = getCurrentSharePrice();
        return shares.mulDiv(price, 1e18);
    }

    /// @notice Maximum USDC depositable (0 when not in Pending)
    function maxDeposit(address) external view returns (uint256) {
        if (vaultInfo.state != VaultState.Pending) return 0;
        return vaultInfo.principalAmount - vaultInfo.totalRaised;
    }

    /// @notice Preview shares for deposit amount
    function previewDeposit(uint256 assets) external view returns (uint256) {
        if (vaultInfo.state != VaultState.Pending) return 0;
        return convertToShares(assets);
    }

    // ─────────────────────────────────────────────────────────────
    // Share Price Views
    // ─────────────────────────────────────────────────────────────

    /// @notice Initial price per whole share in USDC (6 decimals)
    /// @dev = principalAmount / totalShareSupply
    function getBaseSharePrice() external view returns (uint256) {
        return vaultInfo.principalAmount.mulDiv(1e18, originalTotalShares);
    }

    /// @notice Expected price per whole share at full repayment (USDC, 6 decimals)
    /// @dev = (principal + interest - protocolFee) / totalShareSupply
    function getExpectedFinalSharePrice() external view returns (uint256) {
        uint256 netForInvestors = _getNetForInvestors();
        return netForInvestors.mulDiv(1e18, originalTotalShares);
    }

    /// @notice Current price per whole share (USDC, 6 decimals)
    /// @dev Interpolates between baseSharePrice and expectedFinalSharePrice
    ///      based on the fraction of total debt repaid. This gives a deterministic,
    ///      redemption-order-independent price that investors can trust.
    ///
    ///   currentSharePrice = basePrice + (expectedFinalPrice - basePrice) × repaidFraction
    ///
    ///   At 0% repaid  → baseSharePrice           (e.g. $100)
    ///   At 50% repaid → midpoint price            (e.g. $105)
    ///   At 100% repaid → expectedFinalSharePrice  (e.g. $110)
    function getCurrentSharePrice() public view returns (uint256) {
        if (originalTotalShares == 0) return 0;

        uint256 basePrice = vaultInfo.principalAmount.mulDiv(1e18, originalTotalShares);

        if (
            vaultInfo.state == VaultState.Pending ||
            vaultInfo.state == VaultState.Funded ||
            vaultInfo.state == VaultState.Active
        ) {
            return basePrice;
        }

        if (vaultInfo.state == VaultState.Completed) {
            return _getNetForInvestors().mulDiv(1e18, originalTotalShares);
        }

        // Repaying: interpolate based on repaid fraction
        uint256 totalDue = _getTotalDue();
        if (totalDue == 0) return basePrice;

        uint256 repaidFraction = Math.min(1e18, vaultInfo.totalRepaid.mulDiv(1e18, totalDue));
        uint256 netForInvestors = _getNetForInvestors();
        uint256 expectedFinalPrice = netForInvestors.mulDiv(1e18, originalTotalShares);

        if (expectedFinalPrice <= basePrice) return basePrice;
        uint256 priceRange = expectedFinalPrice - basePrice;
        return basePrice + priceRange.mulDiv(repaidFraction, 1e18);
    }

    // ─────────────────────────────────────────────────────────────
    // ERC-4626: Deposit (synchronous, Pending state only)
    // ─────────────────────────────────────────────────────────────

    /// @notice Purchase vault shares by depositing USDC
    /// @param assets USDC to deposit (6 decimals)
    /// @param receiver Address receiving the shares
    /// @return shares Amount of shares (18 decimals) minted
    function deposit(uint256 assets, address receiver) external nonReentrant returns (uint256 shares) {
        require(reputationManager.canInvestInVaults(msg.sender), "Tier 1+ required to invest");
        require(vaultInfo.state == VaultState.Pending, "Not accepting deposits");
        require(assets >= minInvestment, "Below minimum investment");
        require(vaultInfo.totalRaised + assets <= vaultInfo.principalAmount, "Exceeds funding target");
        require(receiver != address(0), "Invalid receiver");

        shares = convertToShares(assets);
        require(shares > 0, "Zero shares");

        if (!_isInvestor[receiver]) {
            _investors.push(receiver);
            _isInvestor[receiver] = true;
        }

        require(usdc.transferFrom(msg.sender, address(this), assets), "USDC transfer failed");
        _mint(receiver, shares);
        vaultInfo.totalRaised += assets;

        emit Deposit(msg.sender, receiver, assets, shares);

        if (vaultInfo.totalRaised == vaultInfo.principalAmount) {
            vaultInfo.state = VaultState.Funded;
            vaultInfo.fundedAt = block.timestamp;
            emit VaultStateChanged(VaultState.Funded);
            emit VaultFullyFunded(vaultInfo.vaultId, block.timestamp);
        }
    }

    // ─────────────────────────────────────────────────────────────
    // Early Exit (Funded / Active — before borrower withdraws)
    // ─────────────────────────────────────────────────────────────

    /// @notice Exit before borrower withdraws. Returns principal at base price (1:1 USDC per share).
    /// @param shares Shares to burn
    function earlyExit(uint256 shares) external nonReentrant {
        require(
            vaultInfo.state == VaultState.Funded || vaultInfo.state == VaultState.Active,
            "Early exit only before disbursement"
        );
        require(shares > 0, "Zero shares");
        require(balanceOf(msg.sender) >= shares, "Insufficient shares");

        uint256 assets = shares.mulDiv(vaultInfo.principalAmount, originalTotalShares);
        require(usdc.balanceOf(address(this)) >= assets, "Insufficient vault balance");

        _burn(msg.sender, shares);
        vaultInfo.totalRaised -= assets;
        require(usdc.transfer(msg.sender, assets), "USDC transfer failed");

        // Revert to Pending if target no longer met
        if (vaultInfo.totalRaised < vaultInfo.principalAmount) {
            vaultInfo.state = VaultState.Pending;
            vaultInfo.fundedAt = 0;
            vaultInfo.contractAttachedAt = 0;
            vaultInfo.contractHash = bytes32(0);
            emit VaultStateChanged(VaultState.Pending);
        }

        emit Withdraw(msg.sender, msg.sender, msg.sender, assets, shares);
    }

    // ─────────────────────────────────────────────────────────────
    // ERC-7540: Async Redeem (Repaying / Completed)
    // ─────────────────────────────────────────────────────────────

    /// @notice ERC-7540: Lock shares for async redemption.
    ///         Shares transfer from owner to vault. All locked shares are immediately claimable
    ///         proportional to the current repaid fraction.
    /// @param shares Share-wei to lock
    /// @param controller Address that controls the claim (receives assets on redeem)
    /// @param owner Address whose shares are locked (must be msg.sender or operator)
    /// @return requestId Always 0 (aggregated per-controller, per ERC-7540 requestId==0 spec)
    function requestRedeem(
        uint256 shares,
        address controller,
        address owner
    ) external nonReentrant returns (uint256 requestId) {
        require(
            vaultInfo.state == VaultState.Repaying || vaultInfo.state == VaultState.Completed,
            "Not in repaying state"
        );
        require(shares > 0, "Zero shares");
        require(owner == msg.sender || isOperator[owner][msg.sender], "Not authorized");
        require(balanceOf(owner) >= shares, "Insufficient shares");
        require(controller != address(0), "Invalid controller");

        // Transfer shares to vault (locked, not yet burned)
        _transfer(owner, address(this), shares);

        RedeemState storage rs = _redeemRequests[controller];
        rs.originalLockedShares += shares;
        rs.remainingLockedShares += shares;

        emit RedeemRequest(controller, owner, 0, msg.sender, shares);
        return 0;
    }

    /// @notice ERC-7540: Shares pending fulfillment for controller.
    ///         In this vault all requests are immediately claimable (no waiting period).
    function pendingRedeemRequest(uint256, address) external pure returns (uint256) {
        return 0; // All requests transition directly to claimable
    }

    /// @notice ERC-7540: Shares claimable by controller right now (locked shares in vault)
    function claimableRedeemRequest(uint256, address controller) public view returns (uint256) {
        return _redeemRequests[controller].remainingLockedShares;
    }

    /// @notice ERC-7540 / ERC-4626: Claim USDC for locked shares, proportional to repayments.
    ///
    /// @dev Math:
    ///   entitlement = originalLockedShares × netForInvestors / originalTotalShares
    ///   claimableNow = entitlement × repaidFraction - assetsClaimed
    ///   sharesBurned  = remainingLockedShares × claimableNow / (entitlement - assetsClaimed)
    ///
    ///   Multiple calls allowed as repayments accumulate. Shares burned proportionally to
    ///   the fraction of entitlement being claimed in each call. Price is unaffected for
    ///   remaining investors because both available-USDC and totalSupply shrink proportionally.
    ///
    /// @param shares Share-wei to process in this call (≤ remainingLockedShares)
    /// @param receiver Address receiving USDC
    /// @param controller Controller address (msg.sender or operator)
    /// @return assets USDC transferred
    function redeem(
        uint256 shares,
        address receiver,
        address controller
    ) external nonReentrant returns (uint256 assets) {
        require(controller == msg.sender || isOperator[controller][msg.sender], "Not authorized");
        require(shares > 0, "Zero shares");
        require(receiver != address(0), "Invalid receiver");

        RedeemState storage rs = _redeemRequests[controller];
        require(shares <= rs.remainingLockedShares, "Exceeds locked shares");

        uint256 totalDue = _getTotalDue();
        require(totalDue > 0, "Invalid vault state");

        // repaidFraction ∈ [0, 1e18]
        uint256 repaidFraction = Math.min(1e18, vaultInfo.totalRepaid.mulDiv(1e18, totalDue));

        // Total entitlement for ALL originally locked shares
        uint256 netForInvestors = _getNetForInvestors();
        uint256 totalEntitlement = rs.originalLockedShares.mulDiv(netForInvestors, originalTotalShares);

        // How much of that entitlement is claimable now (based on repayment progress)
        uint256 totalClaimableNow = totalEntitlement.mulDiv(repaidFraction, 1e18);

        // Subtract what's already been claimed
        uint256 availableNow = totalClaimableNow > rs.assetsClaimed
            ? totalClaimableNow - rs.assetsClaimed
            : 0;
        require(availableNow > 0, "Nothing claimable yet");

        // Remaining entitlement (denominator for proportional burn)
        uint256 remainingEntitlement = totalEntitlement > rs.assetsClaimed
            ? totalEntitlement - rs.assetsClaimed
            : 0;
        require(remainingEntitlement > 0, "Entitlement exhausted");

        // Assets for this specific shares tranche (proportional to locked)
        assets = shares.mulDiv(availableNow, rs.remainingLockedShares);
        require(assets > 0, "Zero assets for shares");
        require(usdc.balanceOf(address(this)) >= assets, "Insufficient vault balance");

        // Burn shares proportional to fraction of remaining entitlement being claimed
        uint256 sharesToBurn = rs.remainingLockedShares.mulDiv(assets, remainingEntitlement);
        if (sharesToBurn > rs.remainingLockedShares) sharesToBurn = rs.remainingLockedShares;
        if (sharesToBurn > shares) sharesToBurn = shares; // cap at requested

        _burn(address(this), sharesToBurn);
        rs.remainingLockedShares -= sharesToBurn;
        rs.assetsClaimed += assets;

        require(usdc.transfer(receiver, assets), "USDC transfer failed");
        emit Withdraw(controller, receiver, controller, assets, sharesToBurn);

        _checkVaultCompletion();
    }

    // ─────────────────────────────────────────────────────────────
    // ERC-7540: Operator Management
    // ─────────────────────────────────────────────────────────────

    /// @notice Grant or revoke operator permission
    function setOperator(address operator, bool approved) external returns (bool) {
        require(operator != address(0), "Invalid operator");
        isOperator[msg.sender][operator] = approved;
        emit OperatorSet(msg.sender, operator, approved);
        return true;
    }

    // ─────────────────────────────────────────────────────────────
    // Vault Lifecycle
    // ─────────────────────────────────────────────────────────────

    /// @notice Attach signed contract hash to vault (VAULT_MANAGER_ROLE)
    function attachContract(bytes32 _contractHash) external onlyRole(VAULT_MANAGER_ROLE) {
        require(vaultInfo.state == VaultState.Funded, "Vault not funded");
        require(vaultInfo.contractHash == bytes32(0), "Contract already attached");
        require(_contractHash != bytes32(0), "Invalid contract hash");

        vaultInfo.contractHash = _contractHash;
        vaultInfo.contractAttachedAt = block.timestamp;
        vaultInfo.state = VaultState.Active;
        emit ContractAttached(vaultInfo.vaultId, _contractHash);
        emit VaultStateChanged(VaultState.Active);
    }

    /// @notice Borrower withdraws principal after contract is fully signed
    function withdrawFunds() external nonReentrant {
        require(msg.sender == vaultInfo.borrower, "Only borrower");
        require(vaultInfo.state == VaultState.Active, "Vault not active");
        require(vaultInfo.contractHash != bytes32(0), "No contract attached");
        require(vaultInfo.totalRaised == vaultInfo.principalAmount, "Not fully funded");

        IContractSigner.ContractDocument memory doc = IContractSigner(contractSigner).getContract(
            vaultInfo.contractHash
        );
        require(doc.isExecuted, "Contract not fully signed");
        require(!doc.isCancelled, "Contract cancelled");

        require(usdc.transfer(vaultInfo.borrower, vaultInfo.principalAmount), "USDC transfer failed");
        vaultInfo.state = VaultState.Repaying;
        vaultInfo.fundsWithdrawnAt = block.timestamp;
        emit FundsWithdrawn(vaultInfo.borrower, vaultInfo.principalAmount);
        emit VaultStateChanged(VaultState.Repaying);
    }

    /// @notice Borrower repays principal + interest + fee in one or more installments
    function makeRepayment(uint256 amount) external nonReentrant {
        require(vaultInfo.state == VaultState.Repaying, "Not in repaying state");
        require(amount > 0, "Zero amount");
        require(usdc.transferFrom(msg.sender, address(this), amount), "USDC transfer failed");

        vaultInfo.totalRepaid += amount;
        emit RepaymentMade(msg.sender, amount, vaultInfo.totalRepaid);
    }

    /// @notice Mark vault as defaulted after maturity (VAULT_MANAGER_ROLE)
    function markAsDefaulted() external onlyRole(VAULT_MANAGER_ROLE) {
        require(vaultInfo.state == VaultState.Repaying, "Not in repaying state");
        require(block.timestamp > vaultInfo.maturityDate, "Not yet matured");

        vaultInfo.state = VaultState.Defaulted;
        emit VaultStateChanged(VaultState.Defaulted);
    }

    // ─────────────────────────────────────────────────────────────
    // Protocol Fees
    // ─────────────────────────────────────────────────────────────

    /// @notice Claim earned protocol fees proportional to repayments received
    function withdrawProtocolFees() external nonReentrant {
        require(msg.sender == protocolFeeCollector, "Only protocol fee collector");
        require(
            vaultInfo.state == VaultState.Repaying || vaultInfo.state == VaultState.Completed,
            "No repayments yet"
        );

        uint256 totalDue = _getTotalDue();
        uint256 totalProtocolFee = vaultInfo.principalAmount.mulDiv(vaultInfo.protocolFeeRate, 10000);

        uint256 earnedFee = vaultInfo.totalRepaid >= totalDue
            ? totalProtocolFee
            : vaultInfo.totalRepaid.mulDiv(totalProtocolFee, totalDue);

        uint256 available = earnedFee > protocolFeesWithdrawn
            ? earnedFee - protocolFeesWithdrawn
            : 0;
        require(available > 0, "No fees to collect");

        protocolFeesWithdrawn += available;
        require(usdc.transfer(protocolFeeCollector, available), "USDC transfer failed");
        emit ProtocolFeesCollected(available);

        _checkVaultCompletion();
    }

    // ─────────────────────────────────────────────────────────────
    // Admin
    // ─────────────────────────────────────────────────────────────

    /// @notice Update minimum investment (VAULT_MANAGER_ROLE)
    function setMinInvestment(uint256 newMin) external onlyRole(VAULT_MANAGER_ROLE) {
        require(newMin > 0, "Must be > 0");
        emit MinInvestmentUpdated(minInvestment, newMin);
        minInvestment = newMin;
    }

    // ─────────────────────────────────────────────────────────────
    // Internal Helpers
    // ─────────────────────────────────────────────────────────────

    /// @notice Total borrower obligation: principal + interest + protocolFee
    function _getTotalDue() internal view returns (uint256) {
        uint256 interest = vaultInfo.principalAmount.mulDiv(vaultInfo.interestRate, 10000);
        uint256 fee = vaultInfo.principalAmount.mulDiv(vaultInfo.protocolFeeRate, 10000);
        return vaultInfo.principalAmount + interest + fee;
    }

    /// @notice Net USDC for investors: principal + interest - protocolFee
    function _getNetForInvestors() internal view returns (uint256) {
        uint256 interest = vaultInfo.principalAmount.mulDiv(vaultInfo.interestRate, 10000);
        uint256 fee = vaultInfo.principalAmount.mulDiv(vaultInfo.protocolFeeRate, 10000);
        return vaultInfo.principalAmount + interest - fee;
    }

    /// @notice Protocol fees earned but not yet withdrawn (reserved from vault balance)
    function _calculateReservedProtocolFees() internal view returns (uint256) {
        uint256 totalDue = _getTotalDue();
        uint256 totalProtocolFee = vaultInfo.principalAmount.mulDiv(vaultInfo.protocolFeeRate, 10000);

        uint256 earnedFee = vaultInfo.totalRepaid >= totalDue
            ? totalProtocolFee
            : vaultInfo.totalRepaid.mulDiv(totalProtocolFee, totalDue);

        return earnedFee > protocolFeesWithdrawn ? earnedFee - protocolFeesWithdrawn : 0;
    }

    /// @notice Mark vault Completed when all debt repaid and all funds distributed
    function _checkVaultCompletion() internal {
        if (vaultInfo.state != VaultState.Repaying) return;

        bool debtFullyRepaid = vaultInfo.totalRepaid >= _getTotalDue();
        bool allDistributed = usdc.balanceOf(address(this)) < 100; // < 0.0001 USDC dust

        if (debtFullyRepaid && allDistributed) {
            vaultInfo.state = VaultState.Completed;
            emit VaultStateChanged(VaultState.Completed);
        }
    }

    // ─────────────────────────────────────────────────────────────
    // Public View Functions
    // ─────────────────────────────────────────────────────────────

    /// @notice USDC available for investor redemptions (vault balance minus reserved protocol fees)
    function getAvailableForInvestors() public view returns (uint256) {
        uint256 bal = usdc.balanceOf(address(this));
        uint256 reserved = _calculateReservedProtocolFees();
        return bal > reserved ? bal - reserved : 0;
    }

    /// @notice Repayment overview for borrower dashboard
    /// @return totalDue   Principal + interest + protocol fee
    /// @return totalPaid  Amount repaid so far
    /// @return remaining  Amount still owed
    /// @return protocolFee Total protocol fee (not net)
    function getRepaymentStatus()
        external
        view
        returns (uint256 totalDue, uint256 totalPaid, uint256 remaining, uint256 protocolFee)
    {
        protocolFee = vaultInfo.principalAmount.mulDiv(vaultInfo.protocolFeeRate, 10000);
        uint256 interest = vaultInfo.principalAmount.mulDiv(vaultInfo.interestRate, 10000);
        totalDue = vaultInfo.principalAmount + interest + protocolFee;
        totalPaid = vaultInfo.totalRepaid;
        remaining = totalDue > totalPaid ? totalDue - totalPaid : 0;
    }

    /// @notice Vault metrics for frontend dashboard
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
        )
    {
        totalShares = totalSupply();
        sharePrice = getCurrentSharePrice();
        totalValueLocked = usdc.balanceOf(address(this));
        targetAmount = vaultInfo.principalAmount;
        fundingProgress = targetAmount > 0
            ? vaultInfo.totalRaised.mulDiv(10000, targetAmount)
            : 0;
        uint256 netForInvestors = _getNetForInvestors();
        expectedFinalSharePrice = netForInvestors.mulDiv(1e18, originalTotalShares);
    }

    /// @notice Investor return summary
    /// @return invested          USDC value of all shares (held + locked + claimed-from)
    /// @return currentValue      USDC claimable now + claimed already + current value of held shares
    /// @return profit            currentValue - invested (0 if negative)
    /// @return expectedAtMaturity USDC expected when fully repaid (for unlocked + locked shares)
    function getInvestorReturn(address investor)
        external
        view
        returns (
            uint256 invested,
            uint256 currentValue,
            uint256 profit,
            uint256 expectedAtMaturity
        )
    {
        uint256 held = balanceOf(investor);
        RedeemState memory rs = _redeemRequests[investor];

        uint256 totalShares = held + rs.originalLockedShares;
        invested = totalShares.mulDiv(vaultInfo.principalAmount, originalTotalShares);

        // Claimed already
        uint256 claimed = rs.assetsClaimed;

        // Claimable now from locked shares
        uint256 claimable = 0;
        if (rs.originalLockedShares > 0) {
            uint256 totalDue = _getTotalDue();
            uint256 repaidFraction = totalDue > 0
                ? Math.min(1e18, vaultInfo.totalRepaid.mulDiv(1e18, totalDue))
                : 0;
            uint256 netLocked = _getNetForInvestors();
            uint256 totalEntitlement = rs.originalLockedShares.mulDiv(netLocked, originalTotalShares);
            uint256 totalClaimableNow = totalEntitlement.mulDiv(repaidFraction, 1e18);
            claimable = totalClaimableNow > rs.assetsClaimed ? totalClaimableNow - rs.assetsClaimed : 0;
        }

        // Value of currently held (not locked) shares
        uint256 heldValue = held > 0 ? convertToAssets(held) : 0;

        currentValue = claimed + claimable + heldValue;
        profit = currentValue > invested ? currentValue - invested : 0;

        // Expected at maturity for shares not yet redeemed
        uint256 netForInvestors = _getNetForInvestors();
        uint256 unredeemed = held + rs.remainingLockedShares;
        expectedAtMaturity = unredeemed.mulDiv(netForInvestors, originalTotalShares);
    }

    /// @notice Redemption state for a controller (for frontend)
    function getRedeemState(address controller)
        external
        view
        returns (
            uint256 originalLockedShares,
            uint256 remainingLockedShares,
            uint256 assetsClaimed,
            uint256 claimableNow
        )
    {
        RedeemState memory rs = _redeemRequests[controller];
        originalLockedShares = rs.originalLockedShares;
        remainingLockedShares = rs.remainingLockedShares;
        assetsClaimed = rs.assetsClaimed;
        claimableNow = claimableRedeemRequest(0, controller) > 0
            ? _computeClaimableAssets(controller)
            : 0;
    }

    /// @notice Actual due date: fundsWithdrawnAt + loan duration
    function getActualDueDate() external view returns (uint256) {
        if (vaultInfo.fundsWithdrawnAt == 0) return 0;
        return vaultInfo.fundsWithdrawnAt + (vaultInfo.maturityDate - vaultInfo.createdAt);
    }

    function getVaultState() external view returns (VaultState) { return vaultInfo.state; }
    function getVaultBalance() external view returns (uint256) { return usdc.balanceOf(address(this)); }
    function getVaultBorrower() external view returns (address) { return vaultInfo.borrower; }
    function getVaultPrincipalAmount() external view returns (uint256) { return vaultInfo.principalAmount; }
    function getVaultTotalRaised() external view returns (uint256) { return vaultInfo.totalRaised; }
    function getVaultTotalRepaid() external view returns (uint256) { return vaultInfo.totalRepaid; }
    function getVaultContractHash() external view returns (bytes32) { return vaultInfo.contractHash; }
    function getVaultFundedAt() external view returns (uint256) { return vaultInfo.fundedAt; }
    function getVaultFundsWithdrawnAt() external view returns (uint256) { return vaultInfo.fundsWithdrawnAt; }
    function getInvestors() external view returns (address[] memory) { return _investors; }
    function isInvestorAddress(address account) external view returns (bool) { return _isInvestor[account]; }

    // ─────────────────────────────────────────────────────────────
    // Internal View Helper
    // ─────────────────────────────────────────────────────────────

    function _computeClaimableAssets(address controller) internal view returns (uint256) {
        RedeemState memory rs = _redeemRequests[controller];
        if (rs.remainingLockedShares == 0) return 0;

        uint256 totalDue = _getTotalDue();
        if (totalDue == 0) return 0;

        uint256 repaidFraction = Math.min(1e18, vaultInfo.totalRepaid.mulDiv(1e18, totalDue));
        uint256 netForInvestors = _getNetForInvestors();
        uint256 totalEntitlement = rs.originalLockedShares.mulDiv(netForInvestors, originalTotalShares);
        uint256 totalClaimableNow = totalEntitlement.mulDiv(repaidFraction, 1e18);

        return totalClaimableNow > rs.assetsClaimed ? totalClaimableNow - rs.assetsClaimed : 0;
    }

    // ─────────────────────────────────────────────────────────────
    // ERC-165
    // ─────────────────────────────────────────────────────────────

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl)
        returns (bool)
    {
        return
            interfaceId == 0xe3bc4e65 || // ERC-7540 operator methods
            interfaceId == 0x620ee8e4 || // ERC-7540 async redeem
            super.supportsInterface(interfaceId);
    }
}

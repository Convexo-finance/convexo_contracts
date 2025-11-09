// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReputationManager} from "./ReputationManager.sol";
import {PriceFeedManager} from "./PriceFeedManager.sol";

/// @title TokenizedBondCredits
/// @notice Manages tokenized bond credits: SME signs → Credit approved → Loan disbursed → Daily cash flow factored
/// @dev Handles credit approval, loan disbursement, and cash flow factoring for SMEs
contract TokenizedBondCredits is AccessControl {
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
    bytes32 public constant CREDIT_APPROVER_ROLE = keccak256("CREDIT_APPROVER_ROLE");

    /// @notice Credit status enum
    enum CreditStatus {
        Pending,
        Approved,
        Disbursed,
        Repaying,
        Completed,
        Defaulted
    }

    /// @notice Credit information
    struct Credit {
        uint256 creditId;
        address borrower;
        uint256 creditScore;
        uint256 principalAmount; // In USDC (6 decimals)
        uint256 interestRate; // Basis points (e.g., 1000 = 10%)
        uint256 loanDuration; // In days
        uint256 maturityDate;
        bytes32 contractHash; // Link to signed contract
        CreditStatus status;
        uint256 disbursedAmount;
        uint256 repaidAmount;
        uint256 vaultId; // Linked vault ID
        uint256 createdAt;
        uint256 approvedAt;
        uint256 disbursedAt;
        PriceFeedManager.CurrencyPair currencyPair; // Currency for disbursement
    }

    /// @notice Cash flow tracking
    struct CashFlowEntry {
        uint256 creditId;
        uint256 amount;
        uint256 timestamp;
        string description;
    }

    /// @notice Counter for credit IDs
    uint256 private _nextCreditId;

    /// @notice Reputation manager contract
    ReputationManager public immutable reputationManager;

    /// @notice Price feed manager contract
    PriceFeedManager public immutable priceFeedManager;

    /// @notice Mapping from credit ID to credit
    mapping(uint256 => Credit) public credits;

    /// @notice Mapping from credit ID to cash flow entries
    mapping(uint256 => CashFlowEntry[]) public cashFlowEntries;

    /// @notice Array of all credit IDs
    uint256[] public creditIds;

    /// @notice Mapping from contract hash to credit ID
    mapping(bytes32 => uint256) public contractHashToCreditId;

    /// @notice Emitted when a credit is created
    event CreditCreated(
        uint256 indexed creditId,
        address indexed borrower,
        uint256 creditScore,
        uint256 principalAmount,
        bytes32 contractHash
    );

    /// @notice Emitted when a credit is approved
    event CreditApproved(uint256 indexed creditId, uint256 approvedAt);

    /// @notice Emitted when a loan is disbursed
    event LoanDisbursed(
        uint256 indexed creditId, uint256 disbursedAmount, uint256 vaultId, PriceFeedManager.CurrencyPair currencyPair
    );

    /// @notice Emitted when a cash flow entry is recorded
    event CashFlowRecorded(uint256 indexed creditId, uint256 amount, string description);

    /// @notice Emitted when a repayment is made
    event RepaymentMade(uint256 indexed creditId, uint256 amount, uint256 totalRepaid);

    /// @notice Emitted when a credit is completed
    event CreditCompleted(uint256 indexed creditId);

    /// @notice Emitted when a credit is defaulted
    event CreditDefaulted(uint256 indexed creditId);

    constructor(address admin, ReputationManager _reputationManager, PriceFeedManager _priceFeedManager) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(VERIFIER_ROLE, admin);
        _grantRole(CREDIT_APPROVER_ROLE, admin);
        reputationManager = _reputationManager;
        priceFeedManager = _priceFeedManager;
    }

    /// @notice Create a new credit request after contract signing
    /// @param borrower The address of the SME borrowing
    /// @param creditScore The credit score of the borrower (0-100)
    /// @param principalAmount The principal amount in USDC (6 decimals)
    /// @param interestRate The interest rate in basis points (e.g., 1000 = 10%)
    /// @param loanDuration The loan duration in days
    /// @param contractHash The hash of the signed contract
    /// @param currencyPair The currency pair for disbursement
    /// @return creditId The ID of the created credit
    function createCredit(
        address borrower,
        uint256 creditScore,
        uint256 principalAmount,
        uint256 interestRate,
        uint256 loanDuration,
        bytes32 contractHash,
        PriceFeedManager.CurrencyPair currencyPair
    ) external onlyRole(VERIFIER_ROLE) returns (uint256 creditId) {
        require(creditScore > 70, "Credit score must be above 70");
        require(principalAmount > 0, "Principal amount must be greater than 0");
        require(loanDuration > 0, "Loan duration must be greater than 0");
        require(contractHashToCreditId[contractHash] == 0, "Contract hash already used");

        // Check reputation (must have Creditscore tier for bond credits)
        require(
            reputationManager.getReputationTierNumeric(borrower) >= 2,
            "Borrower must have Creditscore reputation tier"
        );

        creditId = _nextCreditId++;

        uint256 maturityDate = block.timestamp + (loanDuration * 1 days);

        credits[creditId] = Credit({
            creditId: creditId,
            borrower: borrower,
            creditScore: creditScore,
            principalAmount: principalAmount,
            interestRate: interestRate,
            loanDuration: loanDuration,
            maturityDate: maturityDate,
            contractHash: contractHash,
            status: CreditStatus.Pending,
            disbursedAmount: 0,
            repaidAmount: 0,
            vaultId: 0,
            createdAt: block.timestamp,
            approvedAt: 0,
            disbursedAt: 0,
            currencyPair: currencyPair
        });

        creditIds.push(creditId);
        contractHashToCreditId[contractHash] = creditId;

        emit CreditCreated(creditId, borrower, creditScore, principalAmount, contractHash);

        return creditId;
    }

    /// @notice Approve a credit
    /// @param creditId The ID of the credit to approve
    function approveCredit(uint256 creditId) external onlyRole(CREDIT_APPROVER_ROLE) {
        require(creditId < _nextCreditId, "Credit does not exist");
        Credit storage credit = credits[creditId];
        require(credit.status == CreditStatus.Pending, "Credit is not pending");

        credit.status = CreditStatus.Approved;
        credit.approvedAt = block.timestamp;

        emit CreditApproved(creditId, block.timestamp);
    }

    /// @notice Disburse a loan after vault creation
    /// @param creditId The ID of the credit to disburse
    /// @param vaultId The ID of the created vault
    function disburseLoan(uint256 creditId, uint256 vaultId) external onlyRole(VERIFIER_ROLE) {
        require(creditId < _nextCreditId, "Credit does not exist");
        Credit storage credit = credits[creditId];
        require(credit.status == CreditStatus.Approved, "Credit is not approved");

        // Convert USDC to local currency using price feed
        uint256 localAmount = priceFeedManager.convertUSDCToLocal(credit.currencyPair, credit.principalAmount);

        credit.status = CreditStatus.Disbursed;
        credit.disbursedAmount = localAmount;
        credit.vaultId = vaultId;
        credit.disbursedAt = block.timestamp;

        // Move to repaying status
        credit.status = CreditStatus.Repaying;

        emit LoanDisbursed(creditId, localAmount, vaultId, credit.currencyPair);
    }

    /// @notice Record daily cash flow
    /// @param creditId The ID of the credit
    /// @param amount The cash flow amount
    /// @param description Description of the cash flow
    function recordCashFlow(uint256 creditId, uint256 amount, string memory description)
        external
        onlyRole(VERIFIER_ROLE)
    {
        require(creditId < _nextCreditId, "Credit does not exist");
        Credit storage credit = credits[creditId];
        require(credit.status == CreditStatus.Repaying, "Credit is not in repaying status");

        cashFlowEntries[creditId].push(
            CashFlowEntry({creditId: creditId, amount: amount, timestamp: block.timestamp, description: description})
        );

        emit CashFlowRecorded(creditId, amount, description);
    }

    /// @notice Make a repayment
    /// @param creditId The ID of the credit
    /// @param amount The repayment amount in USDC
    function makeRepayment(uint256 creditId, uint256 amount) external onlyRole(VERIFIER_ROLE) {
        require(creditId < _nextCreditId, "Credit does not exist");
        Credit storage credit = credits[creditId];
        require(credit.status == CreditStatus.Repaying, "Credit is not in repaying status");

        credit.repaidAmount += amount;

        emit RepaymentMade(creditId, amount, credit.repaidAmount);

        // Calculate total amount due (principal + interest)
        uint256 totalDue = credit.principalAmount + (credit.principalAmount * credit.interestRate / 10000);

        // Check if fully repaid
        if (credit.repaidAmount >= totalDue) {
            credit.status = CreditStatus.Completed;
            emit CreditCompleted(creditId);
        }
    }

    /// @notice Mark a credit as defaulted
    /// @param creditId The ID of the credit
    function markAsDefaulted(uint256 creditId) external onlyRole(CREDIT_APPROVER_ROLE) {
        require(creditId < _nextCreditId, "Credit does not exist");
        Credit storage credit = credits[creditId];
        require(credit.status == CreditStatus.Repaying, "Credit is not in repaying status");
        require(block.timestamp > credit.maturityDate, "Credit has not matured yet");

        credit.status = CreditStatus.Defaulted;

        emit CreditDefaulted(creditId);
    }

    /// @notice Get credit information
    /// @param creditId The ID of the credit
    /// @return Credit struct
    function getCredit(uint256 creditId) external view returns (Credit memory) {
        require(creditId < _nextCreditId, "Credit does not exist");
        return credits[creditId];
    }

    /// @notice Get credit by contract hash
    /// @param contractHash The contract hash
    /// @return Credit struct
    function getCreditByContractHash(bytes32 contractHash) external view returns (Credit memory) {
        uint256 creditId = contractHashToCreditId[contractHash];
        require(creditId != 0 || contractHashToCreditId[contractHash] == 0, "Credit not found");
        return credits[creditId];
    }

    /// @notice Get cash flow entries for a credit
    /// @param creditId The ID of the credit
    /// @return Array of cash flow entries
    function getCashFlowEntries(uint256 creditId) external view returns (CashFlowEntry[] memory) {
        require(creditId < _nextCreditId, "Credit does not exist");
        return cashFlowEntries[creditId];
    }

    /// @notice Get total number of credits
    /// @return The number of credits
    function getCreditCount() external view returns (uint256) {
        return _nextCreditId;
    }
}


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ReputationManager} from "./ReputationManager.sol";

/// @title InvoiceFactoring
/// @notice Manages invoice factoring: SME signs → Invoice tokenized → Sold to investors via vault
/// @dev Creates ERC20 tokens representing invoices that can be sold to investors
contract InvoiceFactoring is AccessControl {
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");

    /// @notice Invoice information
    struct Invoice {
        uint256 invoiceId;
        address issuer;
        uint256 faceValue;
        uint256 maturityDate;
        bytes32 contractHash; // Link to signed contract
        address tokenAddress; // Address of the tokenized invoice ERC20
        bool isActive;
        bool isPaidOut;
        uint256 createdAt;
    }

    /// @notice Counter for invoice IDs
    uint256 private _nextInvoiceId;

    /// @notice Reputation manager contract
    ReputationManager public immutable reputationManager;

    /// @notice Mapping from invoice ID to invoice
    mapping(uint256 => Invoice) public invoices;

    /// @notice Array of all invoice IDs
    uint256[] public invoiceIds;

    /// @notice Mapping from contract hash to invoice ID
    mapping(bytes32 => uint256) public contractHashToInvoiceId;

    /// @notice Emitted when an invoice is created
    event InvoiceCreated(
        uint256 indexed invoiceId,
        address indexed issuer,
        uint256 faceValue,
        uint256 maturityDate,
        bytes32 contractHash,
        address tokenAddress
    );

    /// @notice Emitted when an invoice is paid out
    event InvoicePaidOut(uint256 indexed invoiceId, address indexed issuer);

    /// @notice Emitted when an invoice is deactivated
    event InvoiceDeactivated(uint256 indexed invoiceId);

    constructor(address admin, ReputationManager _reputationManager) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(VERIFIER_ROLE, admin);
        reputationManager = _reputationManager;
    }

    /// @notice Create a new invoice after contract signing
    /// @param issuer The address of the SME issuing the invoice
    /// @param faceValue The face value of the invoice in USDC (6 decimals)
    /// @param maturityDate The timestamp when the invoice matures
    /// @param contractHash The hash of the signed contract
    /// @return invoiceId The ID of the created invoice
    function createInvoice(address issuer, uint256 faceValue, uint256 maturityDate, bytes32 contractHash)
        external
        onlyRole(VERIFIER_ROLE)
        returns (uint256 invoiceId)
    {
        require(faceValue > 0, "Face value must be greater than 0");
        require(maturityDate > block.timestamp, "Maturity date must be in the future");
        require(contractHashToInvoiceId[contractHash] == 0, "Contract hash already used");

        // Check reputation (must have at least Compliant tier)
        require(
            reputationManager.getReputationTierNumeric(issuer) >= 1,
            "Issuer must have at least Compliant reputation tier"
        );

        invoiceId = _nextInvoiceId++;

        // Create invoice token (simplified - in production, deploy actual ERC20)
        address tokenAddress = address(0); // Placeholder - would deploy InvoiceToken contract here

        invoices[invoiceId] = Invoice({
            invoiceId: invoiceId,
            issuer: issuer,
            faceValue: faceValue,
            maturityDate: maturityDate,
            contractHash: contractHash,
            tokenAddress: tokenAddress,
            isActive: true,
            isPaidOut: false,
            createdAt: block.timestamp
        });

        invoiceIds.push(invoiceId);
        contractHashToInvoiceId[contractHash] = invoiceId;

        emit InvoiceCreated(invoiceId, issuer, faceValue, maturityDate, contractHash, tokenAddress);

        return invoiceId;
    }

    /// @notice Mark an invoice as paid out
    /// @param invoiceId The ID of the invoice to pay out
    function payOutInvoice(uint256 invoiceId) external onlyRole(VERIFIER_ROLE) {
        require(invoiceId < _nextInvoiceId, "Invoice does not exist");
        Invoice storage invoice = invoices[invoiceId];
        require(invoice.isActive, "Invoice is not active");
        require(!invoice.isPaidOut, "Invoice already paid out");

        invoice.isPaidOut = true;
        invoice.isActive = false;

        emit InvoicePaidOut(invoiceId, invoice.issuer);
    }

    /// @notice Deactivate an invoice
    /// @param invoiceId The ID of the invoice to deactivate
    function deactivateInvoice(uint256 invoiceId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(invoiceId < _nextInvoiceId, "Invoice does not exist");
        invoices[invoiceId].isActive = false;

        emit InvoiceDeactivated(invoiceId);
    }

    /// @notice Get invoice information
    /// @param invoiceId The ID of the invoice
    /// @return Invoice struct
    function getInvoice(uint256 invoiceId) external view returns (Invoice memory) {
        require(invoiceId < _nextInvoiceId, "Invoice does not exist");
        return invoices[invoiceId];
    }

    /// @notice Get invoice by contract hash
    /// @param contractHash The contract hash
    /// @return Invoice struct
    function getInvoiceByContractHash(bytes32 contractHash) external view returns (Invoice memory) {
        uint256 invoiceId = contractHashToInvoiceId[contractHash];
        require(invoiceId != 0 || contractHashToInvoiceId[contractHash] == 0, "Invoice not found");
        return invoices[invoiceId];
    }

    /// @notice Get total number of invoices
    /// @return The number of invoices
    function getInvoiceCount() external view returns (uint256) {
        return _nextInvoiceId;
    }

    /// @notice Get invoice ID at a specific index
    /// @param index The index to query
    /// @return The invoice ID at that index
    function getInvoiceIdAtIndex(uint256 index) external view returns (uint256) {
        require(index < invoiceIds.length, "Index out of bounds");
        return invoiceIds[index];
    }

    /// @notice Check if an invoice is active and not paid out
    /// @param invoiceId The ID of the invoice
    /// @return True if active and not paid out
    function isInvoiceActiveAndUnpaid(uint256 invoiceId) external view returns (bool) {
        require(invoiceId < _nextInvoiceId, "Invoice does not exist");
        Invoice memory invoice = invoices[invoiceId];
        return invoice.isActive && !invoice.isPaidOut;
    }
}

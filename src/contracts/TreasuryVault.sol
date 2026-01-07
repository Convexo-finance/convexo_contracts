// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title TreasuryVault
/// @notice Personal USDC treasury with multi-signature withdrawal support
/// @dev Allows Tier 1+ users to manage personal reserves with optional multi-sig for withdrawals
contract TreasuryVault is ReentrancyGuard {
    /// @notice Treasury owner address
    address public immutable owner;

    /// @notice USDC token address
    IERC20 public immutable usdc;

    /// @notice Number of signatures required for withdrawal
    uint256 public signaturesRequired;

    /// @notice Mapping of authorized signers
    mapping(address => bool) public isAuthorizedSigner;

    /// @notice Array of authorized signers
    address[] public signers;

    /// @notice Withdrawal proposal counter
    uint256 private _nextWithdrawalId;

    /// @notice Withdrawal proposal struct
    struct WithdrawalProposal {
        uint256 id;
        address to;
        uint256 amount;
        uint256 proposedAt;
        bool executed;
        mapping(address => bool) signatures;
        uint256 signatureCount;
    }

    /// @notice Mapping from withdrawal ID to proposal
    mapping(uint256 => WithdrawalProposal) public withdrawalProposals;

    /// @notice Emitted when USDC is deposited
    event Deposited(address indexed from, uint256 amount, uint256 newBalance);

    /// @notice Emitted when a withdrawal is proposed
    event WithdrawalProposed(
        uint256 indexed withdrawalId,
        address indexed proposer,
        address indexed to,
        uint256 amount
    );

    /// @notice Emitted when a signer signs a withdrawal
    event WithdrawalSigned(
        uint256 indexed withdrawalId,
        address indexed signer,
        uint256 signatureCount,
        uint256 signaturesRequired
    );

    /// @notice Emitted when a withdrawal is executed
    event WithdrawalExecuted(
        uint256 indexed withdrawalId,
        address indexed to,
        uint256 amount
    );

    /// @notice Emitted when a signer is added
    event SignerAdded(address indexed signer, uint256 newSignerCount);

    /// @notice Emitted when a signer is removed
    event SignerRemoved(address indexed signer, uint256 newSignerCount);

    /// @notice Emitted when signature requirement is updated
    event SignaturesRequiredUpdated(uint256 oldRequired, uint256 newRequired);

    constructor(
        address _owner,
        address _usdc,
        address[] memory _signers,
        uint256 _signaturesRequired
    ) {
        require(_owner != address(0), "Invalid owner address");
        require(_usdc != address(0), "Invalid USDC address");
        require(_signaturesRequired > 0, "Invalid signature requirement");

        owner = _owner;
        usdc = IERC20(_usdc);

        // Initialize signers
        if (_signers.length > 0) {
            require(_signaturesRequired <= _signers.length, "Signatures required exceeds signer count");
            for (uint256 i = 0; i < _signers.length; i++) {
                require(_signers[i] != address(0), "Invalid signer address");
                require(!isAuthorizedSigner[_signers[i]], "Duplicate signer");
                isAuthorizedSigner[_signers[i]] = true;
                signers.push(_signers[i]);
            }
        } else {
            // Single-sig mode: owner is the only signer
            require(_signaturesRequired == 1, "Single-sig requires 1 signature");
            isAuthorizedSigner[_owner] = true;
            signers.push(_owner);
        }

        signaturesRequired = _signaturesRequired;
    }

    /// @notice Deposit USDC into the treasury
    /// @param amount The amount of USDC to deposit
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");

        usdc.transferFrom(msg.sender, address(this), amount);

        emit Deposited(msg.sender, amount, usdc.balanceOf(address(this)));
    }

    /// @notice Propose a withdrawal (only authorized signers)
    /// @param to The recipient address
    /// @param amount The amount to withdraw
    /// @return withdrawalId The ID of the created withdrawal proposal
    function proposeWithdrawal(address to, uint256 amount)
        external
        returns (uint256 withdrawalId)
    {
        require(isAuthorizedSigner[msg.sender], "Not an authorized signer");
        require(to != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be greater than 0");
        require(amount <= usdc.balanceOf(address(this)), "Insufficient balance");

        withdrawalId = _nextWithdrawalId++;

        WithdrawalProposal storage proposal = withdrawalProposals[withdrawalId];
        proposal.id = withdrawalId;
        proposal.to = to;
        proposal.amount = amount;
        proposal.proposedAt = block.timestamp;
        proposal.executed = false;
        proposal.signatureCount = 0;

        emit WithdrawalProposed(withdrawalId, msg.sender, to, amount);

        // Automatically sign if proposer is a signer
        signWithdrawal(withdrawalId);

        return withdrawalId;
    }

    /// @notice Sign a withdrawal proposal
    /// @param withdrawalId The ID of the withdrawal to sign
    function signWithdrawal(uint256 withdrawalId) public {
        require(isAuthorizedSigner[msg.sender], "Not an authorized signer");

        WithdrawalProposal storage proposal = withdrawalProposals[withdrawalId];
        require(proposal.id == withdrawalId, "Withdrawal does not exist");
        require(!proposal.executed, "Withdrawal already executed");
        require(!proposal.signatures[msg.sender], "Already signed");

        proposal.signatures[msg.sender] = true;
        proposal.signatureCount++;

        emit WithdrawalSigned(
            withdrawalId,
            msg.sender,
            proposal.signatureCount,
            signaturesRequired
        );

        // Automatically execute if enough signatures
        if (proposal.signatureCount >= signaturesRequired) {
            _executeWithdrawal(withdrawalId);
        }
    }

    /// @notice Internal function to execute a withdrawal
    /// @param withdrawalId The ID of the withdrawal to execute
    function _executeWithdrawal(uint256 withdrawalId) private nonReentrant {
        WithdrawalProposal storage proposal = withdrawalProposals[withdrawalId];
        require(!proposal.executed, "Withdrawal already executed");
        require(proposal.signatureCount >= signaturesRequired, "Insufficient signatures");

        proposal.executed = true;

        usdc.transfer(proposal.to, proposal.amount);

        emit WithdrawalExecuted(withdrawalId, proposal.to, proposal.amount);
    }

    /// @notice Add an authorized signer (only owner)
    /// @param signer The address to add as signer
    function addSigner(address signer) external {
        require(msg.sender == owner, "Only owner can add signers");
        require(signer != address(0), "Invalid signer address");
        require(!isAuthorizedSigner[signer], "Already a signer");

        isAuthorizedSigner[signer] = true;
        signers.push(signer);

        emit SignerAdded(signer, signers.length);
    }

    /// @notice Remove an authorized signer (only owner)
    /// @param signer The address to remove
    function removeSigner(address signer) external {
        require(msg.sender == owner, "Only owner can remove signers");
        require(isAuthorizedSigner[signer], "Not a signer");
        require(signers.length > signaturesRequired, "Cannot remove signer: would fall below required signatures");

        isAuthorizedSigner[signer] = false;

        // Remove from signers array
        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] == signer) {
                signers[i] = signers[signers.length - 1];
                signers.pop();
                break;
            }
        }

        emit SignerRemoved(signer, signers.length);
    }

    /// @notice Update the number of signatures required (only owner)
    /// @param newRequired The new number of signatures required
    function updateSignaturesRequired(uint256 newRequired) external {
        require(msg.sender == owner, "Only owner can update");
        require(newRequired > 0, "Invalid signature requirement");
        require(newRequired <= signers.length, "Exceeds signer count");

        uint256 oldRequired = signaturesRequired;
        signaturesRequired = newRequired;

        emit SignaturesRequiredUpdated(oldRequired, newRequired);
    }

    /// @notice Get the current balance of the treasury
    /// @return The USDC balance
    function getBalance() external view returns (uint256) {
        return usdc.balanceOf(address(this));
    }

    /// @notice Get withdrawal proposal details
    /// @param withdrawalId The ID of the withdrawal
    /// @return to Recipient address
    /// @return amount Amount to withdraw
    /// @return proposedAt Timestamp when proposed
    /// @return executed Whether withdrawal was executed
    /// @return signatureCount Number of signatures
    function getWithdrawalProposal(uint256 withdrawalId)
        external
        view
        returns (
            address to,
            uint256 amount,
            uint256 proposedAt,
            bool executed,
            uint256 signatureCount
        )
    {
        WithdrawalProposal storage proposal = withdrawalProposals[withdrawalId];
        return (
            proposal.to,
            proposal.amount,
            proposal.proposedAt,
            proposal.executed,
            proposal.signatureCount
        );
    }

    /// @notice Check if an address has signed a withdrawal
    /// @param withdrawalId The withdrawal ID
    /// @param signer The signer address
    /// @return True if the signer has signed
    function hasSigned(uint256 withdrawalId, address signer) external view returns (bool) {
        return withdrawalProposals[withdrawalId].signatures[signer];
    }

    /// @notice Get the number of authorized signers
    /// @return The signer count
    function getSignerCount() external view returns (uint256) {
        return signers.length;
    }

    /// @notice Get all authorized signers
    /// @return Array of signer addresses
    function getSigners() external view returns (address[] memory) {
        return signers;
    }
}

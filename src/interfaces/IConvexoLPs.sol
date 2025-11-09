// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/// @notice Interface for the Convexo_LPs NFT contract
interface IConvexoLPs {
    /// @notice Returns the number of tokens owned by an address
    /// @param owner The address to query
    /// @return The number of tokens owned
    function balanceOf(address owner) external view returns (uint256);

    /// @notice Returns the owner of a token
    /// @param tokenId The token ID to query
    /// @return The address of the token owner
    function ownerOf(uint256 tokenId) external view returns (address);

    /// @notice Returns the state of a token (true = Active, false = NonActive)
    /// @param tokenId The token ID to query
    /// @return True if the token is active, false otherwise
    function getTokenState(uint256 tokenId) external view returns (bool);
}


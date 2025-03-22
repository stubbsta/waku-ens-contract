// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title WakuNameService
 * @dev Contract that maps domain names to public keys, with only the owner able to modify mappings
 * @notice Ownership can be transferred using the transferOwnership function inherited from OpenZeppelin's Ownable
 */
contract WakuNameService is Ownable {
    // Mapping from domain name (string) to public key (bytes)
    mapping(string => bytes) private _domainToPublicKey;
    
    // Array to keep track of all registered domain names
    string[] private _registeredDomains;
    
    // Mapping to check if a domain exists
    mapping(string => bool) private _domainExists;

    // Events
    event DomainRegistered(string indexed domainName, bytes publicKey);
    event DomainUpdated(string indexed domainName, bytes newPublicKey);
    event DomainRemoved(string indexed domainName);

    /**
     * @dev Constructor sets the original owner of the contract to the sender account
     */
    constructor() Ownable(msg.sender) {}

    /**
     * @dev Add a new domain name to public key mapping
     * @param domainName The domain name to register
     * @param publicKey The public key to associate with the domain
     * @return bool True if the operation was successful
     */
    function addDomain(string calldata domainName, bytes calldata publicKey) external onlyOwner returns (bool) {
        require(!_domainExists[domainName], "WakuNameService: Domain already exists");
        require(publicKey.length > 0, "WakuNameService: Public key cannot be empty");
        
        _domainToPublicKey[domainName] = publicKey;
        _registeredDomains.push(domainName);
        _domainExists[domainName] = true;
        
        emit DomainRegistered(domainName, publicKey);
        return true;
    }

    /**
     * @dev Update the public key for an existing domain
     * @param domainName The domain name to update
     * @param newPublicKey The new public key to associate with the domain
     * @return bool True if the operation was successful
     */
    function updateDomain(string calldata domainName, bytes calldata newPublicKey) external onlyOwner returns (bool) {
        require(_domainExists[domainName], "WakuNameService: Domain does not exist");
        require(newPublicKey.length > 0, "WakuNameService: Public key cannot be empty");
        
        _domainToPublicKey[domainName] = newPublicKey;
        
        emit DomainUpdated(domainName, newPublicKey);
        return true;
    }

    /**
     * @dev Remove a domain name mapping
     * @param domainName The domain name to remove
     * @return bool True if the operation was successful
     */
    function removeDomain(string calldata domainName) external onlyOwner returns (bool) {
        require(_domainExists[domainName], "WakuNameService: Domain does not exist");
        
        delete _domainToPublicKey[domainName];
        _domainExists[domainName] = false;
        
        // Remove from the registered domains array
        // Note: This creates a gap in the array but keeps gas costs lower than shifting elements
        // A more gas efficient approach would be needed for large scale operations
        
        emit DomainRemoved(domainName);
        return true;
    }

    /**
     * @dev Get the public key associated with a domain name
     * @param domainName The domain name to look up
     * @return bytes The public key associated with the domain name
     */
    function getPublicKey(string calldata domainName) external view returns (bytes memory) {
        require(_domainExists[domainName], "WakuNameService: Domain does not exist");
        return _domainToPublicKey[domainName];
    }

    /**
     * @dev Check if a domain exists
     * @param domainName The domain name to check
     * @return bool True if the domain exists
     */
    function domainExists(string calldata domainName) external view returns (bool) {
        return _domainExists[domainName];
    }

    /**
     * @dev Get all registered domains
     * @return array of all registered domain names
     * Note: This may include "removed" domains that still exist in the array but are marked as non-existent
     */
    function getAllDomains() external view returns (string[] memory) {
        return _registeredDomains;
    }
    
    /**
     * @dev Transfers ownership of the contract to a new account
     * @param newOwner The address to transfer ownership to
     * @notice This function is already available from OpenZeppelin's Ownable contract,
     * but is explicitly added here for clarity
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        require(newOwner != address(0), "WakuNameService: new owner is the zero address");
        _transferOwnership(newOwner);
        emit OwnershipTransferred(owner(), newOwner);
    }
}
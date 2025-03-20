// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title SimpleDNS
 * @dev A simplified version of a domain name service where the contract owner
 * can manage domain name to IP mappings, and users can query those mappings.
 */
contract SimpleDNS {
    address public owner;
    
    // Mapping from domain name (as bytes32) to IP address (as string)
    mapping(bytes32 => string) private domainToIP;
    
    // Events for logging
    event DomainRegistered(bytes32 indexed domain, string ip);
    event DomainUpdated(bytes32 indexed domain, string oldIP, string newIP);
    event DomainRemoved(bytes32 indexed domain);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    // Modifier to restrict certain functions to the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Converts a string domain name to bytes32 for storage
     * @param _domain The domain name as a string
     * @return The domain name as bytes32
     */
    function stringToBytes32(string memory _domain) public pure returns (bytes32) {
        require(bytes(_domain).length > 0, "Domain name cannot be empty");
        return keccak256(abi.encodePacked(_domain));
    }
    
    /**
     * @dev Allows the owner to register a new domain name with its IP address
     * @param _domain The domain name as a string
     * @param _ip The IP address as a string
     */
    function registerDomain(string memory _domain, string memory _ip) public onlyOwner {
        bytes32 domainHash = stringToBytes32(_domain);
        require(bytes(domainToIP[domainHash]).length == 0, "Domain already registered");
        domainToIP[domainHash] = _ip;
        emit DomainRegistered(domainHash, _ip);
    }
    
    /**
     * @dev Allows the owner to update the IP address for an existing domain
     * @param _domain The domain name as a string
     * @param _newIP The new IP address as a string
     */
    function updateDomain(string memory _domain, string memory _newIP) public onlyOwner {
        bytes32 domainHash = stringToBytes32(_domain);
        string memory oldIP = domainToIP[domainHash];
        require(bytes(oldIP).length > 0, "Domain not registered");
        
        domainToIP[domainHash] = _newIP;
        emit DomainUpdated(domainHash, oldIP, _newIP);
    }
    
    /**
     * @dev Allows the owner to remove a domain name from the registry
     * @param _domain The domain name as a string
     */
    function removeDomain(string memory _domain) public onlyOwner {
        bytes32 domainHash = stringToBytes32(_domain);
        require(bytes(domainToIP[domainHash]).length > 0, "Domain not registered");
        delete domainToIP[domainHash];
        emit DomainRemoved(domainHash);
    }
    
    /**
     * @dev Allows any user to query the IP address for a given domain name
     * @param _domain The domain name as a string
     * @return The IP address as a string
     */
    function getIP(string memory _domain) public view returns (string memory) {
        bytes32 domainHash = stringToBytes32(_domain);
        string memory ip = domainToIP[domainHash];
        require(bytes(ip).length > 0, "Domain not registered");
        return ip;
    }
    
    /**
     * @dev Check if a domain exists in the registry
     * @param _domain The domain name as a string
     * @return True if the domain exists, false otherwise
     */
    function domainExists(string memory _domain) public view returns (bool) {
        bytes32 domainHash = stringToBytes32(_domain);
        return bytes(domainToIP[domainHash]).length > 0;
    }
    
    /**
     * @dev Allows the owner to transfer ownership of the contract
     * @param _newOwner The address of the new owner
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner cannot be the zero address");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

// forge create --rpc-url 10.3.0.3:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 src/SimpleDNS.sol:SimpleDNS
// cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 "registerDomain(string,string)" "example1.com" "1.2.3.4" --rpc-url 10.3.0.3:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
// cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 "registerDomain(string,string)" "example2.com" "5.5.6.6" --rpc-url 10.3.0.3:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

// cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 "domainExists(string)(bool)" "example2.com" --rpc-url 10.3.0.3:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
// cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 "getIP(string)(string)" "example2.com" --rpc-url 10.3.0.3:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
// cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 "updateDomain(string,string) " "example2.com" "77.11.2.3" --rpc-url 10.3.0.3:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 
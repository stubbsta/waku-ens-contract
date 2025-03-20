// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/SimpleDNS.sol";

contract SimpleDNSTest is Test {
    SimpleDNS public simpleDNS;
    address public owner = address(1);
    address public user1 = address(2);
    address public user2 = address(3);

    // Setup function runs before each test
    function setUp() public {
        // Deploy the contract with owner as the deployer
        vm.prank(owner);
        simpleDNS = new SimpleDNS();
    }

    // ======== Deployment Tests ========
    function test__Deployment() view external {
        assertEq(simpleDNS.owner(), owner);
    }

    function testInitialState() public {
        vm.expectRevert("Domain not registered");
        simpleDNS.getIP("example.com");
    }

    // ======== Domain Registration Tests ========
    function test__RegisterDomain() public {
        vm.prank(owner);
        simpleDNS.registerDomain("example.com", "192.168.1.1");
        
        assertEq(simpleDNS.getIP("example.com"), "192.168.1.1");
    }

    function test__RegisterDomainEvent() public {
        bytes32 domainHash = simpleDNS.stringToBytes32("example.com");
        string memory ip = "192.168.1.1";
        
        vm.expectEmit(true, false, false, true);
        emit SimpleDNS.DomainRegistered(domainHash, ip);
        
        vm.prank(owner);
        simpleDNS.registerDomain("example.com", ip);
    }

    function test__NonOwnerRegister() public {
        vm.prank(user1);
        vm.expectRevert("Only the contract owner can call this function");
        simpleDNS.registerDomain("example.com", "192.168.1.1");
    }

    function test__RegisterTwice() public {
        vm.startPrank(owner);
        simpleDNS.registerDomain("example.com", "192.168.1.1");
        
        vm.expectRevert("Domain already registered");
        simpleDNS.registerDomain("example.com", "192.168.1.2");
        vm.stopPrank();
    }

    function test__RegisterEmptyDomain() public {
        vm.prank(owner);
        vm.expectRevert("Domain name cannot be empty");
        simpleDNS.registerDomain("", "192.168.1.1");
    }

    // ======== Domain Update Tests ========
    function test__UpdateDomain() public {
        vm.startPrank(owner);
        simpleDNS.registerDomain("example.com", "192.168.1.1");
        simpleDNS.updateDomain("example.com", "192.168.1.2");
        vm.stopPrank();
        
        assertEq(simpleDNS.getIP("example.com"), "192.168.1.2");
    }

    function test__UpdateDomainEvent() public {
        string memory oldIP = "192.168.1.1";
        string memory newIP = "192.168.1.2";
        bytes32 domainHash = simpleDNS.stringToBytes32("example.com");
        
        vm.prank(owner);
        simpleDNS.registerDomain("example.com", oldIP);
        
        vm.expectEmit(true, false, false, true);
        emit SimpleDNS.DomainUpdated(domainHash, oldIP, newIP);
        
        vm.prank(owner);
        simpleDNS.updateDomain("example.com", newIP);
    }

    function test__NonOwnerUpdate() public {
        vm.prank(owner);
        simpleDNS.registerDomain("example.com", "192.168.1.1");
        
        vm.prank(user1);
        vm.expectRevert("Only the contract owner can call this function");
        simpleDNS.updateDomain("example.com", "192.168.1.2");
    }

    function test__UpdateNonExistentDomain() public {
        vm.prank(owner);
        vm.expectRevert("Domain not registered");
        simpleDNS.updateDomain("nonexistent.com", "192.168.1.2");
    }

    // ======== Domain Removal Tests ========
    function test__RemoveDomain() public {
        vm.startPrank(owner);
        simpleDNS.registerDomain("example.com", "192.168.1.1");
        simpleDNS.removeDomain("example.com");
        vm.stopPrank();
        
        assertEq(simpleDNS.domainExists("example.com"), false);
    }

    function test__RemoveDomainEvent() public {
        bytes32 domainHash = simpleDNS.stringToBytes32("example.com");
        
        vm.prank(owner);
        simpleDNS.registerDomain("example.com", "192.168.1.1");
        
        vm.expectEmit(true, false, false, false);
        emit SimpleDNS.DomainRemoved(domainHash);
        
        vm.prank(owner);
        simpleDNS.removeDomain("example.com");
    }

    function test__NonOwnerRemove() public {
        vm.prank(owner);
        simpleDNS.registerDomain("example.com", "192.168.1.1");
        
        vm.prank(user1);
        vm.expectRevert("Only the contract owner can call this function");
        simpleDNS.removeDomain("example.com");
    }

    function test__RemoveNonExistentDomain() public {
        vm.prank(owner);
        vm.expectRevert("Domain not registered");
        simpleDNS.removeDomain("nonexistent.com");
    }

    function test__CannotQueryRemovedDomain() public {
        vm.startPrank(owner);
        simpleDNS.registerDomain("example.com", "192.168.1.1");
        simpleDNS.removeDomain("example.com");
        vm.stopPrank();
        
        vm.expectRevert("Domain not registered");
        simpleDNS.getIP("example.com");
    }

    // ======== Domain Querying Tests ========
    function test__QueryDomain() public {
        vm.prank(owner);
        simpleDNS.registerDomain("example.com", "192.168.1.1");
        
        vm.prank(user1);
        string memory ip = simpleDNS.getIP("example.com");
        
        assertEq(ip, "192.168.1.1");
    }

    function test__DomainExists() public {
        vm.prank(owner);
        simpleDNS.registerDomain("example.com", "192.168.1.1");
        
        assertEq(simpleDNS.domainExists("example.com"), true);
        assertEq(simpleDNS.domainExists("nonexistent.com"), false);
    }

    // ======== Ownership Management Tests ========
    function test__TransferOwnership() public {
        vm.prank(owner);
        simpleDNS.transferOwnership(user1);
        
        assertEq(simpleDNS.owner(), user1);
    }

    function test__TransferOwnershipEvent() public {
        vm.expectEmit(true, true, false, false);
        emit SimpleDNS.OwnershipTransferred(owner, user1);
        
        vm.prank(owner);
        simpleDNS.transferOwnership(user1);
    }

    function test__NonOwnerTransfer() public {
        vm.prank(user1);
        vm.expectRevert("Only the contract owner can call this function");
        simpleDNS.transferOwnership(user2);
    }

    function test__TransferToZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert("New owner cannot be the zero address");
        simpleDNS.transferOwnership(address(0));
    }

    function test__NewOwnerCanRegister() public {
        vm.prank(owner);
        simpleDNS.transferOwnership(user1);
        
        vm.prank(user1);
        simpleDNS.registerDomain("newdomain.com", "192.168.1.3");
        
        assertEq(simpleDNS.getIP("newdomain.com"), "192.168.1.3");
    }

    // ======== Domain Hashing Tests ========
    function test__HashConsistency() view external {
        bytes32 hash1 = simpleDNS.stringToBytes32("example.com");
        bytes32 hash2 = simpleDNS.stringToBytes32("example.com");
        
        assertEq(hash1, hash2);
    }

    function test__HashUniqueness() view external {
        bytes32 hash1 = simpleDNS.stringToBytes32("example.com");
        bytes32 hash2 = simpleDNS.stringToBytes32("example.org");
        
        assertTrue(hash1 != hash2);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/WakuNameService.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WakuNameServiceTest is Test {
    WakuNameService private wns;
    address private owner;
    address private nonOwner;

    // Test domain data
    string private constant DOMAIN_1 = "waku.eth";
    string private constant DOMAIN_2 = "test.waku.eth";
    bytes private constant PUBLIC_KEY_1 = hex"04a5b3c17e8596ec143176c7c504db6bb6277c9eef87b2d03674d62eb140658c86c6d1136cd0873e46bfa72a32dc027c1d5b45e42b950312785ec4422f67ca0f11";
    bytes private constant PUBLIC_KEY_2 = hex"0487d2b8717520678f764efc03b84cf548e0e596bd34b9d9c3430d11d399c0429e29d04b41f872e9fea876882cf7bafabf4a3a43c8aabb0543c67bb1be77651a6a";
    bytes private constant NEW_PUBLIC_KEY = hex"04ae1e54ffd06597bb0a16b06d7649a30f6a9a903479bbafb9cb59ea41227d8aeab763b7fa516c38e3f1241fb3a38f38050d365c2a74a0d4d5ef8e539e291bf19f";

    function setUp() public {
        // Create test accounts
        owner = address(this);
        nonOwner = address(0x1);
        vm.label(owner, "Owner");
        vm.label(nonOwner, "NonOwner");

        // Deploy the contract
        wns = new WakuNameService();
    }

    function testAddDomain() public {
        // Add a domain
        bool success = wns.addDomain(DOMAIN_1, PUBLIC_KEY_1);
        
        // Verify domain was added
        assertTrue(success);
        assertTrue(wns.domainExists(DOMAIN_1));
        assertEq(wns.getPublicKey(DOMAIN_1), PUBLIC_KEY_1);
    }

    function testAddMultipleDomains() public {
        // Add multiple domains
        wns.addDomain(DOMAIN_1, PUBLIC_KEY_1);
        wns.addDomain(DOMAIN_2, PUBLIC_KEY_2);
        
        // Verify all domains were added correctly
        assertTrue(wns.domainExists(DOMAIN_1));
        assertTrue(wns.domainExists(DOMAIN_2));
        assertEq(wns.getPublicKey(DOMAIN_1), PUBLIC_KEY_1);
        assertEq(wns.getPublicKey(DOMAIN_2), PUBLIC_KEY_2);
    }

    function testRevertWhenAddingDuplicateDomain() public {
        // Add a domain
        wns.addDomain(DOMAIN_1, PUBLIC_KEY_1);
        
        // Try to add the same domain again (should revert)
        vm.expectRevert("WakuNameService: Domain already exists");
        wns.addDomain(DOMAIN_1, PUBLIC_KEY_2);
    }

    function testRevertWhenAddingEmptyPublicKey() public {
        // Try to add a domain with empty public key (should revert)
        bytes memory emptyKey = new bytes(0);
        vm.expectRevert("WakuNameService: Public key cannot be empty");
        wns.addDomain(DOMAIN_1, emptyKey);
    }

    function testUpdateDomain() public {
        // Add a domain first
        wns.addDomain(DOMAIN_1, PUBLIC_KEY_1);
        
        // Update the domain's public key
        bool success = wns.updateDomain(DOMAIN_1, NEW_PUBLIC_KEY);
        
        // Verify domain was updated
        assertTrue(success);
        assertEq(wns.getPublicKey(DOMAIN_1), NEW_PUBLIC_KEY);
    }

    function testRevertWhenUpdatingWithEmptyPublicKey() public {
        // Add a domain first
        wns.addDomain(DOMAIN_1, PUBLIC_KEY_1);
        
        // Try to update with empty public key (should revert)
        bytes memory emptyKey = new bytes(0);
        vm.expectRevert("WakuNameService: Public key cannot be empty");
        wns.updateDomain(DOMAIN_1, emptyKey);
    }

    function testRevertWhenUpdatingNonExistentDomain() public {
        // Try to update a domain that doesn't exist (should revert)
        vm.expectRevert("WakuNameService: Domain does not exist");
        wns.updateDomain(DOMAIN_1, PUBLIC_KEY_1);
    }

    function testRemoveDomain() public {
        // Add a domain first
        wns.addDomain(DOMAIN_1, PUBLIC_KEY_1);
        
        // Remove the domain
        bool success = wns.removeDomain(DOMAIN_1);
        
        // Verify domain was removed
        assertTrue(success);
        assertFalse(wns.domainExists(DOMAIN_1));
        
        // Try to get the public key (should revert)
        vm.expectRevert("WakuNameService: Domain does not exist");
        wns.getPublicKey(DOMAIN_1);
    }

    function testRevertWhenRemovingNonExistentDomain() public {
        // Try to remove a domain that doesn't exist (should revert)
        vm.expectRevert("WakuNameService: Domain does not exist");
        wns.removeDomain(DOMAIN_1);
    }

    function testGetAllDomains() public {
        // Add a few domains
        wns.addDomain(DOMAIN_1, PUBLIC_KEY_1);
        wns.addDomain(DOMAIN_2, PUBLIC_KEY_2);
        
        // Get all domains
        string[] memory domains = wns.getAllDomains();
        
        // Verify the domains list
        assertEq(domains.length, 2);
        assertEq(domains[0], DOMAIN_1);
        assertEq(domains[1], DOMAIN_2);
    }

    function testNonOwnerCannotAddDomain() public {
        // Switch to non-owner account
        vm.startPrank(nonOwner);
        
        // Try to add a domain (should revert)
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, nonOwner));
        wns.addDomain(DOMAIN_1, PUBLIC_KEY_1);
        
        vm.stopPrank();
    }

    function testNonOwnerCannotUpdateDomain() public {
        // Add a domain as owner
        wns.addDomain(DOMAIN_1, PUBLIC_KEY_1);
        
        // Switch to non-owner account
        vm.startPrank(nonOwner);
        
        // Try to update a domain (should revert)
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, nonOwner));
        wns.updateDomain(DOMAIN_1, NEW_PUBLIC_KEY);
        
        vm.stopPrank();
    }

    function testNonOwnerCannotRemoveDomain() public {
        // Add a domain as owner
        wns.addDomain(DOMAIN_1, PUBLIC_KEY_1);
        
        // Switch to non-owner account
        vm.startPrank(nonOwner);
        
        // Try to remove a domain (should revert)
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, nonOwner));
        wns.removeDomain(DOMAIN_1);
        
        vm.stopPrank();
    }

    function testTransferOwnership() public {
        // Transfer ownership to the non-owner account
        wns.transferOwnership(nonOwner);
        
        // Verify ownership was transferred
        assertEq(wns.owner(), nonOwner);
        
        // Original owner can no longer add domains
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, owner));
        wns.addDomain(DOMAIN_1, PUBLIC_KEY_1);
        
        // New owner can add domains
        vm.startPrank(nonOwner);
        bool success = wns.addDomain(DOMAIN_1, PUBLIC_KEY_1);
        assertTrue(success);
        vm.stopPrank();
    }

    function testRevertWhenTransferringOwnershipToZeroAddress() public {
        // Try to transfer ownership to zero address (should revert)
        vm.expectRevert("WakuNameService: new owner is the zero address");
        wns.transferOwnership(address(0));
    }
}
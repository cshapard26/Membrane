// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "hardhat/console.sol";
import "./onetimekey-dev.sol";

contract OneTimeKeyTest {
    
    bytes32 instituteKey = "PIGfMA0GCSqGSIb3DQEBAQUAA4GDAQAB";
    OneTimeKey KeyStorage;

    function beforeAll () public {
        console.log("Running beforeAll");
        KeyStorage = new OneTimeKey();
        KeyStorage.issueKey(msg.sender, instituteKey);
    }

    function returnDisplayKey() public view returns (bytes32) {
        bytes32 bigData = KeyStorage.displayKey(msg.sender);
        return bigData;
    }
    
    function checkKeyUse() public {
        console.log("Running checkKeyUse");
        Assert.equal(KeyStorage.getKeyStatus(msg.sender), false, "Key should not be used yet.");
        KeyStorage.useKey(instituteKey);
        Assert.equal(KeyStorage.getKeyStatus(msg.sender), true, "Key should have been used.");
        console.log("Success!");
    }
}

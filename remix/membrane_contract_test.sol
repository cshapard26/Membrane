// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @custom:dev-run-script ../scripts/deploy_with_ethers.ts
 */


import "remix_tests.sol"; // this import is automatically injected by Remix.
import "hardhat/console.sol";
import "./_MembraneContract.sol";

contract MembraneTest {
    string serverKey = "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCI1KiHgoR6IwBjvOUXpxyzJyhky9ECGggBjisl7WMe1ucxDFsfPf+n9ghCGleODU7NM/NwulIHfT/Juwbmrh/hNx+D8Cb4nbC6/tYUtKVs5d9qpC8K2FoNhX6GdEPx6pjweX4f8wM+5Ev1LU6YXa9udMjNYgpqSOggkv4uHTVYvQIDAQAB";
    MembraneCrowdsourcing membraneInstance;

    bytes encryptedData = "Hello, world!";
    bytes hashedData = bytes32ToBytes(keccak256(abi.encodePacked(encryptedData)));

    function beforeAll () public {
        console.log("Running beforeAll");
        membraneInstance = new MembraneCrowdsourcing();
        membraneInstance.setServerPublicKey(serverKey);
        console.log("Success!");
    }

    function checkCommit() public {
        console.log("Running checkCommit");
        Assert.equal(membraneInstance.checkCommitReceived(), false, "commit should not have been received yet.");
        membraneInstance.commit(hashedData, hashedData);
        Assert.equal(membraneInstance.checkCommitReceived(), true, "commit should have been received.");
        console.log("Success!");
    }

    function checkReveal() public view {
        console.log("Running checkReveal");
        membraneInstance.reveal(encryptedData);
        console.log("Success!");
    }

    function bytes32ToBytes(bytes32 data) public pure returns (bytes memory) {
        bytes memory result = new bytes(32);
        assembly {
            mstore(add(result, 32), data)
        }
        return result;
    }
}

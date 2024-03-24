// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "hardhat/console.sol";
import "./_MembraneContract.sol";

contract MembraneTest {
    bytes serverKey = "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCI1KiHgoR6IwBjvOUXpxyzJyhky9ECGggBjisl7WMe1ucxDFsfPf+n9ghCGleODU7NM/NwulIHfT/Juwbmrh/hNx+D8Cb4nbC6/tYUtKVs5d9qpC8K2FoNhX6GdEPx6pjweX4f8wM+5Ev1LU6YXa9udMjNYgpqSOggkv4uHTVYvQIDAQAB";
    MembraneCrowdsourcing crowdsourceInstance;

    bytes encryptedData;
    bytes32 hashedData = "78016cea74c298162366b9f86bfc3b16";

    function beforeAll () public {
        crowdsourceInstance.setServerPublicKey(serverKey);
    }

    function checkCommit() public {
        console.log("Running checkWinningProposal");
        crowdsourceInstance.commit(hashedData, hashedData);
        Assert.equal(crowdsourceInstance.checkCommitReceived(), true, "commit should have been received.");
    }
}

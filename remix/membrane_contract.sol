// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/** 
 * @title Membrane
 * @dev Stores encrypted crowdsourced data and sends it to approved receivers
 */

import {Chainlink, ChainlinkClient} from "@chainlink/contracts@0.8.0/src/v0.8/ChainlinkClient.sol";
import {LinkTokenInterface} from "@chainlink/contracts@0.8.0/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

import "./onetimekey.sol";

contract MembraneCrowdsourcing is ChainlinkClient  {
    using Chainlink for Chainlink.Request;

    struct Dataload {
        bytes hashedData;
        bytes hashedApprovedRecipients;
    }

    address private membraneHostOwner;
    string public serverPublicKey;
    uint256 public commitReceived = 1;
    Dataload private userData;
    mapping(address => bool) private approvedReceivers;
    uint256 private approvedReceiversCount;
    
    // One time Key
    OneTimeKey public onetimekey;

    // Chainlink variables
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;


    constructor() {
        membraneHostOwner = msg.sender;
        setChainlinkToken(0x779877A7B0D9E8603169DdbD7836e478b4624789);
        setChainlinkOracle(0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD);
        jobId = "7da2702f37fd48e5b1b9a5715e3509b6";
        fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18 (Varies by network and job)
        onetimekey = new OneTimeKey();
    }

    event OwnerSet(address indexed membraneHostOwner, address indexed newOwner);
    event KeyChange(string oldKey, string newKey, address indexed changer);
    event DataSubmit(address indexed user, bytes hashedData);
    event DataTransferReceipt(address indexed user, string Chainlinkresponse);
    event DataToInstitutionReceipt(address indexed user, string Chainlinkresponse);

    modifier isOwner() {
        require(msg.sender == membraneHostOwner, "Only the owner has access to this function");
        _;
    }

    modifier commitIsReceived() {
        require(commitReceived == 1, "Commit not yet received.");
        _;
    }

    function addApprovedReceiver(address receiver) external isOwner {
        require(!approvedReceivers[receiver], "Receiver already approved");
        approvedReceivers[receiver] = true;
        unchecked { approvedReceiversCount++; }
    }

    function removeApprovedReceiver(address receiver) external isOwner {
        require(approvedReceivers[receiver], "Receiver not approved");
        approvedReceivers[receiver] = false;
        unchecked { approvedReceiversCount--; }
    }

    function isApprovedReceiver(address receiver) public view returns (bool) {
        return approvedReceivers[receiver];
    }

    function getApprovedReceiversCount() public view returns (uint256) {
        return approvedReceiversCount;
    }

    function changeOwner(address newOwner) external isOwner {
        emit OwnerSet(membraneHostOwner, newOwner);
        membraneHostOwner = newOwner;
    }

    function setServerPublicKey(bytes calldata newKey) external isOwner {
        emit KeyChange(serverPublicKey, string(newKey), msg.sender);
        serverPublicKey = string(newKey);
    }


    function getServerPublicKey() external view returns (string memory){
        return serverPublicKey;       // Return the address for public key encryption
    }

    function commit(bytes calldata _encryptedData, bytes calldata _encryptedApprovedRecipients) external {
        userData.hashedApprovedRecipients = _encryptedApprovedRecipients;
        userData.hashedData = _encryptedData;
        emit DataSubmit(msg.sender, userData.hashedData);
        commitReceived = 1;
    }

    function checkCommitReceived() external view returns (bool) {
        return commitReceived == 1;
    }

    function reveal(bytes calldata encryptedPayload) external view {
        require(commitReceived == 1, "Commit not yet received.");
        bytes32 hashData = keccak256(encryptedPayload);
        require(keccak256(userData.hashedData) == keccak256(abi.encodePacked(hashData)), "Hashed data not equivalent. Aborting.");
        sendDataToServer(encryptedPayload);
    }

    function sendDataToServer(bytes memory _encryptedPayload) private view isOwner() {
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.dataTransferCallback.selector);
        req.add("url", "QmXXXXXXX");     // SET QM Hash here
        req.add("method", "PUT");
        req.add("body", string(_encryptedPayload));
        // sendChainlinkRequest(req, fee);      Results in error unless chainlink node is set up.
    }

    function zeroKnowledgeProof() internal view returns (bool) {
        uint p = 10111; 
        uint g = 2;
        uint x = 56;
        uint y = x**g;

        uint claim = (27*x + 37*y) % p;
        uint encrypted_claim = (g**claim) % p;

        uint mul = (((g**x) % p) * ((g**y) % p)) % p;

        return encrypted_claim == mul;
    }

    function canAccessData(address requester) private {
        require(msg.sender == membraneHostOwner, "Only the owner has access to this function");
        require(zeroKnowledgeProof(), "Zero Knowledge Proof not verified.");
        
        bool canAccess = approvedReceivers[requester];
        
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.dataToInstitutionCallback.selector);
        req.add("url", "QmXXXXXXX");     // SET QM Hash here
        req.add("method", "PUT");
        req.add("body", canAccess ? "Approved" : "Denied");

        bytes32 randomKey = keccak256(abi.encodePacked(block.timestamp, block.prevrandao, blockhash(block.number - 1)));
        onetimekey.issueKey(requester, randomKey);
        // sendChainlinkRequest(req, fee);
    } 

    function dataTransferCallback() public {
        emit DataTransferReceipt(msg.sender, "Success!");
    }

    function dataToInstitutionCallback() public {
        emit DataToInstitutionReceipt(msg.sender, "Success!");
    }

    function bytes32ToBytes(bytes32 data) public pure returns (bytes memory) {
        bytes memory result = new bytes(32);
        assembly {
            mstore(add(result, 32), data)
        }
        return result;
    }

    function areBytesEqual(bytes memory a, bytes memory b) public pure returns (bool) {
        if (a.length != b.length) {
            return false;
        }
        for (uint i = 0; i < a.length; i++) {
            if (a[i] != b[i]) {
                return false;
            }
        }
        return true;
    }

    function generateRandomKey() public view returns (bytes32) {
        bytes32 randomKey = keccak256(abi.encodePacked(block.timestamp, block.prevrandao, blockhash(block.number - 1)));
        return randomKey;
    }
 }

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/** 
 * @title Membrane
 * @dev Stores encrypted crowdsourced data and sends it to approved receivers
 */

import {Chainlink, ChainlinkClient} from "@chainlink/contracts@0.8.0/src/v0.8/ChainlinkClient.sol";
import {LinkTokenInterface} from "@chainlink/contracts@0.8.0/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

contract MembraneCrowdsourcing is ChainlinkClient  {
    using Chainlink for Chainlink.Request;

    struct Dataload {
        bytes32 hashedData;
        bytes32 hashedApprovedRecipients;
    }

    address private membraneHostOwner;
    bytes public serverPublicKey;
    bool private commitReceived = false;
    Dataload private userData;
    address[] private approvedReceivers;
    

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
    }

    event OwnerSet(address indexed membraneHostOwner, address indexed newOwner);
    event KeyChange(bytes oldKey, bytes newKey, address indexed changer);
    event DataSubmit(address indexed user, bytes32 hashedData);
    event DataTransferReceipt(address indexed user, string Chainlinkresponse);
    event DataToInstitutionReceipt(address indexed user, string Chainlinkresponse);

    modifier isOwner() {
        require(msg.sender == membraneHostOwner, "Only the owner has access to this function");
        _;
    }

    modifier commitIsReceived() {
        require(commitReceived == true, "Commit not yet received.");
        _;
    }

    function addApprovedReceiver(address receiver) public isOwner{
        approvedReceivers.push(receiver);
    }

    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(membraneHostOwner, newOwner);
        membraneHostOwner = newOwner;
    }

    function setServerPublicKey(bytes calldata newKey) public isOwner() {
        emit KeyChange(serverPublicKey, newKey, msg.sender);
        serverPublicKey = newKey;
    }

    modifier dataReal() {
        // ZKP
        _;
    }

    function getServerPublicKey() external view returns (bytes memory){
        return serverPublicKey;       // Return the address for public key encryption
    }

    function commit(bytes32 _encryptedData, bytes32 _encryptedApprovedRecipients) external {
        userData.hashedApprovedRecipients = _encryptedApprovedRecipients;
        userData.hashedData = _encryptedData;
        emit DataSubmit(msg.sender, userData.hashedData);
        commitReceived = true;
    }

    function reveal(bytes calldata encryptedPayload) external commitIsReceived() {
        bytes32 hashData = keccak256(abi.encodePacked(encryptedPayload));
        require(userData.hashedData == hashData, "Hashed data not equivalent. Aborting.");
        sendDataToServer(encryptedPayload);
    }

    function sendDataToServer(bytes memory _encryptedPayload) private isOwner() {
        // Upload to file
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.dataTransferCallback.selector);
        req.add("url", "https://ipfs.example.com/api");     // SET API HERE
        req.add("method", "PUT");
        req.add("body", string(_encryptedPayload));

        sendChainlinkRequest(req, fee);
    }

    function canAccessData(address requester) private isOwner() {
        bool canAccess = false;
        for (uint i = 0; i < approvedReceivers.length; i++) {
            if (approvedReceivers[i] == requester) {
                canAccess = true;
            } 
        }
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.dataToInstitutionCallback.selector);
        req.add("url", "https://ipfs.example.com/api");     // SET API HERE
        req.add("method", "PUT");
        if (canAccess) {
            req.add("body", "Approved");
        } else {
            req.add("body", "Denied");
        }

        sendChainlinkRequest(req, fee);

    }

    function dataTransferCallback() public {
        emit DataTransferReceipt(msg.sender, "Success!");
    }

    function dataToInstitutionCallback() public {
        emit DataToInstitutionReceipt(msg.sender, "Success!");
    }
 }

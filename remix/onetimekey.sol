// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract OneTimeKey {
    address owner;
    mapping(address => bytes32) private keys;
    mapping(bytes32 => bool) public keyUsed;

    address[] private theAddresses;

    event KeyIssued(address indexed to, bytes32 key);
    event KeyUsed(address indexed by, bytes32 key);

    constructor() {
        owner = msg.sender;
    }


    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can issue keys");
        _;
    }


    function issueKey(address _to, bytes32 _key) public onlyOwner {
        require(keys[_to] == 0, "Key already issued");
        keys[_to] = _key;
        theAddresses.push(_to);
        emit KeyIssued(_to, _key);

    }


    function useKey(bytes32 _key) public {
        bool keyInList = false;
        for (uint i = 0; i < theAddresses.length; i++) {
            if (keys[theAddresses[i]] == _key) {
                keyInList = true;
            }
        }
        require(keyInList, "Invalid key");
        require(!keyUsed[_key], "Key already used");
        keyUsed[_key] = true;

        emit KeyUsed(msg.sender, _key);

        delete keys[msg.sender];

    }


    function getKeyStatus(address _user) public view returns (bool) {
        return keyUsed[keys[_user]];
    }


    function displayKey(address _user) public view returns (bytes32) {
        return keys[_user];
    }
}

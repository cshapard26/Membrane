// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OneTimeKey {
    address owner;
    mapping(address => bytes32) private keys;
    mapping(address => bool) public keyUsed;

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
        emit KeyIssued(_to, _key);
    }

    function useKey(bytes32 _key) public {
        require(keys[msg.sender] == _key, "Invalid key");
        require(!keyUsed[msg.sender], "Key already used");
        keyUsed[msg.sender] = true;

        emit KeyUsed(msg.sender, _key);


        delete keys[msg.sender];
    }

    function getKeyStatus(address _user) public view returns (bool) {
        return keyUsed[_user];
    }
}

// solium-disable linebreak-style
pragma solidity ^0.4.24;

/**
 * @title Whitelist
 * @dev Whitelist contract has its own role whitelister and maintains index of whitelisted addresses.
 */
contract Whitelist {

    // who can whitelist
    address public whitelister;

    // Whitelist mapping
    mapping (address => bool) whitelist;

    /**
      * @dev The Whitelist constructor sets the original `whitelister` of the contract to the sender
      * account.
      */
    constructor() public {
        whitelister = msg.sender;
    }

    /**
      * @dev Throws if called by any account other than the whitelister.
      */
    modifier onlyWhitelister() {
        require(msg.sender == whitelister);
        _;
    }

    modifier addressNotZero(address _address) {
        require(_address != address(0));
        _;
    }

    modifier onlyWhitelisted(address _address) {
        require(whitelist[_address]);
        _;
    }

    /** 
    * @dev Only callable by the whitelister. Whitelists the specified address.
    * @notice Only callable by the whitelister. Whitelists the specified address.
    * @param _address Address to be whitelisted. 
    */
    function addToWhitelist(address _address) public onlyWhitelister addressNotZero(_address) {
        emit WhitelistAdd(whitelister, _address);
        whitelist[_address] = true;
    }
    
    /** 
    * @dev Only callable by the whitelister. Whitelists the specified addresses.
    * @notice Only callable by the whitelister. Whitelists the specified addresses.
    * @param _addresses Addresses to be whitelisted. 
    */
    function addAddressesToWhitelist(address[] _addresses) public onlyWhitelister {
        for(uint i = 0; i < _addresses.length; ++i)
            addToWhitelist(_addresses[i]);
    }

    /**
    * @dev Checks if the specified address is whitelisted.
    * @notice Checks if the specified address is whitelisted. 
    * @param _address Address to be whitelisted.
    */
    function isWhitelisted(address _address) public view returns (bool) {
        return whitelist[_address];
    }

    /**
      * @dev Changes the current whitelister. Callable only by the whitelister.
      * @notice Changes the current whitelister. Callable only by the whitelister.
      * @param _newWhitelister Address of new whitelister.
      */
    function changeWhitelister(address _newWhitelister) public onlyWhitelister addressNotZero(_newWhitelister) {
        emit WhitelisterChanged(whitelister, _newWhitelister);
        whitelister = _newWhitelister;
    }

    /** 
    * Event for logging the whitelister change. 
    * @param previousWhitelister Old whitelister.
    * @param newWhitelister New whitelister.
    */
    event WhitelisterChanged(address indexed previousWhitelister, address indexed newWhitelister);
    
    /** 
    * Event for logging when the user is whitelisted.
    * @param whitelister Current whitelister.
    * @param whitelistedAddress User added to whitelist.
    */
    event WhitelistAdd(address indexed whitelister, address indexed whitelistedAddress);
}

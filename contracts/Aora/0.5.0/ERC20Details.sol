// solium-disable linebreak-style
pragma solidity ^0.5.0;

import "./TokenDetails.sol";

contract ERC20Details is TokenDetails {

    uint8 internal _decimals;

    /**
    * @return the number of decimals of the token.
    */
    function decimals() public view returns(uint8) {
        return _decimals;
    }

}
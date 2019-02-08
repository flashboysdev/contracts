// solium-disable linebreak-style
pragma solidity ^0.5.0;


contract TokenDetails {

    string internal _name;
    string internal _symbol;
    
    /**
    * @return the name of the token.
    */
    function name() public view returns(string memory) {
        return _name;
    }

    /**
    * @return the symbol of the token.
    */
    function symbol() public view returns(string memory) {
        return _symbol;
    }

}
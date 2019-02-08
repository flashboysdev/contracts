// solium-disable linebreak-style
pragma solidity ^0.5.0;

import "./ERC20Burnable.sol";
import "./ERC20Mintable.sol";
import "./ERC20Details.sol";
import "./Ownable.sol";

contract AoraCoin is ERC20Burnable, ERC20Mintable, ERC20Details, Ownable {
    constructor () public {
        _decimals = 18;
        _name = "AORA COIN";
        _symbol = "AORA";
        _totalSupply = 650000000 ether; // TODO: Check
        _balances[msg.sender] = _totalSupply;
    }

    function burn(uint value) public onlyOwner {
        _burn(msg.sender, value);
    }

    function mint(address to, uint value) public onlyOwner { 
        _mint(to, value);
    }

    function claimTokens(address _token) public onlyOwner {
        address payable owner = address(uint160(owner()));
        
        if (_token == address(0)) {
            owner.transfer(address(this).balance);
            return;
        }

        IERC20 token = IERC20(_token);
        uint balance = token.balanceOf(address(this));
        token.transfer(owner, balance);
        emit ClaimedTokens(_token, owner, balance);
    }

    // Emitted when calimTokens function is invoked.
    event ClaimedTokens(address tokenAddress, address ownerAddress, uint amount);
}
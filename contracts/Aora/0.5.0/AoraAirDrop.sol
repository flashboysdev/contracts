// solium-disable linebreak-style
pragma solidity ^0.5.0;

import "./Pausable.sol";
import "./IERC20.sol";

contract AoraAirDrop is Pausable {
    
    IERC20 public AoraCoin;
    
    function setAoraCoinAddress(address newAddress) public onlyOwner {
        require(newAddress != address(0));
        emit AoraContractAddressChanged(address(AoraCoin), newAddress);
        AoraCoin = IERC20(newAddress);
    }

    function getAoraCoinAddress() public view returns(address) {
        return address(AoraCoin);
    }

    constructor(address aoraCoinAddress) public {
        AoraCoin = IERC20(aoraCoinAddress);
    }

    function airDrop(address to, uint value) public onlyOwner whenNotPaused {
        AoraCoin.transfer(to, value);
        emit AirDrop(to, value);
    }

    function airDropBulk(address[] memory addresses, uint[] memory values) public onlyOwner whenNotPaused {
        uint iterations = addresses.length;
        
        require(iterations != 0);
        require(iterations == values.length);

        for (uint i = 0; i < iterations; ++i)
            airDrop(addresses[i], values[i]);
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

    // Emitted when setAoraCoinAddress function is invoked. 
    event AoraContractAddressChanged(address oldAddress, address newAddress);

    // Emitted when the airDrop function is invoked.
    event AirDrop(address to, uint value);

    // Emitted when withdrawAoraCoin function in invoked.
    event AoraCoinsWithdrawn(); 

    // Emitted when calimTokens function is invoked.
    event ClaimedTokens(address tokenAddress, address ownerAddress, uint amount);
}

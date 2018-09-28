// solium-disable linebreak-style
pragma solidity ^0.4.24;

import "./Ownable.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

contract AoraTgeCoin is IERC20, Ownable {
    using SafeMath for uint256;

    // Name of the token
    string public constant name = "Aora TGE Coin"; 
    
    // Symbol of the token
    string public constant symbol = "AORATGE";

    // Number of decimals for the token
    uint8 public constant decimals = 18;
    
    uint constant private _totalSupply = 650000000 ether;

    // Contract deployment block
    uint256 public deploymentBlock;

    // Address of the convertContract
    address public convertContract = address(0);

    // Address of the crowdsaleContract
    address public crowdsaleContract = address(0);

    // Token balances 
    mapping (address => uint) balances;

    // Sets the convertContract address
    function setConvertContract(address _convert) external onlyOwner {
        require(address(0) != address(_convert));
        convertContract = _convert;
        emit OnConvertContractSet(_convert);
    }

    // Sets the convertContract address
    function setCrowdsaleContract(address _crowdsale) external onlyOwner {
        require(address(0) != address(_crowdsale));
        convertContract = _crowdsale;
        emit OnCrowdsaleContractSet(_crowdsale);
    }

    modifier onlyConvert {
        require(msg.sender == convertContract);
        _;
    }

    constructor() public {
        balances[msg.sender] = _totalSupply;
        deploymentBlock = block.number;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address who) external view returns (uint256) {
        return balances[who];
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        require(false);
        return 0;
    }

    /**
    * @dev Transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        // Only owner or crowdsale contract can call this method 
        require(msg.sender == owner || msg.sender == crowdsaleContract);

        require(_value <= balances[msg.sender]);
        require(_to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        require(false);
        return false;
    }

    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) onlyConvert public returns (bool) {
        require(_value <= balances[_from]);
        require(_to == address(0));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
    * @dev This method can be used by the owner to extract mistakenly sent tokens
    * or Ether sent to this contract.
    * @param _token address The address of the token contract that you want to
    * recover set to 0 in case you want to extract ether. It can't be ElpisToken.
    */
    function claimTokens(address _token) public onlyOwner {
        require(_token != address(convertContract), "Na-a! That is insanitiy!");

        if (_token == address(0)) {
            owner.transfer(address(this).balance);
            return;
        }

        ERC20 tokenReference = ERC20(_token);
        uint balance = tokenReference.balanceOf(address(this));
        tokenReference.transfer(owner, balance);
        emit OnClaimTokens(_token, owner, balance);
    }

    /**
    * @param crowdsaleAddress crowdsale contract address
    */
    event OnCrowdsaleContractSet(address indexed crowdsaleAddress);

    /**
    * @param convertAddress crowdsale contract address
    */
    event OnConvertContractSet(address indexed convertAddress);

    /**
    * @param token claimed token
    * @param owner who owns the contract
    * @param amount amount of the claimed token
    */
    event OnClaimTokens(address indexed token, address indexed owner, uint256 amount);
}
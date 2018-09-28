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
        require(msg.sender == whitelister, "Only whitelister can call this method.");
        _;
    }

    modifier addressNotZero(address _address) {
        require(_address != address(0), "We don't like address 0x0."); // TODO: Change the message to something that makes more sense
        _;
    }

    modifier onlyWhitelisted(address _address) {
        require(whitelist[_address], "Only whitelisted addresses can do that.");
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

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

    // Owner's address
    address public owner;

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public {
        owner = msg.sender;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit OwnerChanged(owner, _newOwner);
        owner = _newOwner;
    }

    event OwnerChanged(address indexed previousOwner,address indexed newOwner);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

  /**
  * @dev Total number of tokens in existence
  */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

  /**
  * @dev Gets the balance of the specified address.
  * @param owner The address to query the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param owner address The address which owns the funds.
   * @param spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
    function allowance(
        address owner,
        address spender
    )
        public
        view
        returns (uint256)
    {
        return _allowed[owner][spender];
    }

  /**
  * @dev Transfer token for a specified address
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
    function transfer(address to, uint256 value) public returns (bool) {
        require(value <= _balances[msg.sender]);
        require(to != address(0));

        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

  /**
   * @dev Transfer tokens from one address to another
   * @param from address The address which you want to send tokens from
   * @param to address The address which you want to transfer to
   * @param value uint256 the amount of tokens to be transferred
   */
    function transferFrom(
        address from,
        address to,
        uint256 value
    )
        public
        returns (bool)
    {
        require(value <= _balances[from]);
        require(value <= _allowed[from][msg.sender]);
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param addedValue The amount of tokens to increase the allowance by.
   */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    )
        public
        returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
            _allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param subtractedValue The amount of tokens to decrease the allowance by.
   */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    )
        public
        returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
            _allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

  /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param account The account that will receive the created tokens.
   * @param amount The amount that will be created.
   */
    function _mint(address account, uint256 amount) internal {
        require(account != 0);
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param account The account whose tokens will be burnt.
   * @param amount The amount that will be burnt.
   */
    function _burn(address account, uint256 amount) internal {
        require(account != 0);
        require(amount <= _balances[account]);

        _totalSupply = _totalSupply.sub(amount);
        _balances[account] = _balances[account].sub(amount);
        emit Transfer(account, address(0), amount);
    }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender's allowance for said account. Uses the
   * internal burn function.
   * @param account The account whose tokens will be burnt.
   * @param amount The amount that will be burnt.
   */
    function _burnFrom(address account, uint256 amount) internal {
        require(amount <= _allowed[account][msg.sender]);

        // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
        // this function needs to emit an event with the updated approval.
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
            amount);
        _burn(account, amount);
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
      // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
      // benefit is lost if 'b' is also tested.
      // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract AoraCrowdsale is Whitelist, Ownable {
    using SafeMath for uint256;

    // Token being sold
    IERC20 public token;

    // Start of presale timestamp in miliseconds
    uint public startOfPresale;

    // End of presale timestamp in miliseconds
    uint public endOfPresale;

    // Start of crowdsale timestamp in miliseconds
    uint public startOfCrowdsale;

    // End of crowdsale timestamp in miliseconds
    uint public endOfCrowdsale;

    // Maximum number of tokens that can be sold
    uint public cap;

    // Tokens sold so far
    uint public tokensSold = 0;

    // US Dollars raised so far in cents 
    uint public usdRaised = 0;

    // Deployment block of the contract 
    uint public deploymentBlock;

    // Tokens per US Dollar rate, fixed for this crowsale.
    uint public tokensPerUsdRate = 5;

    // Factor that we multiply with to get whole tokens from cents 
    uint constant public centsToWholeTokenFactor = 10 ** 16; 

    /**
    * @param _startOfPresale start of presale timestamp
    * @param _endOfPresale  end of presale timestamp
    * @param _startOfCrowdsale start of crowdsale timestamp
    * @param _endOfCrowdsale end of crowdsale timestamp
    * @param _tokensPerUsdRate how many tokens per US Dollar contributed
    * @param _cap total amount of sellable tokens 
    * @param _token address of the token contract 
    */
    constructor(
        uint _startOfPresale, 
        uint _endOfPresale, 
        uint _startOfCrowdsale, 
        uint _endOfCrowdsale, 
        uint _tokensPerUsdRate, 
        uint _cap,
        IERC20 _token
        ) public addressNotZero(_token) {
        
        startOfPresale = _startOfPresale;
        endOfPresale = _endOfPresale;
        startOfCrowdsale = _startOfCrowdsale;
        endOfCrowdsale = _endOfCrowdsale;

        tokensPerUsdRate = _tokensPerUsdRate; 

        cap = _cap;

        token = _token;

        deploymentBlock = block.number;
    }

    /**
    * @dev signifies weather or not the argument has any value
    * @param usdAmount amount of US Dollars in cents 
    */ 
    modifier hasValue(uint usdAmount) {
        require(usdAmount > 0);
        _;
    }

    /**
    * @dev signifies weather or not crowdsale is over
    */
    modifier crowdsaleNotOver() {
        require(isCrowdsale()); 
        _;
    }

    /** 
    * @dev sets the start of presale
    */
    function setStartOfPresale(uint _startOfPresale) external onlyOwner {
        emit OnStartOfPresaleSet(_startOfPresale, startOfPresale); 
        startOfPresale = _startOfPresale;
    }

    /**
    * @dev sets the end of presale
    * @param _endOfPresale new timestamp value  
    */
    function setEndOfPresale(uint _endOfPresale) external onlyOwner {
        emit OnEndOfPresaleSet(_endOfPresale, endOfPresale); 
        endOfPresale = _endOfPresale;
    }

    /**
    * @dev sets the start of crowdsale
    * @param _startOfCrowdsale new timestamp value
    */
    function setStartOfCrowdsale(uint _startOfCrowdsale) external onlyOwner {
        emit OnStartOfCrowdsaleSet(_startOfCrowdsale, startOfCrowdsale);
        startOfCrowdsale = _startOfCrowdsale;
    }

    /**
    * @dev sets the end of crowdsale
    * @param _endOfCrowdsale new timestamp value
    */
    function setEndOfCrowdsale(uint _endOfCrowdsale) external onlyOwner {
        emit OnEndOfCrowdsaleSet(_endOfCrowdsale, endOfCrowdsale);
        endOfCrowdsale = _endOfCrowdsale;
    }

    /** 
    * @dev sets the cap
    * @param _cap new cap value
    */
    function setCap(uint _cap) external onlyOwner { 
        emit OnCapSet(_cap, cap);
        cap = _cap;
    }

    /**
    * @dev sets the tokensPerUsdRate
    * @param _tokensPerUsdRate new tokens per US Dollar rate
    */
    function setTokensPerUsdRate(uint _tokensPerUsdRate) external onlyOwner {
        emit OnTokensPerUsdRateSet(_tokensPerUsdRate, tokensPerUsdRate);
        tokensPerUsdRate = _tokensPerUsdRate;
    }

    /**
    * @dev returns weather or not the presale is over
    */
    function isPresale() public view returns(bool) {
        return now < endOfPresale;
    }

    /** 
    * @dev returns weather or not the crowdsale is over
    */
    function isCrowdsale() public view returns(bool) {
        return now < endOfCrowdsale;
    }

    /**
    * @dev Creates a contribution for the specified beneficiary.
    *   Callable only by the owner, while the crowdsale is not over. 
    *   Whitelists the beneficiary as well, to optimize gas cost.
    * @param beneficiary address of the beneficiary
    * @param usdAmount contribution value in cents
    */
    function createContribution(address beneficiary, uint usdAmount) public 
    onlyOwner 
    addressNotZero(beneficiary) 
    hasValue(usdAmount)
    crowdsaleNotOver
    {        
        usdRaised = usdRaised.add(usdAmount); // USD amount in cents 

        uint aoraTgeAmount = usdAmount.mul(tokensPerUsdRate).mul(centsToWholeTokenFactor); 

        if(isPresale())
            aoraTgeAmount = aoraTgeAmount.mul(11).div(10); // 10% presale bonus, paid out from crowdsale pool

        require(tokensSold.add(aoraTgeAmount) <= cap);

        tokensSold = tokensSold.add(aoraTgeAmount);

        token.transfer(beneficiary, aoraTgeAmount);

        addToWhitelist(beneficiary);

        emit OnContributionCreated(beneficiary, usdAmount);
    }

    /**
    * @dev Create contributions in bulk, to optimize gas cost.
    * @param beneficiaries addresses of beneficiaries 
    * @param usdAmounts USDollar value of the each contribution in cents.
    */
    function createBulkContributions(address[] beneficiaries, uint[] usdAmounts) external onlyOwner {
        require(beneficiaries.length == usdAmounts.length);
        for (uint i = 0; i < beneficiaries.length; ++i)
            createContribution(beneficiaries[i], usdAmounts[i]);
    }

    /**
    * @dev This method can be used by the owner to extract mistakenly sent tokens
    * or Ether sent to this contract.
    * @param _token address The address of the token contract that you want to
    * recover set to 0 in case you want to extract ether. It can't be ElpisToken.
    */
    function claimTokens(address _token) public onlyOwner {
        require(_token != address(token));

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
    * @param oldValue old value of the field
    * @param newValue new value of the field
    */
    event OnTokensPerUsdRateSet(uint256 oldValue, uint256 newValue);

    /**
    * @param oldValue old value of the field
    * @param newValue new value of the field
    */
    event OnCapSet(uint256 oldValue, uint256 newValue);

    /**
    * @param oldValue old value of the field
    * @param newValue new value of the field
    */
    event OnStartOfPresaleSet(uint256 oldValue, uint256 newValue);

    /**
    * @param oldValue old value of the field
    * @param newValue new value of the field
    */
    event OnEndOfPresaleSet(uint256 oldValue, uint256 newValue);

    /**
    * @param oldValue old value of the field
    * @param newValue new value of the field
    */
    event OnStartOfCrowdsaleSet(uint256 oldValue, uint256 newValue);

    /**
    * @param oldValue old value of the field
    * @param newValue new value of the field
    */
    event OnEndOfCrowdsaleSet(uint256 oldValue, uint256 newValue);

    /**
    * @param token claimed token
    * @param owner who owns the contract
    * @param amount amount of the claimed token
    */
    event OnClaimTokens(address indexed token, address indexed owner, uint256 amount);

    /**
    * @param beneficiary who is the recipient of tokens from the contribution
    * @param weiAmount Amount of wei contributed 
    */
    event OnContributionCreated(address indexed beneficiary, uint256 weiAmount);
}
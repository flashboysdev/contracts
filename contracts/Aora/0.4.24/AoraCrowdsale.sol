// solium-disable linebreak-style
pragma solidity ^0.4.24;

import "./Whitelist.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

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
    * @dev Fallback function. Can't send ether to this contract. 
    */
    function () external payable {
        revert();
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

        uint newTokensSoldAmount = tokensSold.add(aoraTgeAmount);

        require(newTokensSoldAmount <= cap);

        tokensSold = newTokensSoldAmount;

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

        IERC20 tokenReference = IERC20(_token);
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
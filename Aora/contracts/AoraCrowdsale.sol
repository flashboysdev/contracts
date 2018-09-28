// solium-disable linebreak-style
pragma solidity ^0.4.24;

import "./Whitelist.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract AoraCrowdsale is Whitelist, Ownable {
    using SafeMath for uint256;

    // Token being sold
    IERC20 public token;

    // Start of presale timestamp in miliseconds
    uint public startOfPresale = 1538352000000; // October 1, 2018 12:00:00 AM

    // End of presale timestamp in miliseconds
    uint public endOfPresale = 1541030399000; // October 31, 2018 11:59:59 PM

    // Start of crowdsale timestamp in miliseconds
    uint public startOfCrowdsale = 1541030400000; // November 1, 2018 12:00:00 AM

    // End of crowdsale timestamp in miliseconds
    uint public endOfCrowdsale = 1543622399000; // November 30, 2018 11:59:59 PM

    // Maximum number of tokens that can be sold
    uint public cap = 250000000 ether;

    // Tokens sold so far
    uint public tokensSold = 0;

    // US Dollars raised so far in cents 
    uint public usdRaised = 0;

    // Deployment block of the contract 
    uint public deploymentBlock;

    // Tokens per US Dollar rate, fixed for this crowsale. Price of a token is 0.20$USD
    uint public tokensPerUsdRate = 5;

    // Factor that we multiply with to get whole tokens from cents 
    uint constant public centsToWholeTokenFactor = 10 ** 16; 

    /**
        @param _token Address of the token contract 
    */
    constructor(IERC20 _token) public addressNotZero(_token) {
        token = _token;

        deploymentBlock = block.number;
    }

    // Signifies weather or not the argument has any value 
    modifier hasValue(uint usdAmount) {
        require(usdAmount > 0, "You have to give us something, buddy.");
        _;
    }

    // Signifies weather or not crowdsale is over
    modifier crowdsaleNotOver() {
        require(isCrowdsale()); 
        _;
    }

    // Sets the start of presale
    function setStartOfPresale(uint _startOfPresale) external onlyOwner {
        emit OnStartOfPresaleSet(_startOfPresale, startOfPresale); 
        startOfPresale = _startOfPresale;
    }

    // Sets the end of presale
    function setEndOfPresale(uint _endOfPresale) external onlyOwner {
        emit OnEndOfPresaleSet(_endOfPresale, endOfPresale); 
        endOfPresale = _endOfPresale;
    }

    // Sets the start of crowdsale
    function setStartOfCrowdsale(uint _startOfCrowdsale) external onlyOwner {
        emit OnStartOfCrowdsaleSet(_startOfCrowdsale, startOfCrowdsale);
        startOfCrowdsale = _startOfCrowdsale;
    }

    // Sets the end of crowdsale
    function setEndOfCrowdsale(uint _endOfCrowdsale) external onlyOwner {
        emit OnEndOfCrowdsaleSet(_endOfCrowdsale, endOfCrowdsale);
        endOfCrowdsale = _endOfCrowdsale;
    }

    // Sets the cap
    function setCap(uint _cap) external onlyOwner { 
        emit OnCapSet(_cap, cap);
        cap = _cap;
    }

    // Setter for the tokensPerUsdRate 
    function setTokensPerUsdRate(uint _tokensPerUsdRate) external onlyOwner {
        emit OnTokensPerUsdRateSet(_tokensPerUsdRate, tokensPerUsdRate);
        tokensPerUsdRate = _tokensPerUsdRate;
    }

    // Returns weather or not the presale is over
    function isPresale() public view returns(bool) {
        return now < endOfPresale;
    }

    // Returns weather or not the crowdsale is over
    function isCrowdsale() public view returns(bool) {
        return now < endOfCrowdsale;
    }

    // Creates a contribution for the specified beneficiary, with the specified wei amount value
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

    // Create a bulk of contributions 
    // USDollar value of the each contribution in cents
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
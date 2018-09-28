# Aora smart contracts 
Collection of smart contracts for Aora<br />
Written in Solidity<br />
Base library - Open Zeppelin<br />

# Contract interactions 

Contracts:
- AoraCrowdsale
- AoraTgeCoin

In the future:
- AoraCoin
- Convert

#AoraCrowdsale 

AoraCrowdsale is contract for selling the tokens. 
AoraTgeCoin address is injected through the constructor. 
Owner calls createContribution(...) or createBulkContributions(...) functions. 

AoraCrowdsale tracks the amount of tokens sold and US Dollars raised in cents.
AoraCrowdsale transfers AORATGE to the beneficiary in createContribution(...) function.
Quantity of AORATGE per USD is specified in the tokensPerUsdRate state variable.

#AoraTgeCoin 

In constructor, total balance is awarded to the owner. 
transfer function is only callable by the owner and the AoraCrowdsale contracts.
AoraCrowdsale because it sells the tokens.
Owner because we need a way to send tokens to AoraCrowdsale and other addresses, for means specified by the Aora business model.
AoraCrowdsale contract address must be set by the owner. 

transferFrom(...) is only callable by the convert contract. 
transferFrom(...) always transfers to address 0x0, because we don't want to enable token recycling. 
Convert contract address must be set by the owner. 

#Convert 

Convert contract will be deployed in the future. 
Convert contract will be used to trade AORATGE for AORA in 1-1 ratio and enforce vesting rules, which will be specified in the future.

It will use AoraTgeCoin contract's function transferFrom(...) in own convert() function to transfer AORATGE to address 0x0, to eliminate the possibility of reentering. It will also call AoraCoin contracts transfer function to give the beneficiary their AORA. User will get the same amout of AORA as they lost in AORATGE. They will be exchanged in 1-1 ratio.

#AoraCoin

Contract will be deployed in the future. 
Contract will be a pure ERC20 contract. It is the only contract that is intended to be used indefinetely. 
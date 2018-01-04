pragma solidity ^0.4.18;


library SafeMath {
  function mul(uint a, uint b) internal constant returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint a, uint b) internal constant returns (uint) {
    uint c = a / b;
    return c;
  }
  function sub(uint a, uint b) internal constant returns (uint) {
    assert(b <= a);
    return a - b;
  }
  function add(uint a, uint b) internal constant returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}


contract Ownable {

  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  
  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
    }
}

contract ERC20 {

  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function transfer(address to, uint value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
  
  function allowance(address owner, address spender) public constant returns (uint);
  function transferFrom(address from, address to, uint value) public returns (bool);
  function approve(address spender, uint value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract StandardToken is ERC20, Ownable {

  using SafeMath for uint;



  event Mint(address _to, uint _amount);
  event Burn(address _from, uint _amount);
  event Lock(address _from, uint _amount);
  event LockClaimed(address _from, uint _amount);
  event Unlock(address _from, uint _amount);
  event Pause();
  event Unpause();

  struct Locked {
      uint lockedAmount;
      uint lastUpdated;
      uint lastClaimed;
  }
  
  bool public pauseTransfer = false;
  uint public constant MIN_LOCK_AMOUNT = 100000;   

  mapping (address => uint) balances;
  mapping (address => Locked) locked;
  mapping (address => mapping (address => uint)) internal allowed;
  
  /*
  * Don't accept ETH
  */
  function () public payable {
    revert();
  }

  function pause() public onlyOwner {
      pauseTransfer = true;
      Pause();
  }

  function unpause() public onlyOwner {
      pauseTransfer = false;
      Unpause();
  }

  function mint(address _to, uint _amount) public onlyOwner returns (bool) {
      require(_to != address(0));
      totalSupply = totalSupply.add(_amount);
      balances[_to] = balances[_to].add(_amount);
      Mint(_to, _amount);
      return true;
  } 


  function burn(address _from, uint _amount) internal {
      require(_from != address(0));
      balances[_from] = balances[_from].sub(_amount);
      totalSupply = totalSupply.sub(_amount);
      Burn(_from, _amount);
  }

  function lock(uint _amount) public returns (bool) {
      require(msg.sender != address(0));
      require(_amount >= MIN_LOCK_AMOUNT);
      require(balances[msg.sender].sub(_amount.add(locked[msg.sender].lockedAmount)) >= 0);
      _checkLock(msg.sender);
      locked[msg.sender].lockedAmount = locked[msg.sender].lockedAmount.add(_amount);
      locked[msg.sender].lastUpdated = now;
      Lock(msg.sender, _amount);
      return true;
  }

  function _checkLock(address _from) internal returns (bool) {
      if (locked[_from].lockedAmount != 0) {
        if (locked[_from].lastUpdated + 30 days >= now) {
            uint _value = locked[_from].lockedAmount.div(100);
            totalSupply = totalSupply.add(_value);
            balances[_from] = balances[_from].add(_value);
            locked[_from].lastClaimed = now;
            LockClaimed(_from, _value);
            return true;
        }
        return false;
      }
      return false;
  }

  function claimBonus() public returns (bool) {
      require(msg.sender != address(0));
      return _checkLock(msg.sender);
  }

  function unlock(uint _amount) public returns (bool) {
      require(msg.sender != address(0));
      require(locked[msg.sender].lockedAmount >= _amount);
      if (locked[msg.sender].lockedAmount.sub(_amount) < MIN_LOCK_AMOUNT) {
        balances[msg.sender] = balances[msg.sender].add(locked[msg.sender].lockedAmount);
        Unlock(msg.sender, locked[msg.sender].lockedAmount);
        locked[msg.sender].lockedAmount = 0;        
      } else {
        uint _value = locked[msg.sender].lockedAmount.sub(_amount);
        balances[msg.sender] = balances[msg.sender].add(_value);
        locked[msg.sender].lockedAmount = _value;
        Unlock(msg.sender, _value);
      }
      return true;
  }

  function _transfer(address _from, address _to, uint _value) internal {
    require(_to != address(0));
    require(balances[_from].sub(_value.add(locked[_from].lockedAmount)) >= 0);
    require(balances[_to].add(_value) >= balances[_to]);    
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(_from, _to, _value);
  }
  
  function transfer(address _to, uint _value) public returns (bool) {
    require(!pauseTransfer);
    _transfer(msg.sender, _to, _value);
    return true;
  }
  
  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }

  function transferFrom(address _from, address _to, uint _value) public returns (bool) {
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  
  // Owner can transfer out any accidentally sent ERC20 tokens  
  function transferAnyERC20Token(address tokenAddress, uint _amount) public onlyOwner returns (bool success) {
      return ERC20(tokenAddress).transfer(owner, _amount);
  }

}
contract WizzleInfinityToken is StandardToken {
    string public constant name = "Wizzle Infinity Token";
    string public constant symbol = "WZI";
    uint8 public constant decimals = 0;
    function WizzleInfinityToken() public { 
        totalSupply = 0;
    }
}
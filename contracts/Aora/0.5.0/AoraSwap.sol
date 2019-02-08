// solium-disable linebreak-style
pragma solidity ^0.5.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

contract AoraSwap is Ownable {
    using SafeMath for uint256;

    string public name = "AoraSwap";

    /**
     * Events which are related to lock-ups. 
     */
    mapping (string => bool) events;

    /**
     * Start time of each event. 
     */
    mapping (string => uint) eventsStartTime;

    mapping (address => LockUp[]) addressLockUps;

    string[] public eventNames;

    IERC20 public AoraTgeCoin;

    IERC20 public AoraCoin;

    struct LockUp {
        string eventName;
        uint tokenAmount;
        uint eventStartOffset;
        bool isClaimed;
    }

    constructor(address aoraTge, address aoraCoin) public {
        require(aoraTge != aoraCoin && aoraTge != address(0));
        AoraTgeCoin = IERC20(aoraTge);
        AoraCoin = IERC20(aoraCoin);
    }

    function setAoraTgeCoin(address aoraTgeCoin) public onlyOwner {
        require(aoraTgeCoin != address(0));
        AoraTgeCoin = IERC20(aoraTgeCoin);
    }

    function setAoraCoin(address aoraCoin) public onlyOwner {
        require(aoraCoin != address(0));
        AoraCoin = IERC20(aoraCoin);
    }

    function addEvent(string calldata eventName, uint startTime) external onlyOwner {
        require(!events[eventName], "Event already exists.");
        eventNames.push(eventName);
        events[eventName] = true;
        eventsStartTime[eventName] = startTime;
        emit EventAdded(eventName, startTime);
    }

    function changeEventStartTime(string calldata eventName, uint startTime) external onlyOwner {
        require(events[eventName], "Event doesn't exist.");
        emit EventStartTimeChanged(eventName, eventsStartTime[eventName], startTime);
        eventsStartTime[eventName] = startTime;
    }

    function addLockUpPeriods(
        address who, 
        uint[] memory amounts, 
        uint[] memory eventStartOffsets, 
        string memory eventName
        ) public onlyOwner {
        require(events[eventName], "Event doesn't exist.");
        require(amounts.length == eventStartOffsets.length, "Array lengths of amounts and eventStartOffsets are different.");
        LockUp[] storage lockups = addressLockUps[who];
        for (uint i = 0; i < amounts.length; i++)
            lockups.push(lockUpBuilder(eventName, amounts[i], eventStartOffsets[i]));
    } 

    function claimLockedUpTokens(address who) private {
        uint aoraTgeBalance = AoraTgeCoin.balanceOf(who);
        require(aoraTgeBalance > 0, "Aora TGE balance is 0.");
        
        LockUp[] storage lockups = addressLockUps[who];
        require(lockups.length > 0, "Required more than zero lockups.");
        uint claimAmount = 0;

        for (uint i = 0; i < lockups.length; i++) {
            LockUp storage lockup = lockups[i]; 
            if (!lockup.isClaimed 
            && lockup.eventStartOffset.add(eventsStartTime[lockup.eventName]) <= now) {
                lockup.isClaimed = true;
                claimAmount = claimAmount.add(lockup.tokenAmount);
                emit LockUpClaimed(who, lockup.eventName, lockup.tokenAmount);
            }
        }
        require(claimAmount != 0, "Claim amount is zero.");
        require(aoraTgeBalance >= claimAmount, "Not enough AORA TGE.");
        
        AoraTgeCoin.transferFrom(who, address(0), claimAmount);
        require(AoraCoin.balanceOf(address(this)) > 0, "BALANCE OF AORACOIN is ZERO");
        require(AoraCoin.balanceOf(address(this)) >= claimAmount, "NOT ENOUGH TOKENS TO SEND HERE");
        AoraCoin.transfer(who, claimAmount);
    }

    function userClaimLockedUpTokens() public {
        claimLockedUpTokens(msg.sender);        
    }

    function adminClaimLockedUpTokens(address who) public onlyOwner {
        claimLockedUpTokens(who);
    }

    function doesEventExist(string memory eventName) public view returns(bool) {
        return events[eventName];
    }

    function getEventStartTime(string memory eventName) public view returns(uint256) {
        return eventsStartTime[eventName];
    }

    function getLockedAmount(address who) external view returns(uint) {
        uint lockedAmount = 0;

        LockUp[] memory lockups = addressLockUps[who];
        
        uint i = 0;
        for (; i < lockups.length; i++) // NOTE: Possible optimization, uint length = lockups.length; 
            if (!lockups[i].isClaimed)
                lockedAmount = lockedAmount.add(lockups[i].tokenAmount);
        
        return lockedAmount;
    }

    function getLockedAmountForEvent(address who, string calldata eventName) external view returns(uint) {
        uint lockedAmount = 0;
        
        LockUp[] memory lockups = addressLockUps[who];
        for (uint i = 0; i < lockups.length; i++) 
            if (!lockups[i].isClaimed && compareStrings(lockups[i].eventName, eventName))
                lockedAmount = lockedAmount.add(lockups[i].tokenAmount);
        return lockedAmount;
    }

    function getTimeUntilNextClaim(address who) external view returns(uint) { 
        uint shortestTime = 2**256-1; // max uint256
        LockUp[] memory lockups = addressLockUps[who];
        for (uint i = 0; i < lockups.length; ++i) {
            if (!lockups[i].isClaimed) {
                if (now >= eventsStartTime[lockups[i].eventName].add(lockups[i].eventStartOffset))
                    return 0;
                uint currentLockupWaitTime = eventsStartTime[lockups[i].eventName].add(lockups[i].eventStartOffset).sub(now);
                if (shortestTime > currentLockupWaitTime)
                    shortestTime = currentLockupWaitTime;
            }
        }
        return shortestTime;
    }

    function getAddressEventIndices(address who) external view returns(uint[] memory) {
        uint[] memory indices = new uint[](eventNames.length);
        uint currentIndex = 0;
        LockUp[] memory lockups = addressLockUps[who];

        for (uint i = 0; i < lockups.length; i++) {
            for (uint j = 0; j < eventNames.length; j++)
                if (compareStrings(lockups[i].eventName, eventNames[j])) {
                    uint index = j;
                    uint k = 0;
                    while(indices[k] != index && k < currentIndex)
                        k++;
                    if (k > currentIndex || currentIndex == 0)
                        indices[currentIndex++] = index;
                }
        }

        uint[] memory temp = new uint[](currentIndex);
        for (uint i = currentIndex; i < indices.length; i++)
            temp[i] = indices[i];  

        return temp;
    }

    event EventAdded(string eventName, uint startTime);

    event EventStartTimeChanged(string eventName, uint oldStartTime, uint newStartTime);

    event LockUpClaimed(address who, string eventName, uint tokenAmount);

    function lockUpBuilder(string memory eventName, uint tokenAmount, uint eventStartOffset) internal view returns(LockUp memory) {
        require(events[eventName], "Event doesn't exist.");
        require(tokenAmount != 0, "Token amount is 0.");
        return LockUp({
            eventName: eventName,
            tokenAmount: tokenAmount,
            eventStartOffset: eventStartOffset,
            isClaimed: false
        });
    }

    function getNumberOfEvents() public view returns(uint) {
        return eventNames.length;
    }

    function compareStrings (string memory a, string memory b) internal pure returns (bool){
       return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}
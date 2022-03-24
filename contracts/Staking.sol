//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Staking is ERC20, Ownable {
    using SafeMath for uint256;
    uint256 public priceOfToken = 0.001 ether;
    uint256 public constant fixedTotalSupply = 1000000 * 10**18;
    address[] internal stakeholders;
    // mapping(address => uint256) internal rewards;
    struct stakeDetails {
        uint256 timeDueForStakeWithdrawal;
        uint256 amountStaked;
    }
    mapping(address => stakeDetails) internal stakes;

    constructor() ERC20("BlockgamesToken", "BGTK"){
        _mint(msg.sender, 1000* 10**18);
    }

    modifier onlyStakeHolders (){
        (bool _isStakeholder, ) = isStakeholder(msg.sender);
       require(_isStakeholder, "You are not a stakeholder");
        _;
    }

    function modifyTokenBuyPrice (uint256 _price) public onlyOwner {
        priceOfToken = _price * 10**18;
    }

    function buyToken (address receiver, uint256 _amount) public payable {
        uint256 _amountWithDecimals = _amount * 10**18;
        uint256 _cost = priceOfToken * _amount;
        require(receiver != address(0), "Invalid receiver address");
        require((totalSupply()+ _amountWithDecimals)<= fixedTotalSupply, "Maximum number of supply reached");
        require(_cost == msg.value, "Ether sent is incorrect");
        _mint(receiver, _amountWithDecimals);
    }

    function isStakeholder(address _address) public view returns(bool, uint256) {
       for (uint256 s = 0; s < stakeholders.length; s += 1){
           if (_address == stakeholders[s]) return (true, s);
       }
       return (false, 0);
   }

   function addStakeholder(address _stakeholder) public {
       (bool _isStakeholder, ) = isStakeholder(_stakeholder);
       if(!_isStakeholder) stakeholders.push(_stakeholder);
   }

   function removeStakeholder(address _stakeholder) public {
       (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
       if(_isStakeholder){
           stakeholders[s] = stakeholders[stakeholders.length - 1];
           stakeholders.pop();
       }
   }

   function stakeOf(address _stakeholder)public view returns(uint256) {
       return stakes[_stakeholder].amountStaked;
   }

   function createStake(uint256 _stake) public {
       require(_stake > 0, "Please input a value");
       uint256 _stakeWithDecimals = _stake * 10**18;
       require((totalSupply()+ (_stakeWithDecimals/100))<= fixedTotalSupply, "Not Available for staking");
       _burn(msg.sender, _stakeWithDecimals);
       if(stakes[msg.sender].amountStaked == 0) addStakeholder(msg.sender);
       stakes[msg.sender].amountStaked = stakes[msg.sender].amountStaked.add(_stakeWithDecimals);
       stakes[msg.sender].timeDueForStakeWithdrawal = block.timestamp + 7 days;
   }

   function removeStake(uint256 _stake) public onlyStakeHolders{
       require(_stake > 0, "Please input a value");
       uint256 _stakeWithDecimals = _stake * 10**18;
       require(_stakeWithDecimals == stakes[msg.sender].amountStaked, "Insufficient amount");
       stakes[msg.sender].amountStaked = stakes[msg.sender].amountStaked.sub(_stakeWithDecimals);
       stakes[msg.sender].timeDueForStakeWithdrawal = 0;
       if(stakes[msg.sender].amountStaked == 0) removeStakeholder(msg.sender);
       _mint(msg.sender, _stakeWithDecimals);
   }

   function claimReward () public payable onlyStakeHolders{
       require( block.timestamp > (stakes[msg.sender].timeDueForStakeWithdrawal), "Cannot claim reward until after a week");
        uint256 reward = stakes[msg.sender].amountStaked / 100;
        removeStake((stakes[msg.sender].amountStaked.div(1 *10**18)));
        _mint(msg.sender, reward);
   }
}
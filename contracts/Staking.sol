// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract Staking is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    IERC20Upgradeable public _stakingToken;
    
    uint128 private _idCounter;
    uint64 public _rewardRate;
    bool public _dynamicStakingEnabled;
    bool public _autoCompoundEnabled;

    struct StakingInfo {
        uint256 id;
        uint256 stakedAmount;
        uint256 stakingPeriod;
        uint256 startTime;
    }

    mapping(address => StakingInfo[]) private _userStakingInfo;

    modifier stakingPeriodEnded(uint256 _id) {

        if (!_dynamicStakingEnabled) {
            uint256 startTime = _userStakingInfo[_msgSender()][_id].startTime;
            uint256 stakingPeriod = _userStakingInfo[_msgSender()][_id]
                .stakingPeriod;
            uint256 timePassed = block.timestamp - startTime;

            require(
                timePassed >= stakingPeriod,
                "The current staking period has not ended"
            );
        }
        _;
    }

    modifier validId(uint256 id) {
        require(
            _userStakingInfo[_msgSender()][id].stakedAmount > 0,
            "Invalid id"
        );
        _;
    }

    modifier validAmount(uint256 amount) {
        require(amount > 0, "Amount must be greater than 0");
        _;
    }

    event Stake(
        address indexed user,
        uint256 indexed id,
        uint256 indexed stakedAmount,
        uint256 stakingPeriod,
        uint256 startTime
    );

    event Claim(
        address indexed user,
        uint256 indexed id,
        uint256 stakedAmount,
        uint256 indexed claimAmount,
        uint256 stakingPeriod,
        uint256 startTime,
        uint256 endTime
    );

    event UnStake(
        address indexed user,
        uint256 indexed id,
        uint256 stakedAmount,
        uint256 indexed unstakeAmount,
        uint256 stakingPeriod,
        uint256 startTime,
        uint256 endTime
    );

    /**
    * @notice initialize function for init contract
    * @param token token address of staking 
    * @param dynamicStaking true: dynamic, false: static
    * @param autoCompound true: autoCompound, false: non
    */
    function __Staking_init(
        address token,
        bool dynamicStaking,
        bool autoCompound,
        uint64 rewardRate
    ) public initializer {

        _dynamicStakingEnabled = dynamicStaking;
        _autoCompoundEnabled = autoCompound;
        _stakingToken = IERC20Upgradeable(token);
        _rewardRate = rewardRate;

        __Ownable_init();
        __UUPSUpgradeable_init();
    }
    
    function _authorizeUpgrade(address newImplementation)
        internal   
        override
        onlyOwner
    {}

    /**
    * @notice stake internal function
    * @param amount staking amount
    * @param stakingPeriod staking period as second
    */
    function _stake(uint256 amount, uint256 stakingPeriod) internal {
        
        uint256 counter = _idCounter;

        _stakingToken.safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        _userStakingInfo[msg.sender].push(
            StakingInfo(counter, amount, stakingPeriod, block.timestamp)
        );
        unchecked {
            ++_idCounter;
        }
        emit Stake(msg.sender, counter, amount, block.timestamp, stakingPeriod);
    }

    /**
    * @notice claim internal function
    * @param id index of the staking info
    * @param claimAmount amount for claim
    */
    function _claim(uint256 id, uint256 claimAmount) internal {

        StakingInfo storage stakingInfo = _userStakingInfo[msg.sender][id];
        uint256 claimableAmount = _claimableAmount(id, msg.sender);
        uint256 stakedAmount = stakingInfo.stakedAmount;
        uint256 stakingPeriod = stakingInfo.stakingPeriod;
        uint256 startTime = stakingInfo.startTime;

        require(
            claimAmount <= claimableAmount,
            "Claim amount exceeds the claimable amount"
        );

        if (claimAmount < claimableAmount && _autoCompoundEnabled) {
            uint256 tokenStakeAmount = claimableAmount - claimAmount;
            _stake(tokenStakeAmount, stakingPeriod);
        }

        delete _userStakingInfo[msg.sender][id];
        if (_autoCompoundEnabled)
            _stakingToken.safeTransfer(msg.sender, claimAmount);
        else
            _stakingToken.safeTransfer(msg.sender, claimableAmount);

        emit Claim(
            msg.sender,
            id,
            stakedAmount,
            claimableAmount,
            stakingPeriod,
            startTime,
            block.timestamp
        );        
    }

    /**
    * @notice unstake internal function
    * @param id index of the staking info
    */
    function _unstake(uint256 id) internal {
        StakingInfo storage stakingInfo = _userStakingInfo[msg.sender][id];
        uint256 claimableAmount = _claimableAmount(id, msg.sender);

        delete _userStakingInfo[msg.sender][id];
        _stakingToken.transfer(msg.sender, claimableAmount);

        emit UnStake(
            msg.sender,
            id,
            stakingInfo.stakedAmount,
            claimableAmount,
            stakingInfo.stakingPeriod,
            stakingInfo.startTime,
            block.timestamp
        );        
    } 

    /**
    * @return idCounter
    */
    function idCounter() public view virtual returns (uint256) {
        return _idCounter;
    }

    /**
    * @notice stake amount during staking period
    * @param amount staking amount
    * @param stakingPeriod staking period
    */
    function stake(
        uint256 amount,
        uint256 stakingPeriod
    ) public virtual validAmount(amount) {
        _stake(amount, stakingPeriod);
    }

    /**
    * @notice unstake amount
    * @param id staking info index
    */
    function unstake(
        uint256 id
    ) public virtual validId(id) stakingPeriodEnded(id) {
        _unstake(id);
    }

    /**
    * @notice claim
    * @param id staking info index
    * @param claimAmount amount for claim
    */
    function claim(
        uint256 id,
        uint256 claimAmount
    )
        public
        virtual
        validId(id)
        stakingPeriodEnded(id) 
    {
        _claim(id, claimAmount);
    }

    /**
    * @notice withdraw all amount only amdin
    */
    function adminWithdraw(uint256 amount) public virtual onlyOwner {
        _stakingToken.safeTransfer(msg.sender, amount);
    }

    /**
    * @return stakingInfo
    */
    function getUserStakingInfo(
        address user
    ) public view virtual returns (StakingInfo[] memory) {
        return _userStakingInfo[user];
    }

    /**
    * @notice calculate reward amount for id staking
    * @param id staking info index
    */
    function _claimableAmount(uint256 id, address user) public view returns (uint256) {

        StakingInfo storage stakingInfo = _userStakingInfo[user][id];

        uint256 timePassed = block.timestamp - stakingInfo.startTime;

        return stakingInfo.stakedAmount.add(
            timePassed.mul(
                _rewardRate
            )
        );
    }

    /***
    * @notice set reward rate
    * @param rewardRate rate value
    */
    function setRewardRate(
        uint64 rewardRate
    ) external onlyOwner {
        _rewardRate = rewardRate;
    } // in case of fixed staking, the rate can only set once. So after this call is done once should be disabled
    // for dynamic staking contract type, you have to pass two arrays une for utilization , the other for the rates
    // utilization and rates are directly correlated, since one is the inverse of the other
    //
    // You have to store an array of struct like this RateLevels {
    // utilization: uint256,
    // rate: uint256
    //}
    //
    // so to each utilization is assigned a rate.
    // You have to use these "levels" because interactions with contract willmodify the actual utilization but you trigger the rate change only when the
    // actual utilization value goes out of its range and falls in another range. This event will trigger the dynamic rate shift (increase or decrease, if utilization decreases or increases respectively)
    //
    // To set these arrays, the only ones allowed to execute the function must be the Owner AND any Relay providing a valid EIP-712 signature signed by the Owner, for this specific function call. Please see documentation for that
    // here https://eips.ethereum.org/EIPS/eip-712
    //
    // You have to follow the rules of economy where utilization = Demand / Supply . 
    // in your case :
    // Demand = Total Tokens Staked
    // Supply = Total Tokens available as Reward
    //
    // You have to setup a Vault where you hold the reward tokens, and from which you harvest rewards to assign to the claimer
    // 
    // at each action stake/unstake/claim and so on , you calculate the rewards due to the msg.sender
    // extract that amount from the Vault and assign to the msg.sender's balance . (The balance where you assign the tokens is the stakingBalance if itAutoCompounds == true, if not you account the rewards in a separated balance and allow to claim from that balance)
    //
    // Of course this operation , along with the increase/decrease of staked tokens influences the utilization (if falls outside his working range, the rate will change)
    //
    // You have to update the rate at each reward harvesed and at each staked balance update events

    // Also in dynamic staking, you have to take in account that the rewards gained from a staked balance depend on the fluctuations of the APY _rewardRate
    // this means you have keep track of the latest balance update , along with the timestamp you updated the balance and the latest APY rate index picked up from the historyOfRate (you have to create that variable and update it)
    // so when you go to calculate the rewards you have the stakingBalance that remained stable (not changed) but the rates changed so you have to multiply each rate * dT where dT is the time that rate lasted

    // Extra bonus 
    // At moment of Vault topup (or withdraw tokens) you save the timestamp of that action. Then.
    // At each stake event you should check if the amount of Rewards Tokens in Vault is going to be able to cover the amount of unmaterializedRewards since that moment (rewards that have been virtually matured by all other users except msg.sender but not yet claimed) + the expected generated rewards at the (newly) calculated rate
}

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
    }
}
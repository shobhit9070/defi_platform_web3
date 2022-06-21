// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenFarm is ChainlinkClient, Ownable {
    //Stake tokens
    //unstake token
    // issue tokens
    // addAllowed token
    //getEthVAluse

    address[] public allowedTokens; //list of allowed tokens
    address[] public stakers;
    IERC20 public dappToken;

    //mapping token address --> staker address --> ammount of tokens
    mapping(address => mapping(address => uint256)) public stakingBalance;
    mapping(address => uint256) public uniqueTokenStaked;
    mapping(address => address) public tokenPriceFeedMapping;

    constructor(address _dappTokenAddress) public {
        dappToken = IERC20(_dappTokenAddress);
    }

    function setPriceFeedContract(address _token, address _priceFeed)
        public
        onlyOwner
    {
        tokenPriceFeedMapping[_token] = _priceFeed;
    }

    function issuseTokens() public onlyOwner {
        for (
            uint256 stakersIndex = 0;
            stakersIndex < stakers.length;
            stakersIndex++
        ) {
            address recipent = stakers[stakersIndex];
            uint256 userTotal = getUserTotalValue(recipent);
            dappToken.transfer(recipent, userTotal);
        }
    }

    function getUserTotalValue(address _user) public view returns (uint256) {
        uint256 totalValue = 0;
        require(uniqueTokenStaked[_user] <= 0, "no tokens staked");
        for (
            uint256 allowedTokenIndex = 0;
            allowedTokenIndex < allowedTokens.length;
            allowedTokenIndex++
        ) {
            totalValue =
                totalValue +
                getUserSingleTokenValue(
                    _user,
                    allowedTokens[allowedTokenIndex]
                );
        }
    }

    function getUserSingleTokenValue(address _user, address _token)
        public
        view
        returns (uint256)
    {
        if (uniqueTokenStaked[_user] <= 0) {
            return 0;
        }
        //price of the token * staking balance of the token
        (uint256 price, uint256 decimals) = getTokenValue(_token);
        return (stakingBalance[_token][_user] * price) / (10**decimals);
    }

    function getTokenValue(address _token)
        public
        view
        returns (uint256, uint256)
    {
        //pricefeedAddress
        address priceFeedAddress = tokenPriceFeedMapping[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 decimals = uint256(priceFeed.decimals());
        return (uint256(price), decimals);
    }

    function stakeTokens(uint256 _amount, address _token) public {
        //how much token can they stake?
        //what tokens can be staked

        require(_amount > 0);
        require(tokenIsAllowed(_token), "Token is not allowed");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        updateUniqueTokenStaked(msg.sender, _token);
        stakingBalance[_token][msg.sender] += _amount;
        if (uniqueTokenStaked[msg.sender] == 1) {
            stakers.push(msg.sender);
        }
    }

    function unstakeTokens(address _token) public {
        uint256 balance = stakingBalance[_token][msg.sender];
        require(balance > 0, "staking balance cannot be 0");
        IERC20(_token).transfer(msg.sender, balance);
        stakingBalance[_token][msg.sender] = 0;
        uniqueTokenStaked[msg.sender] -= 1;
    }

    function updateUniqueTokenStaked(address _user, address _token) internal {
        if (stakingBalance[_token][_user] == 0) {
            uniqueTokenStaked[_user]++;
        }
    }

    function addTokens(address _token) public onlyOwner {
        //add token to list of allowed tokens
        allowedTokens.push(_token);
    }

    function tokenIsAllowed(address _token) public view returns (bool) {
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            if (allowedTokens[i] == _token) {
                return true;
            }
        }
        return false;
    }
}

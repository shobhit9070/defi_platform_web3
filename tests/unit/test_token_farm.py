# arrange
# act
# assert

from brownie import accounts, network, TokenFarm, DappToken
import pytest
from scripts.helpul_scripts import (
    get_account,
    LOCAL_BLOCKCHAIN_ENVIRONMENTS,
    get_contract,
)
from scripts.deploy_script import deploy_token_farm_and_dapp_token


def test_set_price_feed_contract():
    # arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("only for development")
    account = get_account()
    non_owner = get_account(index=1)
    token_farm, dapp_token = deploy_token_farm_and_dapp_token()

    # act

    price_feed_address = get_contract("eth_usd_price_feed")
    token_farm.setPriceFeedContract(
        dapp_token.address, price_feed_address, {"from": account}
    )

    # assert
    assert token_farm.tokenPriceFeedMapping(dapp_token.address) == price_feed_address


def test_stake_tokens(amount_staked):
    # Arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing")
    account = get_account()
    token_farm, dapp_token = deploy_token_farm_and_dapp_token()
    # Act
    dapp_token.approve(token_farm.address, amount_staked, {"from": account})
    token_farm.stakeTokens(amount_staked, dapp_token.address, {"from": account})
    # Assert
    assert (
        token_farm.stakingBalance(dapp_token.address, account.address) == amount_staked
    )
    assert token_farm.uniqueTokenStaked(account.address) == 1
    assert token_farm.stakers(0) == account.address
    return token_farm, dapp_token

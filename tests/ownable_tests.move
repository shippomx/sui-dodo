#[test_only]
module haedal_pmm::ownable_tests;

use sui::test_scenario;

use haedal_pmm::ownable::{Self};
use haedal_pmm::usdc::USDC;
use haedal_pmm::sui::SUI;

#[test]
public fun test_grant_admin_cap() {
    let admin = @0xAA;
    let mut scenario_value = test_scenario::begin(admin);
    let scenario = &mut scenario_value;

    t_grant_admin_cap(scenario.ctx());

    test_scenario::end(scenario_value);
}

#[test_only]
public fun t_grant_admin_cap(ctx: &mut TxContext) {
    ownable::grant_admin_cap(ctx.sender(), ctx);
}

#[test]
public fun test_grant_pool_admin_cap() {
    let admin = @0xAA;
    let mut scenario_value = test_scenario::begin(admin);
    let scenario = &mut scenario_value;

    // t_grant_admin_cap(ctx);
    t_grant_pool_admin_cap<SUI, USDC>(scenario.ctx());

    test_scenario::end(scenario_value);
}

#[test_only]
public fun t_grant_pool_admin_cap<CoinTypeBase, CoinTypeQuote>(ctx: &mut TxContext) {
    ownable::grant_pool_admin_cap<CoinTypeBase, CoinTypeQuote>(ctx.sender(), ctx);
}

#[test]
public fun test_grant_liquidity_operator_cap() {
    let admin = @0xAA;
    let mut scenario_value = test_scenario::begin(admin);
    let scenario = &mut scenario_value;

    t_grant_liquidity_operator_cap<SUI, USDC>(scenario.ctx());

    test_scenario::end(scenario_value);
}

#[test_only]
public fun t_grant_liquidity_operator_cap<CoinTypeBase, CoinTypeQuote>(ctx: &mut TxContext) {
    ownable::grant_liquidity_operator_cap<CoinTypeBase, CoinTypeQuote>(ctx.sender(), ctx);
}
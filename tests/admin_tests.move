#[test_only]
module haedal_pmm::admin_tests;

// use std::debug::print;
use sui::test_scenario;

use haedal_pmm::admin;
use haedal_pmm::ownable::{AdminCap, PoolAdminCap, LiquidityOperatorCap};
use haedal_pmm::oracle_driven_pool_tests;

use haedal_pmm::usdc::USDC;
use haedal_pmm::sui::SUI;

#[test]
public fun test_grant_pool_admin_cap() {
    
    let admin = @0xAA;
    let pool_admin = @0xbb;

    let mut scenario_value = test_scenario::begin(admin);
    let scenario = &mut scenario_value;

    let (admin_cap, pool_admin_cap) = t_grant_pool_admin_cap<SUI,USDC>(scenario, pool_admin);

    test_scenario::return_to_address(admin, admin_cap);
    test_scenario::return_to_address(pool_admin, pool_admin_cap);
    
    test_scenario::end(scenario_value);

}

#[test]
public fun test_grant_liquidity_operator_cap() {
    let admin = @0xAA;
    let pool_admin = @0xbb;
    let liquidity_operator = @0xcc;
    let mut scenario_value = test_scenario::begin(admin);
    let scenario = &mut scenario_value;

    let (admin_cap, pool_admin_cap, liquidity_operator_cap) = t_grant_liquidity_operator_cap<SUI,USDC>(scenario, pool_admin, liquidity_operator);

    test_scenario::return_to_address(admin, admin_cap);
    test_scenario::return_to_address(pool_admin, pool_admin_cap);
    test_scenario::return_to_address(liquidity_operator, liquidity_operator_cap);

    test_scenario::end(scenario_value);
}

#[test]
public fun test_set_pool_config() {
    let admin = @0xAA;
    let pool_admin = @0xbb;

    let mut scenario_value = test_scenario::begin(admin);
    let scenario = &mut scenario_value;

    let (mut admin_cap, pool_admin_cap) = t_grant_pool_admin_cap<SUI,USDC>(scenario, pool_admin);

    let mut pool = oracle_driven_pool_tests::t_new_pool<SUI,USDC>(scenario, &mut admin_cap);

    test_scenario::next_tx(scenario, pool_admin);
    let new_liquidity_provider_fee_rate = 4_000_000;
    let new_protocol_fee_rate = 44_000_000;
    let new_k = 20_000_000;
    
    let new_balance_limit = 18446744073709551615u64 - 1;

    admin::set_liquidity_provider_fee_rate<SUI,USDC>(&pool_admin_cap, &mut pool, new_liquidity_provider_fee_rate, scenario.ctx());
    admin::set_protocol_fee_rate<SUI,USDC>(&pool_admin_cap, &mut pool, new_protocol_fee_rate, scenario.ctx());
    admin::set_k<SUI,USDC>(&pool_admin_cap, &mut pool, new_k, scenario.ctx());
    admin::set_base_balance_limit<SUI,USDC>(&pool_admin_cap, &mut pool, new_balance_limit);
    admin::set_quote_balance_limit<SUI,USDC>(&pool_admin_cap, &mut pool, new_balance_limit);

    test_scenario::next_tx(scenario, pool_admin);

    let (lp_fee_rate, protocol_fee_rate) = pool.get_fee_rate();
    let (base_balance_limit, quote_balance_limit) = pool.get_balance_limit();

    assert!(lp_fee_rate == new_liquidity_provider_fee_rate, 0);
    assert!(protocol_fee_rate == new_protocol_fee_rate, 1);
    assert!(new_k == pool.get_k(), 2);
    assert!(new_balance_limit == base_balance_limit, 3);
    assert!(new_balance_limit == quote_balance_limit, 4);

    test_scenario::return_to_address(admin, admin_cap);
    test_scenario::return_to_address(pool_admin, pool_admin_cap);
    test_scenario::return_shared(pool);

    test_scenario::end(scenario_value);
}

#[test]
#[expected_failure]
public fun test_pool_disable_trading() {
    let admin = @0xAA;
    let pool_admin = @0xbb;

    let mut scenario_value = test_scenario::begin(admin);
    let scenario = &mut scenario_value;

    let (mut admin_cap, pool_admin_cap) = t_grant_pool_admin_cap<SUI,USDC>(scenario, pool_admin);

    let mut pool = oracle_driven_pool_tests::t_new_pool<SUI,USDC>(scenario, &mut admin_cap);

    test_scenario::next_tx(scenario, pool_admin);
    
    admin::disable_trading<SUI,USDC>(&pool_admin_cap, &mut pool);
    pool.assert_trade_allowed();

    test_scenario::return_to_address(admin, admin_cap);
    test_scenario::return_to_address(pool_admin, pool_admin_cap);
    test_scenario::return_shared(pool);

    test_scenario::end(scenario_value);
}

#[test]
public fun test_pool_enable_trading() {
    let admin = @0xAA;
    let pool_admin = @0xbb;

    let mut scenario_value = test_scenario::begin(admin);
    let scenario = &mut scenario_value;

    let (mut admin_cap, pool_admin_cap) = t_grant_pool_admin_cap<SUI,USDC>(scenario, pool_admin);

    let mut pool = oracle_driven_pool_tests::t_new_pool<SUI,USDC>(scenario, &mut admin_cap);

    
    test_scenario::next_tx(scenario, pool_admin);
    admin::disable_trading<SUI,USDC>(&pool_admin_cap, &mut pool);

    test_scenario::next_tx(scenario, pool_admin);
    admin::enable_trading<SUI,USDC>(&pool_admin_cap, &mut pool);

    test_scenario::next_tx(scenario, pool_admin);
    pool.assert_trade_allowed();

    test_scenario::return_to_address(admin, admin_cap);
    test_scenario::return_to_address(pool_admin, pool_admin_cap);
    test_scenario::return_shared(pool);

    test_scenario::end(scenario_value);
}


#[test]
#[expected_failure]
public fun test_pool_disable_buying() {
    let admin = @0xAA;
    let pool_admin = @0xbb;

    let mut scenario_value = test_scenario::begin(admin);
    let scenario = &mut scenario_value;

    let (mut admin_cap, pool_admin_cap) = t_grant_pool_admin_cap<SUI,USDC>(scenario, pool_admin);

    let mut pool = oracle_driven_pool_tests::t_new_pool<SUI,USDC>(scenario, &mut admin_cap);

    test_scenario::next_tx(scenario, pool_admin);
    
    admin::disable_buying<SUI,USDC>(&pool_admin_cap, &mut pool);
    pool.assert_buying_allowed();

    test_scenario::return_to_address(admin, admin_cap);
    test_scenario::return_to_address(pool_admin, pool_admin_cap);
    test_scenario::return_shared(pool);

    test_scenario::end(scenario_value);
}

#[test]
public fun test_pool_enable_buying() {
    let admin = @0xAA;
    let pool_admin = @0xbb;

    let mut scenario_value = test_scenario::begin(admin);
    let scenario = &mut scenario_value;

    let (mut admin_cap, pool_admin_cap) = t_grant_pool_admin_cap<SUI,USDC>(scenario, pool_admin);

    let mut pool = oracle_driven_pool_tests::t_new_pool<SUI,USDC>(scenario, &mut admin_cap);

    
    test_scenario::next_tx(scenario, pool_admin);
    admin::disable_buying<SUI,USDC>(&pool_admin_cap, &mut pool);

    test_scenario::next_tx(scenario, pool_admin);
    admin::enable_buying<SUI,USDC>(&pool_admin_cap, &mut pool);
    
    test_scenario::next_tx(scenario, pool_admin);
    pool.assert_buying_allowed();

    test_scenario::return_to_address(admin, admin_cap);
    test_scenario::return_to_address(pool_admin, pool_admin_cap);
    test_scenario::return_shared(pool);

    test_scenario::end(scenario_value);
}

#[test]
#[expected_failure]
public fun test_pool_disable_selling() {
    let admin = @0xAA;
    let pool_admin = @0xbb;

    let mut scenario_value = test_scenario::begin(admin);
    let scenario = &mut scenario_value;

    let (mut admin_cap, pool_admin_cap) = t_grant_pool_admin_cap<SUI,USDC>(scenario, pool_admin);

    let mut pool = oracle_driven_pool_tests::t_new_pool<SUI,USDC>(scenario, &mut admin_cap);

    test_scenario::next_tx(scenario, pool_admin);
    
    admin::disable_selling<SUI,USDC>(&pool_admin_cap, &mut pool);
    pool.assert_selling_allowed();

    test_scenario::return_to_address(admin, admin_cap);
    test_scenario::return_to_address(pool_admin, pool_admin_cap);
    test_scenario::return_shared(pool);

    test_scenario::end(scenario_value);
}

#[test]
public fun test_pool_enable_selling() {
    let admin = @0xAA;
    let pool_admin = @0xbb;

    let mut scenario_value = test_scenario::begin(admin);
    let scenario = &mut scenario_value;

    let (mut admin_cap, pool_admin_cap) = t_grant_pool_admin_cap<SUI,USDC>(scenario, pool_admin);

    let mut pool = oracle_driven_pool_tests::t_new_pool<SUI,USDC>(scenario, &mut admin_cap);

    
    test_scenario::next_tx(scenario, pool_admin);
    admin::disable_selling<SUI,USDC>(&pool_admin_cap, &mut pool);

    test_scenario::next_tx(scenario, pool_admin);
    admin::enable_selling<SUI,USDC>(&pool_admin_cap, &mut pool);
    
    test_scenario::next_tx(scenario, pool_admin);
    pool.assert_selling_allowed();

    test_scenario::return_to_address(admin, admin_cap);
    test_scenario::return_to_address(pool_admin, pool_admin_cap);
    test_scenario::return_shared(pool);

    test_scenario::end(scenario_value);
}

#[test]
#[expected_failure]
public fun test_pool_disable_deposit_base() {
    let admin = @0xAA;
    let pool_admin = @0xbb;

    let mut scenario_value = test_scenario::begin(admin);
    let scenario = &mut scenario_value;

    let (mut admin_cap, pool_admin_cap) = t_grant_pool_admin_cap<SUI,USDC>(scenario, pool_admin);

    let mut pool = oracle_driven_pool_tests::t_new_pool<SUI,USDC>(scenario, &mut admin_cap);

    test_scenario::next_tx(scenario, pool_admin);
    
    admin::disable_deposit_base<SUI,USDC>(&pool_admin_cap, &mut pool);
    pool.assert_deposit_base_allowed();

    test_scenario::return_to_address(admin, admin_cap);
    test_scenario::return_to_address(pool_admin, pool_admin_cap);
    test_scenario::return_shared(pool);

    test_scenario::end(scenario_value);
}

#[test]
public fun test_pool_enable_deposit_base() {
    let admin = @0xAA;
    let pool_admin = @0xbb;

    let mut scenario_value = test_scenario::begin(admin);
    let scenario = &mut scenario_value;

    let (mut admin_cap, pool_admin_cap) = t_grant_pool_admin_cap<SUI,USDC>(scenario, pool_admin);

    let mut pool = oracle_driven_pool_tests::t_new_pool<SUI,USDC>(scenario, &mut admin_cap);

    
    test_scenario::next_tx(scenario, pool_admin);
    admin::disable_deposit_base<SUI,USDC>(&pool_admin_cap, &mut pool);

    test_scenario::next_tx(scenario, pool_admin);
    admin::enable_deposit_base<SUI,USDC>(&pool_admin_cap, &mut pool);
    
    test_scenario::next_tx(scenario, pool_admin);
    pool.assert_deposit_base_allowed();

    test_scenario::return_to_address(admin, admin_cap);
    test_scenario::return_to_address(pool_admin, pool_admin_cap);
    test_scenario::return_shared(pool);

    test_scenario::end(scenario_value);
}

#[test]
#[expected_failure]
public fun test_pool_disable_deposit_quote() {
    let admin = @0xAA;
    let pool_admin = @0xbb;

    let mut scenario_value = test_scenario::begin(admin);
    let scenario = &mut scenario_value;

    let (mut admin_cap, pool_admin_cap) = t_grant_pool_admin_cap<SUI,USDC>(scenario, pool_admin);

    let mut pool = oracle_driven_pool_tests::t_new_pool<SUI,USDC>(scenario, &mut admin_cap);

    test_scenario::next_tx(scenario, pool_admin);
    
    admin::disable_deposit_quote<SUI,USDC>(&pool_admin_cap, &mut pool);
    pool.assert_deposit_quote_allowed();

    test_scenario::return_to_address(admin, admin_cap);
    test_scenario::return_to_address(pool_admin, pool_admin_cap);
    test_scenario::return_shared(pool);

    test_scenario::end(scenario_value);
}

#[test]
public fun test_pool_enable_deposit_quote() {
    let admin = @0xAA;
    let pool_admin = @0xbb;

    let mut scenario_value = test_scenario::begin(admin);
    let scenario = &mut scenario_value;

    let (mut admin_cap, pool_admin_cap) = t_grant_pool_admin_cap<SUI,USDC>(scenario, pool_admin);

    let mut pool = oracle_driven_pool_tests::t_new_pool<SUI,USDC>(scenario, &mut admin_cap);

    
    test_scenario::next_tx(scenario, pool_admin);
    admin::disable_deposit_quote<SUI,USDC>(&pool_admin_cap, &mut pool);

    test_scenario::next_tx(scenario, pool_admin);
    admin::enable_deposit_quote<SUI,USDC>(&pool_admin_cap, &mut pool);
    
    test_scenario::next_tx(scenario, pool_admin);
    pool.assert_deposit_quote_allowed();

    test_scenario::return_to_address(admin, admin_cap);
    test_scenario::return_to_address(pool_admin, pool_admin_cap);
    test_scenario::return_shared(pool);

    test_scenario::end(scenario_value);
}

#[test_only]
public fun t_grant_pool_admin_cap<CoinTypeBase, CoinTypeQuote>(scenario: &mut test_scenario::Scenario, pool_admin: address):(AdminCap, PoolAdminCap<CoinTypeBase, CoinTypeQuote>) {
    let admin_cap = oracle_driven_pool_tests::t_pool_init(scenario);

    test_scenario::next_tx(scenario, pool_admin);

    admin::grant_pool_admin_cap<CoinTypeBase, CoinTypeQuote>(&admin_cap, pool_admin, scenario.ctx());
    test_scenario::next_tx(scenario, pool_admin);

    let pool_admin_cap = test_scenario::take_from_address<PoolAdminCap<CoinTypeBase, CoinTypeQuote>>(scenario,pool_admin);

    (admin_cap, pool_admin_cap)
}

#[test_only]
public fun t_grant_liquidity_operator_cap<CoinTypeBase, CoinTypeQuote>(scenario: &mut test_scenario::Scenario, pool_admin: address, liquidity_operator: address):(AdminCap, PoolAdminCap<CoinTypeBase, CoinTypeQuote>, LiquidityOperatorCap<CoinTypeBase, CoinTypeQuote>) {
    let (admin_cap, pool_admin_cap) = t_grant_pool_admin_cap<CoinTypeBase, CoinTypeQuote>(scenario, pool_admin);

    test_scenario::next_tx(scenario, pool_admin);
    admin::grant_liquidity_operator_cap<CoinTypeBase, CoinTypeQuote>(&pool_admin_cap, liquidity_operator, scenario.ctx());

    test_scenario::next_tx(scenario, pool_admin);
    let liquidity_operator_cap = test_scenario::take_from_address<LiquidityOperatorCap<CoinTypeBase, CoinTypeQuote>>(scenario,liquidity_operator);

    (admin_cap, pool_admin_cap,liquidity_operator_cap)
}
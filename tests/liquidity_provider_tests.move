#[test_only]
module haedal_pmm::liquidity_provider_tests;

use sui::coin;
use sui::test_scenario;

use haedal_pmm::liquidity_provider;
use haedal_pmm::oracle_driven_pool::{BasePoolLiquidityCoin, QuotePoolLiquidityCoin};

use haedal_pmm::oracle_driven_pool_tests;

use haedal_pmm::usdc::USDC;
use haedal_pmm::sui::SUI;

#[test]
fun test_deposit_base_internal() {

    let admin = @0xAA;

    let mut scenario_value = test_scenario::begin(admin);
    let scenario = &mut scenario_value;

    let mut admin_cap = oracle_driven_pool_tests::t_pool_init(scenario);

    let mut pool = oracle_driven_pool_tests::t_new_pool<SUI,USDC>(scenario, &mut admin_cap);

    let mint_amount = 1_000_000_000_000;
    let deposit_amount = 1_000_000_000;

    let base_coin = coin::mint_for_testing(mint_amount, scenario.ctx());
    let i = 1_500_000_000;
    // std::debug::print(&pool.get_price_id());
    liquidity_provider::t_deposit_base_internal<SUI, USDC>(&mut pool, base_coin, i, deposit_amount, scenario.ctx());

    assert!(pool.get_base_capital_coin_supply() == deposit_amount, 0);
    assert!(pool.get_quote_capital_coin_supply() == 0, 0);

    test_scenario::next_tx(scenario, admin);

    let sui_coin = test_scenario::take_from_address<coin::Coin<SUI>>(scenario,scenario.sender());
    let capital_coin = test_scenario::take_from_address<coin::Coin<BasePoolLiquidityCoin<SUI, USDC>>>(scenario,scenario.sender());

    assert!(sui_coin.value() == mint_amount - deposit_amount, 0);
    assert!(capital_coin.value() == deposit_amount, 0);


    test_scenario::return_to_address(admin, admin_cap);
    test_scenario::return_to_address(admin, sui_coin);
    test_scenario::return_to_address(admin, capital_coin);
    test_scenario::return_shared(pool);
    
    test_scenario::end(scenario_value);
}

#[test]
fun test_deposit_quote_internal() {

    let admin = @0xAA;

    let mut scenario_value = test_scenario::begin(admin);
    let scenario = &mut scenario_value;

    let mut admin_cap = oracle_driven_pool_tests::t_pool_init(scenario);

    let mut pool = oracle_driven_pool_tests::t_new_pool<SUI,USDC>(scenario, &mut admin_cap);

    let mint_amount = 1_000_000_000_000;
    let deposit_amount = 1_000_000_000;

    let quote_coin = coin::mint_for_testing(mint_amount, scenario.ctx());
    let i = 1_500_000_000;
    
    liquidity_provider::t_deposit_quote_internal<SUI, USDC>(&mut pool, quote_coin, i, deposit_amount, scenario.ctx());

    assert!(pool.get_base_capital_coin_supply() == 0, 0);
    assert!(pool.get_quote_capital_coin_supply() == deposit_amount, 0);

    test_scenario::next_tx(scenario, admin);

    let usdc_coin = test_scenario::take_from_address<coin::Coin<USDC>>(scenario,scenario.sender());
    let capital_coin = test_scenario::take_from_address<coin::Coin<QuotePoolLiquidityCoin<SUI, USDC>>>(scenario,scenario.sender());

    assert!(usdc_coin.value() == mint_amount - deposit_amount, 0);
    assert!(capital_coin.value() == deposit_amount, 0);


    test_scenario::return_to_address(admin, admin_cap);
    test_scenario::return_to_address(admin, usdc_coin);
    test_scenario::return_to_address(admin, capital_coin);
    test_scenario::return_shared(pool);
    
    test_scenario::end(scenario_value);
}


#[test]
fun test_withdraw_base_internal() {

    let admin = @0xAA;

    let mut scenario_value = test_scenario::begin(admin);
    let scenario = &mut scenario_value;

    let mut admin_cap = oracle_driven_pool_tests::t_pool_init(scenario);

    let mut pool = oracle_driven_pool_tests::t_new_pool<SUI,USDC>(scenario, &mut admin_cap);

    let mint_amount = 1_000_000_000_000;
    let deposit_amount = 1_000_000_000;

    let base_coin = coin::mint_for_testing(mint_amount, scenario.ctx());
    let i = 1_500_000_000;
    
    liquidity_provider::t_deposit_base_internal<SUI, USDC>(&mut pool, base_coin, i, deposit_amount, scenario.ctx());


    test_scenario::next_tx(scenario, admin);
    let capital_coin = test_scenario::take_from_address<coin::Coin<BasePoolLiquidityCoin<SUI, USDC>>>(scenario,scenario.sender());
    let withdraw_amount = 400_000_000;

    liquidity_provider::t_withdraw_base_internal(&mut pool, capital_coin, i, withdraw_amount, scenario.ctx());
    test_scenario::next_tx(scenario, admin);

    let capital_coin = test_scenario::take_from_address<coin::Coin<BasePoolLiquidityCoin<SUI, USDC>>>(scenario,scenario.sender());

    assert!(capital_coin.value() == deposit_amount - withdraw_amount, 0);

    test_scenario::return_to_address(admin, admin_cap);
    test_scenario::return_to_address(admin, capital_coin);
    test_scenario::return_shared(pool);
    
    test_scenario::end(scenario_value);
}


#[test]
fun test_withdraw_quote_internal() {

    let admin = @0xAA;

    let mut scenario_value = test_scenario::begin(admin);
    let scenario = &mut scenario_value;

    let mut admin_cap = oracle_driven_pool_tests::t_pool_init(scenario);

    let mut pool = oracle_driven_pool_tests::t_new_pool<SUI,USDC>(scenario, &mut admin_cap);

    let mint_amount = 1_000_000_000_000;
    let deposit_amount = 1_000_000_000;

    let quote_coin = coin::mint_for_testing(mint_amount, scenario.ctx());
    let i = 1_500_000_000;
    
    liquidity_provider::t_deposit_quote_internal<SUI, USDC>(&mut pool, quote_coin, i, deposit_amount, scenario.ctx());

    test_scenario::next_tx(scenario, admin);
    
    let capital_coin = test_scenario::take_from_address<coin::Coin<QuotePoolLiquidityCoin<SUI, USDC>>>(scenario,scenario.sender());

    let withdraw_amount = 400_000_000;

    liquidity_provider::t_withdraw_quote_internal(&mut pool, capital_coin, i, withdraw_amount, scenario.ctx());
    test_scenario::next_tx(scenario, admin);

    let capital_coin = test_scenario::take_from_address<coin::Coin<QuotePoolLiquidityCoin<SUI, USDC>>>(scenario,scenario.sender());
    let usdc_coin = test_scenario::take_from_address<coin::Coin<USDC>>(scenario,scenario.sender());

    assert!(capital_coin.value() == deposit_amount - withdraw_amount, 0);
    assert!(usdc_coin.value() == withdraw_amount, 0);

    test_scenario::return_to_address(admin, admin_cap);
    test_scenario::return_to_address(admin, capital_coin);
    test_scenario::return_to_address(admin, usdc_coin);
    test_scenario::return_shared(pool);
    
    test_scenario::end(scenario_value);
}

#[test]
fun test_withdraw_all_base_internal() {

    let admin = @0xAA;

    let mut scenario_value = test_scenario::begin(admin);
    let scenario = &mut scenario_value;

    let mut admin_cap = oracle_driven_pool_tests::t_pool_init(scenario);

    let mut pool = oracle_driven_pool_tests::t_new_pool<SUI,USDC>(scenario, &mut admin_cap);

    let mint_amount = 1_000_000_000_000;
    let deposit_amount = 1_000_000_000;

    let base_coin = coin::mint_for_testing(mint_amount, scenario.ctx());
    let i = 1_500_000_000;
    
    liquidity_provider::t_deposit_base_internal<SUI, USDC>(&mut pool, base_coin, i, deposit_amount, scenario.ctx());


    test_scenario::next_tx(scenario, admin);
    let capital_coin = test_scenario::take_from_address<coin::Coin<BasePoolLiquidityCoin<SUI, USDC>>>(scenario,scenario.sender());

    liquidity_provider::t_withdraw_all_base_internal(&mut pool, capital_coin, i, scenario.ctx());
    test_scenario::next_tx(scenario, admin);

    let sui_coin = test_scenario::take_from_address<coin::Coin<SUI>>(scenario,scenario.sender());

    assert!(sui_coin.value() == deposit_amount, 0);

    test_scenario::return_to_address(admin, admin_cap);
    test_scenario::return_to_address(admin, sui_coin);
    test_scenario::return_shared(pool);
    
    test_scenario::end(scenario_value);
}


#[test]
fun test_withdraw_all_quote_internal() {

    let admin = @0xAA;

    let mut scenario_value = test_scenario::begin(admin);
    let scenario = &mut scenario_value;

    let mut admin_cap = oracle_driven_pool_tests::t_pool_init(scenario);

    let mut pool = oracle_driven_pool_tests::t_new_pool<SUI,USDC>(scenario, &mut admin_cap);

    let mint_amount = 1_000_000_000_000;
    let deposit_amount = 1_000_000_000;

    let quote_coin = coin::mint_for_testing(mint_amount, scenario.ctx());
    let i = 1_500_000_000;
    
    liquidity_provider::t_deposit_quote_internal<SUI, USDC>(&mut pool, quote_coin, i, deposit_amount, scenario.ctx());

    test_scenario::next_tx(scenario, admin);
    
    let capital_coin = test_scenario::take_from_address<coin::Coin<QuotePoolLiquidityCoin<SUI, USDC>>>(scenario,scenario.sender());

    liquidity_provider::t_withdraw_all_quote_internal(&mut pool, capital_coin, i, scenario.ctx());
    test_scenario::next_tx(scenario, admin);

    let usdc_coin = test_scenario::take_from_address<coin::Coin<USDC>>(scenario,scenario.sender());

    assert!(usdc_coin.value() == deposit_amount, 0);

    test_scenario::return_to_address(admin, admin_cap);
    test_scenario::return_to_address(admin, usdc_coin);
    test_scenario::return_shared(pool);
    
    test_scenario::end(scenario_value);
}
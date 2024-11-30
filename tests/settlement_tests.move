#[test_only]
module haedal_pmm::settlement_tests;

use sui::coin;
use sui::test_scenario;

use haedal_pmm::settlement;
use haedal_pmm::liquidity_provider;
use haedal_pmm::oracle_driven_pool::{BasePoolLiquidityCoin, QuotePoolLiquidityCoin};


use haedal_pmm::admin_tests;
use haedal_pmm::oracle_driven_pool_tests;

use haedal_pmm::usdc::USDC;
use haedal_pmm::sui::SUI;

#[test]
fun test_final_settlement() {

    let admin = @0xAA;
    let pool_admin = @0xbb;

    let mut scenario_value = test_scenario::begin(admin);
    let scenario = &mut scenario_value;

    let (mut admin_cap, pool_admin_cap) = admin_tests::t_grant_pool_admin_cap<SUI,USDC>(scenario, pool_admin);

    let mut pool = oracle_driven_pool_tests::t_new_pool<SUI,USDC>(scenario, &mut admin_cap);

    let mint_amount = 1_000_000_000_000;
    let deposit_base_amount = 1_000_000_000;
    let deposit_quote_amount = 2_000_000_000;

    let base_coin = coin::mint_for_testing<SUI>(mint_amount, scenario.ctx());
    let quote_coin = coin::mint_for_testing<USDC>(mint_amount, scenario.ctx());
    let i = 2_000_000_000;
    
    liquidity_provider::t_deposit_base_internal<SUI, USDC>(&mut pool, base_coin, i, deposit_base_amount, scenario.ctx());
    liquidity_provider::t_deposit_quote_internal<SUI, USDC>(&mut pool, quote_coin, i, deposit_quote_amount, scenario.ctx());

    assert!(pool.get_base_capital_coin_supply() == deposit_base_amount, 0);
    assert!(pool.get_quote_capital_coin_supply() == deposit_quote_amount, 0);

    test_scenario::next_tx(scenario, admin);

    // let sui_coin = test_scenario::take_from_address<coin::Coin<SUI>>(scenario,scenario.sender());
    // let usdc_coin = test_scenario::take_from_address<coin::Coin<USDC>>(scenario,scenario.sender());

    settlement::final_settlement(&pool_admin_cap, &mut pool);
   
    test_scenario::next_tx(scenario, admin);

    pool.assert_closed();

    test_scenario::return_to_address(admin, admin_cap);
    test_scenario::return_to_address(pool_admin, pool_admin_cap);
    test_scenario::return_shared(pool);
    
    test_scenario::end(scenario_value);
}

#[test]
fun test_claim_assets() {

    let admin = @0xAA;
    let pool_admin = @0xbb;

    let mut scenario_value = test_scenario::begin(admin);
    let scenario = &mut scenario_value;

    let (mut admin_cap, pool_admin_cap) = admin_tests::t_grant_pool_admin_cap<SUI,USDC>(scenario, pool_admin);
    
    test_scenario::next_tx(scenario, admin);

    let mut pool = oracle_driven_pool_tests::t_new_pool<SUI,USDC>(scenario, &mut admin_cap);

    let mint_amount = 1_000_000_000_000;
    let deposit_base_amount = 1_000_000_000;
    let deposit_quote_amount = 2_000_000_000;

    let base_coin = coin::mint_for_testing<SUI>(mint_amount, scenario.ctx());
    let quote_coin = coin::mint_for_testing<USDC>(mint_amount, scenario.ctx());
    let i = 2_000_000_000;
    
    liquidity_provider::t_deposit_base_internal<SUI, USDC>(&mut pool, base_coin, i, deposit_base_amount, scenario.ctx());
    liquidity_provider::t_deposit_quote_internal<SUI, USDC>(&mut pool, quote_coin, i, deposit_quote_amount, scenario.ctx());

    assert!(pool.get_base_capital_coin_supply() == deposit_base_amount, 0);
    assert!(pool.get_quote_capital_coin_supply() == deposit_quote_amount, 0);

    test_scenario::next_tx(scenario, admin);

    settlement::final_settlement(&pool_admin_cap, &mut pool);

    test_scenario::next_tx(scenario, admin);

    pool.assert_closed();

    let base_capital_coin = test_scenario::take_from_address<coin::Coin<BasePoolLiquidityCoin<SUI,USDC>>>(scenario,scenario.sender());
    let quote_capital_coin = test_scenario::take_from_address<coin::Coin<QuotePoolLiquidityCoin<SUI,USDC>>>(scenario,scenario.sender());

    settlement::claim_assets(&mut pool, base_capital_coin, quote_capital_coin, scenario.ctx());
    
    test_scenario::next_tx(scenario, admin);

    let sui_coin = test_scenario::take_from_address<coin::Coin<SUI>>(scenario,scenario.sender());
    let usdc_coin = test_scenario::take_from_address<coin::Coin<USDC>>(scenario,scenario.sender());

    assert!(sui_coin.value() == deposit_base_amount, 0);
    assert!(usdc_coin.value() == deposit_quote_amount, 0);

    test_scenario::return_to_address(admin, admin_cap);
    test_scenario::return_to_address(pool_admin, pool_admin_cap);
    test_scenario::return_to_address(admin, sui_coin);
    test_scenario::return_to_address(admin, usdc_coin);
    test_scenario::return_shared(pool);
    
    test_scenario::end(scenario_value);
}

#[test]
fun test_claim_base() {

    let admin = @0xAA;
    let pool_admin = @0xbb;

    let mut scenario_value = test_scenario::begin(admin);
    let scenario = &mut scenario_value;

    let (mut admin_cap, pool_admin_cap) = admin_tests::t_grant_pool_admin_cap<SUI,USDC>(scenario, pool_admin);

    test_scenario::next_tx(scenario, admin);

    let mut pool = oracle_driven_pool_tests::t_new_pool<SUI,USDC>(scenario, &mut admin_cap);

    let mint_amount = 1_000_000_000_000;
    let deposit_amount = 1_000_000_000;

    let base_coin = coin::mint_for_testing(mint_amount, scenario.ctx());
    let i = 1_500_000_000;
    
    liquidity_provider::t_deposit_base_internal<SUI, USDC>(&mut pool, base_coin, i, deposit_amount, scenario.ctx());

    assert!(pool.get_base_capital_coin_supply() == deposit_amount, 0);
    assert!(pool.get_quote_capital_coin_supply() == 0, 0);

    test_scenario::next_tx(scenario, admin);

    let sui_coin = test_scenario::take_from_address<coin::Coin<SUI>>(scenario,scenario.sender());
    let capital_coin = test_scenario::take_from_address<coin::Coin<BasePoolLiquidityCoin<SUI,USDC>>>(scenario,scenario.sender());

    assert!(sui_coin.value() == mint_amount - deposit_amount, 0);
    assert!(capital_coin.value() == deposit_amount, 0);

    test_scenario::return_to_address(admin, sui_coin);
    // final_settlement
    settlement::final_settlement(&pool_admin_cap, &mut pool);

    test_scenario::next_tx(scenario, admin);

    pool.assert_closed();

    settlement::claim_base(&mut pool, capital_coin, scenario.ctx());
    
    test_scenario::next_tx(scenario, admin);

    let sui_coin = test_scenario::take_from_address<coin::Coin<SUI>>(scenario,scenario.sender());

    assert!(sui_coin.value() == deposit_amount, 0);

    test_scenario::return_to_address(admin, admin_cap);
    test_scenario::return_to_address(pool_admin, pool_admin_cap);
    test_scenario::return_to_address(admin, sui_coin);
    test_scenario::return_shared(pool);
    
    test_scenario::end(scenario_value);
}


#[test]
fun test_claim_quote() {

    let admin = @0xAA;
    let pool_admin = @0xbb;

    let mut scenario_value = test_scenario::begin(admin);
    let scenario = &mut scenario_value;

    let (mut admin_cap, pool_admin_cap) = admin_tests::t_grant_pool_admin_cap<SUI,USDC>(scenario, pool_admin);

    test_scenario::next_tx(scenario, admin);

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
    let capital_coin = test_scenario::take_from_address<coin::Coin<QuotePoolLiquidityCoin<SUI,USDC>>>(scenario,scenario.sender());

    assert!(usdc_coin.value() == mint_amount - deposit_amount, 0);
    assert!(capital_coin.value() == deposit_amount, 0);

    test_scenario::return_to_address(admin, usdc_coin);
    // final_settlement
    settlement::final_settlement(&pool_admin_cap, &mut pool);

    test_scenario::next_tx(scenario, admin);

    pool.assert_closed();

    settlement::claim_quote(&mut pool, capital_coin, scenario.ctx());
    
    test_scenario::next_tx(scenario, admin);

    let usdc_coin = test_scenario::take_from_address<coin::Coin<USDC>>(scenario,scenario.sender());

    assert!(usdc_coin.value() == deposit_amount, 0);

    test_scenario::return_to_address(admin, admin_cap);
    test_scenario::return_to_address(pool_admin, pool_admin_cap);
    test_scenario::return_to_address(admin, usdc_coin);
    test_scenario::return_shared(pool);
    
    test_scenario::end(scenario_value);
}
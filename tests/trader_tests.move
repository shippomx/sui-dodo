#[test_only]
module haedal_pmm::trader_tests;

use sui::coin;
use sui::test_scenario;

use haedal_pmm::trader;
use haedal_pmm::liquidity_provider;
use haedal_pmm::oracle_driven_pool::{BasePoolLiquidityCoin, QuotePoolLiquidityCoin};

use haedal_pmm::oracle_driven_pool_tests;

use haedal_pmm::usdc::USDC;
use haedal_pmm::sui::SUI;

#[test]
fun test_sell_base_internal() {

    let admin = @0xAA;
    let trader = @0xee;

    let mut scenario_value = test_scenario::begin(admin);
    let scenario = &mut scenario_value;

    let mut admin_cap = oracle_driven_pool_tests::t_pool_init(scenario);

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

    let sui_coin = test_scenario::take_from_address<coin::Coin<SUI>>(scenario,scenario.sender());
    let usdc_coin = test_scenario::take_from_address<coin::Coin<USDC>>(scenario,scenario.sender());
    let base_capital_coin = test_scenario::take_from_address<coin::Coin<BasePoolLiquidityCoin<SUI,USDC>>>(scenario,scenario.sender());
    let quote_capital_coin = test_scenario::take_from_address<coin::Coin<QuotePoolLiquidityCoin<SUI,USDC>>>(scenario,scenario.sender());

    assert!(sui_coin.value() == mint_amount - deposit_base_amount, 0);
    assert!(usdc_coin.value() == mint_amount - deposit_quote_amount, 0);
    assert!(base_capital_coin.value() == deposit_base_amount, 0);
    assert!(quote_capital_coin.value() == deposit_quote_amount, 0);

    test_scenario::return_to_address(admin, sui_coin);
    test_scenario::return_to_address(admin, usdc_coin);

    test_scenario::next_tx(scenario, trader);
    let sui_coin = coin::mint_for_testing<SUI>(mint_amount, scenario.ctx());

    // trade
    let sell_amount = 1_000_000;
    // let min_receive_quote = 1_890_000;
    let receive_quote = trader::t_query_sell_base_coin_internal(&pool, i, sell_amount);

    trader::t_sell_base_coin_internal<SUI, USDC>(&mut pool, i, sui_coin, sell_amount, receive_quote, scenario.ctx());

    test_scenario::next_tx(scenario, trader);
    let sui_coin = test_scenario::take_from_address<coin::Coin<SUI>>(scenario,scenario.sender());
    let usdc_coin = test_scenario::take_from_address<coin::Coin<USDC>>(scenario,trader);

    assert!(sui_coin.value() == mint_amount - sell_amount, 0);
    assert!(usdc_coin.value() == receive_quote, 0);

    test_scenario::return_to_address(admin, admin_cap);
    test_scenario::return_to_address(trader, sui_coin);
    test_scenario::return_to_address(trader, usdc_coin);
    test_scenario::return_to_address(admin, base_capital_coin);
    test_scenario::return_to_address(admin, quote_capital_coin);
    test_scenario::return_shared(pool);
    
    test_scenario::end(scenario_value);
}

#[test]
fun test_buy_base_internal() {

    let admin = @0xAA;
    let trader = @0xee;

    let mut scenario_value = test_scenario::begin(admin);
    let scenario = &mut scenario_value;

    let mut admin_cap = oracle_driven_pool_tests::t_pool_init(scenario);

    let mut pool = oracle_driven_pool_tests::t_new_pool<SUI,USDC>(scenario, &mut admin_cap);

    let mint_amount = 500_000_000_000;
    let deposit_base_amount = 10_000_000_000;
    let deposit_quote_amount = 20_000_000_000;

    let base_coin = coin::mint_for_testing<SUI>(mint_amount, scenario.ctx());
    let quote_coin = coin::mint_for_testing<USDC>(mint_amount, scenario.ctx());
    let i = 2_000_000_000;
    
    liquidity_provider::t_deposit_base_internal<SUI, USDC>(&mut pool, base_coin, i, deposit_base_amount, scenario.ctx());
    liquidity_provider::t_deposit_quote_internal<SUI, USDC>(&mut pool, quote_coin, i, deposit_quote_amount, scenario.ctx());

    assert!(pool.get_base_capital_coin_supply() == deposit_base_amount, 0);
    assert!(pool.get_quote_capital_coin_supply() == deposit_quote_amount, 0);

    test_scenario::next_tx(scenario, admin);

    let sui_coin = test_scenario::take_from_address<coin::Coin<SUI>>(scenario,scenario.sender());
    let usdc_coin = test_scenario::take_from_address<coin::Coin<USDC>>(scenario,scenario.sender());
    let base_capital_coin = test_scenario::take_from_address<coin::Coin<BasePoolLiquidityCoin<SUI,USDC>>>(scenario,scenario.sender());
    let quote_capital_coin = test_scenario::take_from_address<coin::Coin<QuotePoolLiquidityCoin<SUI,USDC>>>(scenario,scenario.sender());

    assert!(sui_coin.value() == mint_amount - deposit_base_amount, 0);
    assert!(usdc_coin.value() == mint_amount - deposit_quote_amount, 0);
    assert!(base_capital_coin.value() == deposit_base_amount, 0);
    assert!(quote_capital_coin.value() == deposit_quote_amount, 0);

    test_scenario::return_to_address(admin, sui_coin);
    test_scenario::return_to_address(admin, usdc_coin);

    test_scenario::next_tx(scenario, trader);
    let usdc_coin = coin::mint_for_testing<USDC>(mint_amount, scenario.ctx());

    // trade
    let buy_amount = 1_000_000;
    // let max_pay_quote = 2_110_000;
    let pay_quote = trader::t_query_buy_base_coin_internal(&pool, i, buy_amount);
    // std::debug::print(&pay_quote);

    trader::t_buy_base_coin_internal<SUI, USDC>(&mut pool, i, usdc_coin, buy_amount, pay_quote, scenario.ctx());

    test_scenario::next_tx(scenario, trader);
    let sui_coin = test_scenario::take_from_address<coin::Coin<SUI>>(scenario,scenario.sender());
    let usdc_coin = test_scenario::take_from_address<coin::Coin<USDC>>(scenario,trader);

    assert!(sui_coin.value() == buy_amount, 0);
    assert!(usdc_coin.value() == mint_amount - pay_quote, 0);

    test_scenario::return_to_address(admin, admin_cap);
    test_scenario::return_to_address(trader, sui_coin);
    test_scenario::return_to_address(trader, usdc_coin);
    test_scenario::return_to_address(admin, base_capital_coin);
    test_scenario::return_to_address(admin, quote_capital_coin);
    test_scenario::return_shared(pool);
    
    test_scenario::end(scenario_value);
}


#[test]
fun test_buy_base_internal_r_eq_one() {

    let admin = @0xAA;
    let trader = @0xee;

    let mut scenario_value = test_scenario::begin(admin);
    let scenario = &mut scenario_value;

    let mut admin_cap = oracle_driven_pool_tests::t_pool_init(scenario);

    let mut pool = oracle_driven_pool_tests::t_new_pool<SUI,USDC>(scenario, &mut admin_cap);

    let mint_base_amount = 10_000_000_000;
    let mint_quote_amount = 1_000_000_000_000;
    let deposit_base_amount = 10_000_000_000;
    let deposit_quote_amount = 1_000_000_000_000;

    let base_coin = coin::mint_for_testing<SUI>(mint_base_amount, scenario.ctx());
    let quote_coin = coin::mint_for_testing<USDC>(mint_quote_amount, scenario.ctx());
    let i = 100_000_000_000;
    
    liquidity_provider::t_deposit_base_internal<SUI, USDC>(&mut pool, base_coin, i, deposit_base_amount, scenario.ctx());
    liquidity_provider::t_deposit_quote_internal<SUI, USDC>(&mut pool, quote_coin, i, deposit_quote_amount, scenario.ctx());

    assert!(pool.get_base_capital_coin_supply() == deposit_base_amount, 0);
    assert!(pool.get_quote_capital_coin_supply() == deposit_quote_amount, 0);

    test_scenario::next_tx(scenario, admin);

    // let sui_coin = test_scenario::take_from_address<coin::Coin<SUI>>(scenario,scenario.sender());
    // let usdc_coin = test_scenario::take_from_address<coin::Coin<USDC>>(scenario,scenario.sender());
    let base_capital_coin = test_scenario::take_from_address<coin::Coin<BasePoolLiquidityCoin<SUI,USDC>>>(scenario,scenario.sender());
    let quote_capital_coin = test_scenario::take_from_address<coin::Coin<QuotePoolLiquidityCoin<SUI,USDC>>>(scenario,scenario.sender());

    // assert!(sui_coin.value() == mint_base_amount - deposit_base_amount, 0);
    // assert!(usdc_coin.value() == mint_quote_amount - deposit_quote_amount, 0);
    assert!(base_capital_coin.value() == deposit_base_amount, 0);
    assert!(quote_capital_coin.value() == deposit_quote_amount, 0);

    // test_scenario::return_to_address(admin, sui_coin);
    // test_scenario::return_to_address(admin, usdc_coin);

    test_scenario::next_tx(scenario, trader);
    // let sui_coin = coin::mint_for_testing<SUI>(mint_base_amount, scenario.ctx());
    let usdc_coin = coin::mint_for_testing<USDC>(mint_quote_amount, scenario.ctx());

    // test_scenario::return_to_address(trader, sui_coin);
    // trade
    let buy_amount = 1_000_000_000;
    let max_pay_quote = 110_000_000_000;
    // let pay_quote = trader::t_query_buy_base_coin_internal(&pool, i, buy_amount);
    // std::debug::print(&pay_quote);

    trader::t_buy_base_coin_internal<SUI, USDC>(&mut pool, i, usdc_coin, buy_amount, max_pay_quote, scenario.ctx());

    test_scenario::next_tx(scenario, trader);
    let sui_coin = test_scenario::take_from_address<coin::Coin<SUI>>(scenario,scenario.sender());
    let fee_sui_coin = test_scenario::take_from_address<coin::Coin<SUI>>(scenario,pool.get_maintainer());
    let usdc_coin = test_scenario::take_from_address<coin::Coin<USDC>>(scenario,trader);
    
    assert!(fee_sui_coin.value() == 1_000_000, 0);
    assert!(sui_coin.value() == buy_amount, 0);
    assert!(usdc_coin.value() == 898581839552u64, 0); // dodo = 898581839502; Loss of precision

    assert!(pool.get_base_balance() == 8_999_000_000, 0); 
    assert!(pool.get_quote_balance() == 1101418160448, 0);  // dodo = 1101418160497943759027; Loss of precision

    test_scenario::return_to_address(admin, admin_cap);
    test_scenario::return_to_address(trader, sui_coin);
    test_scenario::return_to_address(trader, usdc_coin);
    test_scenario::return_to_address(pool.get_maintainer(), fee_sui_coin);
    test_scenario::return_to_address(admin, base_capital_coin);
    test_scenario::return_to_address(admin, quote_capital_coin);
    test_scenario::return_shared(pool);
    
    test_scenario::end(scenario_value);
}

#[test]
fun test_buy_base_internal_r_above_one() {

    let admin = @0xAA;
    let trader = @0xee;

    let mut scenario_value = test_scenario::begin(admin);
    let scenario = &mut scenario_value;

    let mut admin_cap = oracle_driven_pool_tests::t_pool_init(scenario);

    let mut pool = oracle_driven_pool_tests::t_new_pool<SUI,USDC>(scenario, &mut admin_cap);

    let mint_base_amount = 10_000_000_000;
    let mint_quote_amount = 1_000_000_000_000;
    let deposit_base_amount = 10_000_000_000;
    let deposit_quote_amount = 1_000_000_000_000;

    let base_coin = coin::mint_for_testing<SUI>(mint_base_amount, scenario.ctx());
    let quote_coin = coin::mint_for_testing<USDC>(mint_quote_amount, scenario.ctx());
    let i = 100_000_000_000;
    
    liquidity_provider::t_deposit_base_internal<SUI, USDC>(&mut pool, base_coin, i, deposit_base_amount, scenario.ctx());
    liquidity_provider::t_deposit_quote_internal<SUI, USDC>(&mut pool, quote_coin, i, deposit_quote_amount, scenario.ctx());

    assert!(pool.get_base_capital_coin_supply() == deposit_base_amount, 0);
    assert!(pool.get_quote_capital_coin_supply() == deposit_quote_amount, 0);

    test_scenario::next_tx(scenario, admin);

    // let sui_coin = test_scenario::take_from_address<coin::Coin<SUI>>(scenario,scenario.sender());
    // let usdc_coin = test_scenario::take_from_address<coin::Coin<USDC>>(scenario,scenario.sender());
    let base_capital_coin = test_scenario::take_from_address<coin::Coin<BasePoolLiquidityCoin<SUI,USDC>>>(scenario,scenario.sender());
    let quote_capital_coin = test_scenario::take_from_address<coin::Coin<QuotePoolLiquidityCoin<SUI,USDC>>>(scenario,scenario.sender());

    // assert!(sui_coin.value() == mint_base_amount - deposit_base_amount, 0);
    // assert!(usdc_coin.value() == mint_quote_amount - deposit_quote_amount, 0);
    assert!(base_capital_coin.value() == deposit_base_amount, 0);
    assert!(quote_capital_coin.value() == deposit_quote_amount, 0);

    // test_scenario::return_to_address(admin, sui_coin);
    // test_scenario::return_to_address(admin, usdc_coin);

    test_scenario::next_tx(scenario, trader);
    // let sui_coin = coin::mint_for_testing<SUI>(mint_base_amount, scenario.ctx());
    let usdc_coin = coin::mint_for_testing<USDC>(mint_quote_amount, scenario.ctx());

    // test_scenario::return_to_address(trader, sui_coin);
    // trade
    let buy_amount = 1_000_000_000;
    let max_pay_quote = 110_000_000_000;
    // let pay_quote = trader::t_query_buy_base_coin_internal(&pool, i, buy_amount);
    // std::debug::print(&pay_quote);

    trader::t_buy_base_coin_internal<SUI, USDC>(&mut pool, i, usdc_coin, buy_amount, max_pay_quote, scenario.ctx());

    test_scenario::next_tx(scenario, trader);

        // trade
    let buy_amount = 1_000_000_000;
    let max_pay_quote = 130_000_000_000;
    // let pay_quote = trader::t_query_buy_base_coin_internal(&pool, i, buy_amount);
    // std::debug::print(&pay_quote);
    let usdc_coin = test_scenario::take_from_address<coin::Coin<USDC>>(scenario,trader);

    trader::t_buy_base_coin_internal<SUI, USDC>(&mut pool, i, usdc_coin, buy_amount, max_pay_quote, scenario.ctx());

    test_scenario::next_tx(scenario, trader);

    let sui_coin = test_scenario::take_from_address<coin::Coin<SUI>>(scenario,scenario.sender());
    let fee_sui_coin = test_scenario::take_from_address<coin::Coin<SUI>>(scenario,pool.get_maintainer());
    let usdc_coin = test_scenario::take_from_address<coin::Coin<USDC>>(scenario,trader);

    // std::debug::print(&fee_sui_coin.value());
    // std::debug::print(&sui_coin.value());
    // std::debug::print(&usdc_coin.value());
    // std::debug::print(&pool.get_base_balance());
    // std::debug::print(&pool.get_quote_balance());

    assert!(fee_sui_coin.value() == 1_000_000, 0);
    assert!(sui_coin.value() == buy_amount, 0);
    assert!(usdc_coin.value() == 794367183611, 0); // dodo = 794367183433412077653; Loss of precision
    assert!(pool.get_base_balance() == 7998000000, 0); 
    assert!(pool.get_quote_balance() == 1205632816389, 0);  // dodo = 1205632816566587922347; Loss of precision

    test_scenario::return_to_address(admin, admin_cap);
    test_scenario::return_to_address(trader, sui_coin);
    test_scenario::return_to_address(trader, usdc_coin);
    test_scenario::return_to_address(pool.get_maintainer(), fee_sui_coin);
    test_scenario::return_to_address(admin, base_capital_coin);
    test_scenario::return_to_address(admin, quote_capital_coin);
    test_scenario::return_shared(pool);
    
    test_scenario::end(scenario_value);
}

#[test]
fun test_sell_base_internal_r_above_one() {

    let admin = @0xAA;
    let trader = @0xee;

    let mut scenario_value = test_scenario::begin(admin);
    let scenario = &mut scenario_value;

    let mut admin_cap = oracle_driven_pool_tests::t_pool_init(scenario);

    let mut pool = oracle_driven_pool_tests::t_new_pool<SUI,USDC>(scenario, &mut admin_cap);

    let mint_base_amount = 10_000_000_000;
    let mint_quote_amount = 1_000_000_000_000;
    let deposit_base_amount = 10_000_000_000;
    let deposit_quote_amount = 1_000_000_000_000;

    let base_coin = coin::mint_for_testing<SUI>(mint_base_amount, scenario.ctx());
    let quote_coin = coin::mint_for_testing<USDC>(mint_quote_amount, scenario.ctx());
    let i = 100_000_000_000;
    
    liquidity_provider::t_deposit_base_internal<SUI, USDC>(&mut pool, base_coin, i, deposit_base_amount, scenario.ctx());
    liquidity_provider::t_deposit_quote_internal<SUI, USDC>(&mut pool, quote_coin, i, deposit_quote_amount, scenario.ctx());

    assert!(pool.get_base_capital_coin_supply() == deposit_base_amount, 0);
    assert!(pool.get_quote_capital_coin_supply() == deposit_quote_amount, 0);

    test_scenario::next_tx(scenario, admin);

    let base_capital_coin = test_scenario::take_from_address<coin::Coin<BasePoolLiquidityCoin<SUI,USDC>>>(scenario,scenario.sender());
    let quote_capital_coin = test_scenario::take_from_address<coin::Coin<QuotePoolLiquidityCoin<SUI,USDC>>>(scenario,scenario.sender());

    assert!(base_capital_coin.value() == deposit_base_amount, 0);
    assert!(quote_capital_coin.value() == deposit_quote_amount, 0);

    test_scenario::next_tx(scenario, trader);
    // let sui_coin = coin::mint_for_testing<SUI>(mint_base_amount, scenario.ctx());
    let usdc_coin = coin::mint_for_testing<USDC>(mint_quote_amount, scenario.ctx());

    // test_scenario::return_to_address(trader, sui_coin);
    // trade
    let buy_amount = 1_000_000_000;
    let max_pay_quote = 110_000_000_000;
    // let pay_quote = trader::t_query_buy_base_coin_internal(&pool, i, buy_amount);
    // std::debug::print(&pay_quote);

    trader::t_buy_base_coin_internal<SUI, USDC>(&mut pool, i, usdc_coin, buy_amount, max_pay_quote, scenario.ctx());

    test_scenario::next_tx(scenario, trader);

        // trade
    let sell_amount = 500_000_000;
    let min_receive_quote = 40_000_000_000;
    // let pay_quote = trader::t_query_buy_base_coin_internal(&pool, i, buy_amount);
    // std::debug::print(&pay_quote);
    let sui_coibn = test_scenario::take_from_address<coin::Coin<SUI>>(scenario,trader);

    trader::t_sell_base_coin_internal<SUI, USDC>(&mut pool, i, sui_coibn, sell_amount, min_receive_quote, scenario.ctx());

    test_scenario::next_tx(scenario, trader);

    let fee_sui_coin = test_scenario::take_from_address<coin::Coin<SUI>>(scenario,pool.get_maintainer());
    let fee_usdc_coin = test_scenario::take_from_address<coin::Coin<USDC>>(scenario,pool.get_maintainer());
    let sui_coin = test_scenario::take_from_address<coin::Coin<SUI>>(scenario,scenario.sender());
    let usdc_coin = test_scenario::take_from_address<coin::Coin<USDC>>(scenario,trader);


    // std::debug::print(&fee_sui_coin.value());
    // std::debug::print(&fee_usdc_coin.value());
    // std::debug::print(&sui_coin.value());
    // std::debug::print(&usdc_coin.value());
    // std::debug::print(&pool.get_base_balance());
    // std::debug::print(&pool.get_quote_balance());
    assert!(fee_sui_coin.value() == 1_000_000, 0);
    assert!(sui_coin.value() == buy_amount - sell_amount, 0);
    assert!(usdc_coin.value() == 50699006767, 0); // dodo = 50851561534203512; Loss of precision; TODO: check why
    assert!(pool.get_base_balance() == 9499000000, 0); 
    assert!(pool.get_quote_balance() == 1050668302120, 0);  // dodo = 1050668302086808653352; Loss of precision

    test_scenario::return_to_address(admin, admin_cap);
    test_scenario::return_to_address(trader, sui_coin);
    test_scenario::return_to_address(trader, usdc_coin);
    test_scenario::return_to_address(pool.get_maintainer(), fee_sui_coin);
    test_scenario::return_to_address(pool.get_maintainer(), fee_usdc_coin);
    test_scenario::return_to_address(admin, base_capital_coin);
    test_scenario::return_to_address(admin, quote_capital_coin);
    test_scenario::return_shared(pool);
    
    test_scenario::end(scenario_value);
}

#[test]
fun test_sell_base_internal_r_above_one_and_r_back_to_one() {

    let admin = @0xAA;
    let trader = @0xee;

    let mut scenario_value = test_scenario::begin(admin);
    let scenario = &mut scenario_value;

    let mut admin_cap = oracle_driven_pool_tests::t_pool_init(scenario);

    let mut pool = oracle_driven_pool_tests::t_new_pool<SUI,USDC>(scenario, &mut admin_cap);

    let mint_base_amount = 10_000_000_000;
    let mint_quote_amount = 1_000_000_000_000;
    let deposit_base_amount = 10_000_000_000;
    let deposit_quote_amount = 1_000_000_000_000;

    let base_coin = coin::mint_for_testing<SUI>(mint_base_amount, scenario.ctx());
    let quote_coin = coin::mint_for_testing<USDC>(mint_quote_amount, scenario.ctx());
    let i = 100_000_000_000;
    
    liquidity_provider::t_deposit_base_internal<SUI, USDC>(&mut pool, base_coin, i, deposit_base_amount, scenario.ctx());
    liquidity_provider::t_deposit_quote_internal<SUI, USDC>(&mut pool, quote_coin, i, deposit_quote_amount, scenario.ctx());

    assert!(pool.get_base_capital_coin_supply() == deposit_base_amount, 0);
    assert!(pool.get_quote_capital_coin_supply() == deposit_quote_amount, 0);

    test_scenario::next_tx(scenario, admin);

    let base_capital_coin = test_scenario::take_from_address<coin::Coin<BasePoolLiquidityCoin<SUI,USDC>>>(scenario,scenario.sender());
    let quote_capital_coin = test_scenario::take_from_address<coin::Coin<QuotePoolLiquidityCoin<SUI,USDC>>>(scenario,scenario.sender());

    assert!(base_capital_coin.value() == deposit_base_amount, 0);
    assert!(quote_capital_coin.value() == deposit_quote_amount, 0);

    test_scenario::next_tx(scenario, trader);
    // let sui_coin = coin::mint_for_testing<SUI>(mint_base_amount, scenario.ctx());
    let usdc_coin = coin::mint_for_testing<USDC>(mint_quote_amount, scenario.ctx());

    // test_scenario::return_to_address(trader, sui_coin);
    // trade
    let buy_amount = 1_000_000_000;
    let max_pay_quote = 110_000_000_000;
    // let pay_quote = trader::t_query_buy_base_coin_internal(&pool, i, buy_amount);
    // std::debug::print(&pay_quote);

    trader::t_buy_base_coin_internal<SUI, USDC>(&mut pool, i, usdc_coin, buy_amount, max_pay_quote, scenario.ctx());

    test_scenario::next_tx(scenario, trader);

    // test_scenario::return_to_address(trader, sui_coin);

        // trade
    // let sell_amount = 1001000000;
    let sell_amount = 1003002397;
    let min_receive_quote = 90_000_000_000;
    // let pay_quote = trader::t_query_buy_base_coin_internal(&pool, i, buy_amount);
    // std::debug::print(&pay_quote);
    // let sui_coibn = test_scenario::take_from_address<coin::Coin<SUI>>(scenario,trader);
    let sui_coin = coin::mint_for_testing<SUI>(mint_base_amount, scenario.ctx());

    // std::debug::print(&pool.get_r_status());
    trader::t_sell_base_coin_internal<SUI, USDC>(&mut pool, i, sui_coin, sell_amount, min_receive_quote, scenario.ctx());

    test_scenario::next_tx(scenario, trader);

    let fee_usdc_coin = test_scenario::take_from_address<coin::Coin<USDC>>(scenario,pool.get_maintainer());
    let sui_coin = test_scenario::take_from_address<coin::Coin<SUI>>(scenario,scenario.sender());
    let usdc_coin = test_scenario::take_from_address<coin::Coin<USDC>>(scenario,trader);
    let (target_base_coin_amount, target_quote_coin_amount) = pool.get_target_amount();

    // std::debug::print(&fee_usdc_coin.value());
    // std::debug::print(&sui_coin.value());
    // std::debug::print(&usdc_coin.value());
    // std::debug::print(&pool.get_base_balance());
    // std::debug::print(&pool.get_quote_balance());
    // std::debug::print(&target_base_coin_amount);
    // std::debug::print(&target_quote_coin_amount);
    // std::debug::print(&pool.get_r_status());

    assert!(fee_usdc_coin.value() == 101418160, 0); // dodo: 101418160497943759
    assert!(sui_coin.value() == mint_base_amount - sell_amount, 0);
    assert!(usdc_coin.value() == 101113905968, 0); //

    assert!(pool.get_base_balance() == 10002002397, 0);  // dodo: 10002002430889317763
    assert!(pool.get_quote_balance() == 1000202836320, 0); // dodo: 1000202836320995887518

    assert!(target_base_coin_amount == 10002002397, 0); // dodo: 10002002430889317763
    assert!(target_quote_coin_amount == 1000202836320, 0); // dodo: 1000202836320995887518
    // assert!(pool.get_r_status() == RStatus::ONE, 0);


    test_scenario::return_to_address(admin, admin_cap);
    test_scenario::return_to_address(trader, sui_coin);
    test_scenario::return_to_address(trader, usdc_coin);
    test_scenario::return_to_address(pool.get_maintainer(), fee_usdc_coin);
    test_scenario::return_to_address(admin, base_capital_coin);
    test_scenario::return_to_address(admin, quote_capital_coin);
    test_scenario::return_shared(pool);
    
    test_scenario::end(scenario_value);
}

#[test]
fun test_sell_base_internal_r_above_one_and_r_become_below_one() {

    let admin = @0xAA;
    let trader = @0xee;

    let mut scenario_value = test_scenario::begin(admin);
    let scenario = &mut scenario_value;

    let mut admin_cap = oracle_driven_pool_tests::t_pool_init(scenario);

    let mut pool = oracle_driven_pool_tests::t_new_pool<SUI,USDC>(scenario, &mut admin_cap);

    let mint_base_amount = 10_000_000_000;
    let mint_quote_amount = 1_000_000_000_000;
    let deposit_base_amount = 10_000_000_000;
    let deposit_quote_amount = 1_000_000_000_000;

    let base_coin = coin::mint_for_testing<SUI>(mint_base_amount, scenario.ctx());
    let quote_coin = coin::mint_for_testing<USDC>(mint_quote_amount, scenario.ctx());
    let i = 100_000_000_000;
    
    liquidity_provider::t_deposit_base_internal<SUI, USDC>(&mut pool, base_coin, i, deposit_base_amount, scenario.ctx());
    liquidity_provider::t_deposit_quote_internal<SUI, USDC>(&mut pool, quote_coin, i, deposit_quote_amount, scenario.ctx());

    assert!(pool.get_base_capital_coin_supply() == deposit_base_amount, 0);
    assert!(pool.get_quote_capital_coin_supply() == deposit_quote_amount, 0);

    test_scenario::next_tx(scenario, admin);

    let base_capital_coin = test_scenario::take_from_address<coin::Coin<BasePoolLiquidityCoin<SUI,USDC>>>(scenario,scenario.sender());
    let quote_capital_coin = test_scenario::take_from_address<coin::Coin<QuotePoolLiquidityCoin<SUI,USDC>>>(scenario,scenario.sender());

    assert!(base_capital_coin.value() == deposit_base_amount, 0);
    assert!(quote_capital_coin.value() == deposit_quote_amount, 0);

    test_scenario::next_tx(scenario, trader);
    // let sui_coin = coin::mint_for_testing<SUI>(mint_base_amount, scenario.ctx());
    let usdc_coin = coin::mint_for_testing<USDC>(mint_quote_amount, scenario.ctx());

    // test_scenario::return_to_address(trader, sui_coin);
    // trade
    let buy_amount = 1_000_000_000;
    let max_pay_quote = 110_000_000_000;
    // let pay_quote = trader::t_query_buy_base_coin_internal(&pool, i, buy_amount);
    // std::debug::print(&pay_quote);

    trader::t_buy_base_coin_internal<SUI, USDC>(&mut pool, i, usdc_coin, buy_amount, max_pay_quote, scenario.ctx());

    test_scenario::next_tx(scenario, trader);

    // test_scenario::return_to_address(trader, sui_coin);

        // trade
    // let sell_amount = 1001000000;
    let sell_amount = 2_000_000_000;
    let min_receive_quote = 90_000_000_000;
    // let pay_quote = trader::t_query_buy_base_coin_internal(&pool, i, buy_amount);
    // std::debug::print(&pay_quote);
    // let sui_coibn = test_scenario::take_from_address<coin::Coin<SUI>>(scenario,trader);
    let sui_coin = coin::mint_for_testing<SUI>(mint_base_amount, scenario.ctx());

    // std::debug::print(&pool.get_r_status());
    trader::t_sell_base_coin_internal<SUI, USDC>(&mut pool, i, sui_coin, sell_amount, min_receive_quote, scenario.ctx());

    test_scenario::next_tx(scenario, trader);

    let fee_sui_coin = test_scenario::take_from_address<coin::Coin<SUI>>(scenario,pool.get_maintainer());
    let fee_usdc_coin = test_scenario::take_from_address<coin::Coin<USDC>>(scenario,pool.get_maintainer());
    let sui_coin = test_scenario::take_from_address<coin::Coin<SUI>>(scenario,scenario.sender());
    let usdc_coin = test_scenario::take_from_address<coin::Coin<USDC>>(scenario,trader);
    let (target_base_coin_amount, target_quote_coin_amount) = pool.get_target_amount();

    // std::debug::print(&fee_usdc_coin.value());
    // std::debug::print(&sui_coin.value());
    // std::debug::print(&usdc_coin.value());
    // std::debug::print(&pool.get_base_balance());
    // std::debug::print(&pool.get_quote_balance());
    // std::debug::print(&target_base_coin_amount);
    // std::debug::print(&target_quote_coin_amount);
    // std::debug::print(&pool.get_r_status());

    assert!(fee_sui_coin.value() == 1000000, 0);
    assert!(fee_usdc_coin.value() == 200038902, 0); // dodo: 200038898794388634
    assert!(sui_coin.value() == mint_base_amount - sell_amount, 0);
    assert!(usdc_coin.value() == 199438785351, 0); // dodo: 1098020621600061709144

    assert!(pool.get_base_balance() == 10999000000, 0); // dodo: 10999000000
    assert!(pool.get_quote_balance() == 901779336195, 0); // dodo: 901779339501143902222

    assert!(target_base_coin_amount == 10002002397, 0);  // dodo: 10002002430889317763
    assert!(target_quote_coin_amount == 1000400077804, 0);  // dodo: 1000400077797588777268
    // assert!(pool.get_r_status() == RStatus::ONE, 0);
//  std::debug::print(&pool.get_r_status());

//    let (baseCoin, basePenalty) =  liquidity_provider::query_withdraw_base_coin_internal(&pool, i, 10000000);
//    let (quoteCoin, quotePenalty) =  liquidity_provider::query_withdraw_quote_coin_internal(&pool, i, 100000);
//     std::debug::print(&baseCoin);
//     std::debug::print(&basePenalty);
//     std::debug::print(&quoteCoin);
//     std::debug::print(&quotePenalty);
    test_scenario::return_to_address(admin, admin_cap);
    test_scenario::return_to_address(trader, sui_coin);
    test_scenario::return_to_address(trader, usdc_coin);
    test_scenario::return_to_address(pool.get_maintainer(), fee_usdc_coin);
    test_scenario::return_to_address(pool.get_maintainer(), fee_sui_coin);
    test_scenario::return_to_address(admin, base_capital_coin);
    test_scenario::return_to_address(admin, quote_capital_coin);
    test_scenario::return_shared(pool);
    
    test_scenario::end(scenario_value);
}


#[test]
#[expected_failure]
fun test_sell_base_internal_failure() {

    let admin = @0xAA;
    let trader = @0xee;

    let mut scenario_value = test_scenario::begin(admin);
    let scenario = &mut scenario_value;

    let mut admin_cap = oracle_driven_pool_tests::t_pool_init(scenario);

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

    let sui_coin = test_scenario::take_from_address<coin::Coin<SUI>>(scenario,scenario.sender());
    let usdc_coin = test_scenario::take_from_address<coin::Coin<USDC>>(scenario,scenario.sender());
    let base_capital_coin = test_scenario::take_from_address<coin::Coin<BasePoolLiquidityCoin<SUI,USDC>>>(scenario,scenario.sender());
    let quote_capital_coin = test_scenario::take_from_address<coin::Coin<QuotePoolLiquidityCoin<SUI,USDC>>>(scenario,scenario.sender());

    assert!(sui_coin.value() == mint_amount - deposit_base_amount, 0);
    assert!(usdc_coin.value() == mint_amount - deposit_quote_amount, 0);
    assert!(base_capital_coin.value() == deposit_base_amount, 0);
    assert!(quote_capital_coin.value() == deposit_quote_amount, 0);

    test_scenario::return_to_address(admin, sui_coin);
    test_scenario::return_to_address(admin, usdc_coin);

    test_scenario::next_tx(scenario, trader);
    let sui_coin = coin::mint_for_testing<SUI>(mint_amount, scenario.ctx());

    // trade
    let sell_amount = 1_000_000;
    // let min_receive_quote = 1_890_000;
    let min_receive_quote = trader::t_query_sell_base_coin_internal(&pool, i, sell_amount) * 2;

    trader::t_sell_base_coin_internal<SUI, USDC>(&mut pool, i, sui_coin, sell_amount, min_receive_quote, scenario.ctx());

    test_scenario::return_to_address(admin, admin_cap);
    test_scenario::return_to_address(admin, base_capital_coin);
    test_scenario::return_to_address(admin, quote_capital_coin);
    test_scenario::return_shared(pool);
    
    test_scenario::end(scenario_value);
}    
    
#[test]
#[expected_failure]
fun test_buy_base_internal_failure() {

    let admin = @0xAA;
    let trader = @0xee;

    let mut scenario_value = test_scenario::begin(admin);
    let scenario = &mut scenario_value;

    let mut admin_cap = oracle_driven_pool_tests::t_pool_init(scenario);

    let mut pool = oracle_driven_pool_tests::t_new_pool<SUI,USDC>(scenario, &mut admin_cap);

    let mint_amount = 500_000_000_000;
    let deposit_base_amount = 10_000_000_000;
    let deposit_quote_amount = 20_000_000_000;

    let base_coin = coin::mint_for_testing<SUI>(mint_amount, scenario.ctx());
    let quote_coin = coin::mint_for_testing<USDC>(mint_amount, scenario.ctx());
    let i = 2_000_000_000;
    
    liquidity_provider::t_deposit_base_internal<SUI, USDC>(&mut pool, base_coin, i, deposit_base_amount, scenario.ctx());
    liquidity_provider::t_deposit_quote_internal<SUI, USDC>(&mut pool, quote_coin, i, deposit_quote_amount, scenario.ctx());

    assert!(pool.get_base_capital_coin_supply() == deposit_base_amount, 0);
    assert!(pool.get_quote_capital_coin_supply() == deposit_quote_amount, 0);

    test_scenario::next_tx(scenario, admin);

    let sui_coin = test_scenario::take_from_address<coin::Coin<SUI>>(scenario,scenario.sender());
    let usdc_coin = test_scenario::take_from_address<coin::Coin<USDC>>(scenario,scenario.sender());
    let base_capital_coin = test_scenario::take_from_address<coin::Coin<BasePoolLiquidityCoin<SUI,USDC>>>(scenario,scenario.sender());
    let quote_capital_coin = test_scenario::take_from_address<coin::Coin<QuotePoolLiquidityCoin<SUI,USDC>>>(scenario,scenario.sender());

    assert!(sui_coin.value() == mint_amount - deposit_base_amount, 0);
    assert!(usdc_coin.value() == mint_amount - deposit_quote_amount, 0);
    assert!(base_capital_coin.value() == deposit_base_amount, 0);
    assert!(quote_capital_coin.value() == deposit_quote_amount, 0);

    test_scenario::return_to_address(admin, sui_coin);
    test_scenario::return_to_address(admin, usdc_coin);

    test_scenario::next_tx(scenario, trader);
    let usdc_coin = coin::mint_for_testing<USDC>(mint_amount, scenario.ctx());

    // trade
    let buy_amount = 1_000_000;
    // let max_pay_quote = 2_110_000;
    let max_pay_quote = trader::t_query_buy_base_coin_internal(&pool, i, buy_amount) * 2 / 10;
    // std::debug::print(&pay_quote);

    trader::t_buy_base_coin_internal<SUI, USDC>(&mut pool, i, usdc_coin, buy_amount, max_pay_quote, scenario.ctx());

    test_scenario::return_to_address(admin, admin_cap);
    test_scenario::return_to_address(admin, base_capital_coin);
    test_scenario::return_to_address(admin, quote_capital_coin);
    test_scenario::return_shared(pool);
    
    test_scenario::end(scenario_value);
}
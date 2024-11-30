#[test_only]
module haedal_pmm::oracle_driven_pool_tests;
// uncomment this line to import the module

use sui::test_scenario;
use haedal_pmm::oracle_driven_pool::{Self, Pool};
use haedal_pmm::ownable::{AdminCap};


use haedal_pmm::usdc::USDC;
use haedal_pmm::sui::SUI;

#[test]
fun test_new_pool() {

    let admin = @0xAA;

    let mut scenario_value = test_scenario::begin(admin);
    let scenario = &mut scenario_value;

    let mut admin_cap = t_pool_init(scenario);

    let pool = t_new_pool<SUI,USDC>(scenario, &mut admin_cap);


    test_scenario::return_to_address(admin, admin_cap);
    test_scenario::return_shared(pool);
    
    test_scenario::end(scenario_value);
}

#[test]
#[expected_failure]
fun test_re_new_pool() {

    let admin = @0xAA;

    let mut scenario_value = test_scenario::begin(admin);
    let scenario = &mut scenario_value;

    let mut admin_cap = t_pool_init(scenario);

    let pool = t_new_pool<SUI,USDC>(scenario, &mut admin_cap);
    let pool2 = t_new_pool<SUI,USDC>(scenario, &mut admin_cap);


    test_scenario::return_to_address(admin, admin_cap);
    test_scenario::return_shared(pool);
    test_scenario::return_shared(pool2);
    
    test_scenario::end(scenario_value);
}


#[test_only]
public fun t_new_pool<CoinTypeBase, CoinTypeQuote>(
    scenario: &mut test_scenario::Scenario, 
    admin_cap: &mut AdminCap
): Pool<CoinTypeBase, CoinTypeQuote> {
    // Pool Config
    let maintainer = @0xdd;
    let base_price_id = vector<u8>[];
    let quote_price_id = vector<u8>[];
    let lp_fee_rate = 2_000_000; // 0.002
    let protocol_fee_rate = 1_000_000; // 0.001
    let k = 100_000_000; // 0.1
    let base_coin_decimals = 9;
    let quote_coin_decimals = 9;

    let base_usd_price_age = 60;
    let quote_usd_price_age = 60;
    
    oracle_driven_pool::t_add_pool<CoinTypeBase, CoinTypeQuote>(
        admin_cap,
        base_coin_decimals,
        quote_coin_decimals,
        maintainer,
        base_price_id,
        quote_price_id,
        lp_fee_rate,
        protocol_fee_rate,
        k,
        base_usd_price_age,
        quote_usd_price_age,
        scenario.ctx());
    let sender = test_scenario::sender(scenario);
    test_scenario::next_tx(scenario, sender);
    let pool = test_scenario::take_shared<Pool<CoinTypeBase, CoinTypeQuote>>(scenario);
    pool
}

#[test_only]
public fun t_add_pool<CoinTypeBase, CoinTypeQuote>(
    scenario: &mut test_scenario::Scenario, 
    admin_cap: &mut AdminCap, 
    base_coin_decimals: u8,
    quote_coin_decimals: u8,
    maintainer: address, 
    base_price_id: vector<u8>,
    quote_price_id: vector<u8>, 
    lp_fee_rate: u64, 
    protocol_fee_rate: u64, 
    k: u64,
    base_usd_price_age:u64,
    quote_usd_price_age:u64,
): Pool<CoinTypeBase, CoinTypeQuote> {
    oracle_driven_pool::t_add_pool<CoinTypeBase, CoinTypeQuote>(
        admin_cap,
        base_coin_decimals,
        quote_coin_decimals,
        maintainer,
        base_price_id,
        quote_price_id,
        lp_fee_rate,
        protocol_fee_rate,
        k,
        base_usd_price_age,
        quote_usd_price_age,
        scenario.ctx());
    let sender = test_scenario::sender(scenario);
    test_scenario::next_tx(scenario, sender);
    let pool = test_scenario::take_shared<Pool<CoinTypeBase, CoinTypeQuote>>(scenario);
    pool
}

#[test_only]
public fun t_pool_init(scenario: &mut test_scenario::Scenario): AdminCap {
    oracle_driven_pool::init_t(scenario.ctx());

    let sender = test_scenario::sender(scenario);
    test_scenario::next_tx(scenario, sender);

    let admin_cap = test_scenario::take_from_address<AdminCap>(scenario,scenario.sender());
    admin_cap
}



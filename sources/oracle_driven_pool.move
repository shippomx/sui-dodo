/*
/// Module: haedal_pmm
module haedal_pmm::haedal_pmm;
*/
module haedal_pmm::oracle_driven_pool {

    use std::type_name::{Self};
    use std::ascii::{Self};
    use std::string::{String};
    use sui::clock::Clock;
    
    use pyth::price_info::PriceInfoObject;

    use sui::event;
    use sui::coin::{Self, Coin, CoinMetadata};
    use sui::balance::{Self, Supply, Balance};

    use haedal_pmm::version;
    use haedal_pmm::safe_math::{Self};
    use haedal_pmm::ownable::{Self, AdminCap};
    use haedal_pmm::oracle::{Self};

    const EWrongFeeRate: u64 = 1;
    const EWrongK: u64 = 2;
    const EDepositBaseNotAllowed: u64 = 3;
    const EDepositQuoteNotAllowed: u64 = 4;
    const EBaseBalanceNotEnough: u64 = 5;
    const EQuoteBalanceNotEnough: u64 = 6;
    const EBaseBalanceLimitExceeded: u64 = 7;
    const EQuoteBalanceLimitExceeded: u64 = 8;
    const ETradeNotAllowed:u64=9;
    const EBuyingNotAllowed:u64 = 10;
    const ESellingNotAllowed:u64 = 11;
    const EClosed:u64 = 12;
    const ENotClosed:u64 = 13;
    const EBaseOrQuoteCapitalBalanceNotEnough:u64 = 14;
    const EDataNotMatchProgram:u64 = 15;

    public enum RStatus has store, copy, drop{
        ONE,
        ABOVE_ONE,
        BELOW_ONE,
    }

    public struct Pool<phantom CoinTypeBase, phantom CoinTypeQuote> has key {
        id: UID,
        version: u64,

        controls: PoolControls,

        // ============ Core Address ============

        maintainer: address,                        // maintainer, collect maintainer fee to buy food for Haedal

        oracle_config: PoolOracleConfig,

        // ============ Variables for PMM Algorithm ============

        base_coin_decimals: u8,                 // base coin decimals
        quote_coin_decimals: u8,                // quote coin decimals

        lp_fee_rate: u64,                       // lp fee rate
        protocol_fee_rate: u64,                 // protocol fee rate
    
        core_data: PoolCoreData,

        coins: PoolCoins<CoinTypeBase, CoinTypeQuote>,

        // ============ Variables for Final Settlement ============

        settlement: PoolSettlement,

        tx_data: PoolTxData,                      // tx data
    }

    public struct PoolControls has store {
        // ============ Variables for Controls ============
        
        closed:bool,                            // is closed
        deposit_base_allowed: bool,             // is allowed to deposit base
        deposit_quote_allowed: bool,            // is allowed to deposit quote
        trade_allowed: bool,                    // is allowed to trade
        // gas_price_limit: u64,

        // ============ Advanced Controls ============

        buying_allowed: bool,                   // is allowed to buy
        selling_allowed: bool,                  // is allowed to sell
        base_balance_limit: u64,                // base balance limit
        quote_balance_limit: u64,               // quote balance limit
    }

    public struct PoolOracleConfig has store {
        base_price_id: vector<u8>,                   // pyth base price oracle id
        quote_price_id: vector<u8>,                   // pyth quote price oracle id
        base_usd_price_age: u64,                // base / usd price age
        quote_usd_price_age: u64,               // quote / usd price age
    }

    public struct PoolSettlement has store {
        base_capital_receive_quote: u64,        // base capital receive quote
        quote_capital_receive_base: u64,        // quote capital receive base
    }

    public struct PoolTxData has store {
        // ============ prev price cache ============
        base_usd_price: u64,                    // base / usd price
        quote_usd_price: u64,                   // quote / usd price
        base_quote_price: u64,                  // base / quote price

        // ============ index data ============
        trade_num: u64,                         // trade num
        liquidity_change_num: u64,              // liquidity change num
    }

    public struct PoolCoins<phantom CoinTypeBase, phantom CoinTypeQuote> has store {
        base_coin: Balance<CoinTypeBase>,       // base coin balance
        quote_coin: Balance<CoinTypeQuote>,     // quote coin balance

        base_capital_coin_supply: Supply<BasePoolLiquidityCoin<CoinTypeBase, CoinTypeQuote>>,      // base capital coin supply
        quote_capital_coin_supply: Supply<QuotePoolLiquidityCoin<CoinTypeBase, CoinTypeQuote>>,    // quote capital coin supply
    }

    public struct PoolCoreData has store {
        k: u64,                                 // k value, slippage, k / 1e9
        r_status: RStatus,                      // r status
        target_base_coin_amount: u64,           // target base coin amount
        target_quote_coin_amount: u64,          // target quote coin amount

        base_balance: u64,                      // base balance
        quote_balance: u64,                     // quote balance
    }


    public struct BasePoolLiquidityCoin<phantom BaseCoinType, phantom QuoteCoinType> has drop{}
    public struct QuotePoolLiquidityCoin<phantom BaseCoinType, phantom QuoteCoinType> has drop{}

    public struct PoolVersionUpdated has copy, drop {
        operator: address,
        old_version: u64,
        new_version: u64,
    }

    public struct AddPoolEvent has copy, drop {
        sender: address,
        pool_id: ID,
        lp_fee_rate: u64,
        protocol_fee_rate: u64,
        base_coin_type: String,
        quote_coin_type: String,
        k: u64,
    }

    public struct UpdateLiquidityProviderFeeRateEvent has copy, drop {
        operator: address,
        old_liquidity_provider_fee_rate: u64,
        new_liquidity_provider_fee_rate: u64,
    }

    public struct UpdateProtocolFeeRateEvent has copy, drop {
        operator: address,
        old_protocol_fee_rate: u64,
        new_protocol_fee_rate: u64,
    }

    public struct UpdateKEvent has copy, drop {
        operator: address,
        old_k: u64,
        new_k: u64,
    }

    public struct DonateEvent has copy, drop {
        pool_id: ID,
        amount: u64,
        is_base_coin: bool,
        is_lp_fee: bool,
        index: u64,
    }

    public struct ClaimAssetsEvent has copy, drop {
        pool_id: ID,
        user: address,
        base_coin_amount: u64,
        quote_coin_amount: u64,
        liquidity_change_num: u64,              // liquidity change num
    }

    // initialize
    fun init(ctx: &mut TxContext) {
        ownable::grant_admin_cap(ctx.sender(), ctx);
    }


    #[test_only]
    public fun init_t(ctx: &mut TxContext) {
        init( ctx)
    }

    // ============ Params Setting Functions ============

    public(package) fun set_base_usd_price_age<CoinTypeBase, CoinTypeQuote>(
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>, 
        new_base_usd_price_age: u64, 
    ) {
       pool.oracle_config.base_usd_price_age = new_base_usd_price_age;
    }

    public(package) fun set_quote_usd_price_age<CoinTypeBase, CoinTypeQuote>(
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>, 
        new_quote_usd_price_age: u64, 
    ) {
       pool.oracle_config.quote_usd_price_age = new_quote_usd_price_age;
    }

    public(package) fun set_prices<CoinTypeBase, CoinTypeQuote>(
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>, 
        quote_usd_price: u64, 
    ) {
       pool.tx_data.quote_usd_price = quote_usd_price;
    }

    public(package) fun set_liquidity_provider_fee_rate<CoinTypeBase, CoinTypeQuote>(pool: &mut Pool<CoinTypeBase, CoinTypeQuote>, new_liquidity_provider_fee_rate: u64, ctx: &TxContext) {
        event::emit(UpdateLiquidityProviderFeeRateEvent{
            operator: ctx.sender(),
            old_liquidity_provider_fee_rate: pool.lp_fee_rate,
            new_liquidity_provider_fee_rate,
        });

        pool.lp_fee_rate = new_liquidity_provider_fee_rate;
        pool.check_parameters();
    }

    public(package) fun set_protocol_fee_rate<CoinTypeBase, CoinTypeQuote>(pool: &mut Pool<CoinTypeBase, CoinTypeQuote>, new_protocol_fee_rate: u64, ctx: &TxContext) {
        event::emit(UpdateProtocolFeeRateEvent{
            operator: ctx.sender(),
            old_protocol_fee_rate: pool.protocol_fee_rate,
            new_protocol_fee_rate,
        });

        pool.protocol_fee_rate = new_protocol_fee_rate;
        pool.check_parameters();
    }

    public(package) fun set_k<CoinTypeBase, CoinTypeQuote>(pool: &mut Pool<CoinTypeBase, CoinTypeQuote>, new_k: u64, ctx: &TxContext) {
        event::emit(UpdateKEvent{
            operator: ctx.sender(),
            old_k: pool.core_data.k,
            new_k,
        });

        pool.core_data.k = new_k;
        pool.check_parameters();
    }

    public(package) fun set_target_base_coin_amount<CoinTypeBase, CoinTypeQuote>(pool: &mut Pool<CoinTypeBase, CoinTypeQuote>, new_target_base_coin_amount: u64) {
        if (new_target_base_coin_amount != pool.core_data.target_base_coin_amount) {
            pool.core_data.target_base_coin_amount = new_target_base_coin_amount;
        }
    }
    
    public(package) fun set_target_quote_coin_amount<CoinTypeBase, CoinTypeQuote>(pool: &mut Pool<CoinTypeBase, CoinTypeQuote>, new_target_quote_coin_amount: u64) {
        if (new_target_quote_coin_amount != pool.core_data.target_quote_coin_amount) {
            pool.core_data.target_quote_coin_amount = new_target_quote_coin_amount;
        }
    }

    public(package) fun set_r_status<CoinTypeBase, CoinTypeQuote>(pool: &mut Pool<CoinTypeBase, CoinTypeQuote>, new_r_status: RStatus) {
        if (new_r_status != pool.core_data.r_status) {
            pool.core_data.r_status = new_r_status;
        }
    }

    // ============ System Control Functions ============

    public(package) fun set_trade_allowed<CoinTypeBase, CoinTypeQuote>(pool: &mut Pool<CoinTypeBase, CoinTypeQuote>, new_trade_allowed: bool) {
        pool.controls.trade_allowed = new_trade_allowed;
    }

    public(package) fun set_deposit_quote_allowed<CoinTypeBase, CoinTypeQuote>(pool: &mut Pool<CoinTypeBase, CoinTypeQuote>, new_deposit_quote_allowed: bool) {
        pool.controls.deposit_quote_allowed = new_deposit_quote_allowed;
    }

    public(package) fun set_deposit_base_allowed<CoinTypeBase, CoinTypeQuote>(pool: &mut Pool<CoinTypeBase, CoinTypeQuote>, new_deposit_base_allowed: bool) {
        pool.controls.deposit_base_allowed = new_deposit_base_allowed;
    }

    // ============ Advanced Control Functions ============

    public(package) fun set_buying_allowed<CoinTypeBase, CoinTypeQuote>(pool: &mut Pool<CoinTypeBase, CoinTypeQuote>, new_buying_allowed: bool) {
        pool.controls.buying_allowed = new_buying_allowed;
    }

    public(package) fun set_selling_allowed<CoinTypeBase, CoinTypeQuote>(pool: &mut Pool<CoinTypeBase, CoinTypeQuote>, new_selling_allowed: bool) {
        pool.controls.selling_allowed = new_selling_allowed;
    }

    public(package) fun set_quote_balance_limit<CoinTypeBase, CoinTypeQuote>(pool: &mut Pool<CoinTypeBase, CoinTypeQuote>, new_quote_balance_limit: u64) {
        pool.controls.quote_balance_limit = new_quote_balance_limit;
    }

    public(package) fun set_base_balance_limit<CoinTypeBase, CoinTypeQuote>(pool: &mut Pool<CoinTypeBase, CoinTypeQuote>, new_base_balance_limit: u64) {
        pool.controls.base_balance_limit = new_base_balance_limit;
    }

    public(package) fun increase_trade_num<CoinTypeBase, CoinTypeQuote>(pool: &mut Pool<CoinTypeBase, CoinTypeQuote>) {
        pool.tx_data.trade_num = pool.tx_data.trade_num + 1
    }

    public(package) fun increase_liquidity_change_num<CoinTypeBase, CoinTypeQuote>(pool: &mut Pool<CoinTypeBase, CoinTypeQuote>) {
        pool.tx_data.liquidity_change_num = pool.tx_data.liquidity_change_num + 1
    }

    // ============ R = 1 cases ============
    fun r_one_sell_base_coin(primitive_price:u64, k:u64, amount:u64, target_quote_amount:u64):(u64){
        let q2 = safe_math::solve_quadratic_function_for_trade(
            target_quote_amount,
            target_quote_amount, 
            safe_math::mul(primitive_price,amount), 
            false, 
            k,
            );
        // in theory Q2 <= targetQuoteTokenAmount
        // however when amount is close to 0, precision problems may cause Q2 > targetQuoteTokenAmount
        target_quote_amount - q2
    }

    fun r_one_buy_base_coin(primitive_price:u64, k:u64, amount:u64, target_base_amount:u64):(u64){
        assert!(amount < target_base_amount, EBaseBalanceNotEnough);
        let b2 = target_base_amount - amount;
        r_above_integrate(primitive_price, k, target_base_amount, target_base_amount, b2)
    }
    
    // ============ R < 1 cases ============
    fun r_below_sell_base_coin(
        primitive_price:u64,
        k:u64,
        amount:u64,
        quote_balance:u64,
        target_quote_amount:u64
    ):(u64) {
        let q2 = safe_math::solve_quadratic_function_for_trade(
            target_quote_amount,
            quote_balance, 
            safe_math::mul(primitive_price,amount), 
            false, 
            k,
        );
        quote_balance - q2
    }

    fun r_below_buy_base_coin(
        primitive_price:u64,
        k:u64,
        amount:u64,
        quote_balance:u64,
        target_quote_amount:u64
    ):(u64) {
        // Here we don't require amount less than some value
        // Because it is limited at upper function
        // See Trader.queryBuyBaseToken
        let q2 = safe_math::solve_quadratic_function_for_trade(
            target_quote_amount,
            quote_balance, 
            safe_math::mul_ceil(primitive_price,amount), 
            true, 
            k,
        );
        q2 - quote_balance
    }

    fun get_expected_target_by_r_below_one<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>, primitive_price:u64):(u64, u64) {
        let q:u64 = pool.get_quote_balance();
        let pay_quote_coin:u64 = pool.r_below_back_to_one(primitive_price);
        (pool.core_data.target_base_coin_amount, q + pay_quote_coin)
    }

    // r < 1, Q < Q0, r back to 1
    fun r_below_back_to_one<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>, price:u64):(u64) {
        let quote_balance = pool.get_quote_balance();
        let spare_base:u64 = pool.get_base_balance() - pool.core_data.target_base_coin_amount;
        // important: carefully design the system to make sure spareBase always greater than or equal to 0
        let fair_amount   = safe_math::mul(spare_base, price);
        let new_target_quote = safe_math::solve_quadratic_function_for_target(
            quote_balance, 
            pool.get_k(), 
            fair_amount);
        (new_target_quote - quote_balance)
    }

    // ============ R > 1 cases ============
    fun r_above_buy_base_coin(
        primitive_price:u64,
        k:u64,
        amount:u64,
        base_balance:u64,
        target_base_amount:u64):(u64) {
        // TODO    require(amount < baseBalance, "DODO_BASE_BALANCE_NOT_ENOUGH");
        let b2 = base_balance - amount;
        r_above_integrate(primitive_price, k, target_base_amount, base_balance, b2)
    }

    fun r_above_sell_base_coin(
        primitive_price:u64,
        k:u64,
        amount:u64,
        base_balance:u64,
        target_base_amount:u64):(u64) {
        let b1 = base_balance + amount;
        r_above_integrate(primitive_price, k, target_base_amount, b1, base_balance)
    }

    fun r_above_back_to_one<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>, price:u64):u64 {
        let base_balance = pool.get_base_balance();
        let spare_quote:u64 = pool.get_quote_balance() - pool.get_target_quote_coin_amount();
        // important: carefully design the system to make sure spareBase always greater than or equal to 0
        let fair_amount  = safe_math::div_floor(spare_quote,price);
        let new_target_base = safe_math::solve_quadratic_function_for_target(base_balance, pool.get_k(), fair_amount);
        new_target_base - base_balance
    }

    fun r_above_integrate(
        primitive_price:u64,
        k:u64,
        b0:u64,
        b1:u64,
        b2:u64
    ) :u64 {
        safe_math::general_integrate(b0, b1, b2, primitive_price, k)
    }

    fun get_expected_target_by_r_above_one<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>, primitive_price:u64):(u64, u64) {
        let b:u64 = pool.get_base_balance();
        let pay_base_coin:u64 = pool.r_above_back_to_one(primitive_price);
        (b + pay_base_coin, pool.get_target_quote_coin_amount())
    }

    // ============ Helper Functions ============

    public fun get_expected_target_by_oracle<CoinTypeBase, CoinTypeQuote>(
        pool: &Pool<CoinTypeBase, CoinTypeQuote>, 
        clock: &Clock, 
        base_price_pair_obj: &PriceInfoObject, 
        quote_price_pair_obj: &PriceInfoObject, 
    ): (u64, u64) {
        let (base_price_id, quote_price_id) = pool.get_price_id();
        let (primitive_price,_,_) = oracle::calculate_pyth_primitive_prices(
            base_price_id,
            quote_price_id,
            clock,
            base_price_pair_obj,
            quote_price_pair_obj,
            pool.get_quote_coin_decimals(),
            pool.get_base_usd_price_age(),
            pool.get_quote_usd_price(),
        );
        pool.get_expected_target(primitive_price)
    }
    
    public fun get_expected_target<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>, primitive_price:u64):(u64, u64) {
        match (pool.get_r_status()) {
            RStatus::ONE => (pool.get_target_base_coin_amount(), pool.get_target_quote_coin_amount()),
            RStatus::BELOW_ONE => pool.get_expected_target_by_r_below_one(primitive_price),
            RStatus::ABOVE_ONE => pool.get_expected_target_by_r_above_one(primitive_price),
        }
    }

    public fun get_withdraw_base_penalty<CoinTypeBase,CoinTypeQuote>(pool: &Pool<CoinTypeBase,CoinTypeQuote>, primitive_price:u64, amount:u64) :(u64) {
        assert!(amount <= pool.get_base_balance(), EBaseBalanceNotEnough);
        match (pool.get_r_status()) {
            RStatus::ONE => 0,
            RStatus::BELOW_ONE => 0,
            RStatus::ABOVE_ONE => pool.get_withdraw_base_penalty_by_r_above_one(primitive_price, amount),
        }
    }

    fun get_withdraw_base_penalty_by_r_above_one<CoinTypeBase,CoinTypeQuote>(pool: &Pool<CoinTypeBase,CoinTypeQuote>, price: u64, amount:u64) :(u64) {
        let base_balance = pool.get_base_balance();
        let spare_quote = pool.get_quote_balance() - pool.get_target_quote_coin_amount();
        let fair_amount = safe_math::div_floor(spare_quote, price);
        let target_base = safe_math::solve_quadratic_function_for_target(base_balance, pool.get_k(), fair_amount);
        // if amount = _BASE_BALANCE_, div error
        let target_base_with_withdraw = safe_math::solve_quadratic_function_for_target(base_balance - amount, pool.get_k(), fair_amount);
        target_base - (target_base_with_withdraw + amount)
    }

    public fun get_withdraw_quote_penalty<CoinTypeBase,CoinTypeQuote>(pool: &Pool<CoinTypeBase,CoinTypeQuote>, primitive_price:u64, amount:u64) :(u64) {
        assert!(amount <= pool.get_quote_balance(), EQuoteBalanceNotEnough);
        match (pool.get_r_status()) {
            RStatus::ONE => 0,
            RStatus::BELOW_ONE => pool.get_withdraw_quote_penalty_by_r_below_one(primitive_price, amount),
            RStatus::ABOVE_ONE => 0,
        }
    }

    fun get_withdraw_quote_penalty_by_r_below_one<CoinTypeBase,CoinTypeQuote>(pool: &Pool<CoinTypeBase,CoinTypeQuote>, price:u64, amount:u64) :(u64) {
        let quote_balance = pool.get_quote_balance();
        let spare_base = pool.get_base_balance() - pool.get_target_base_coin_amount();
        let fair_amount = safe_math::mul(spare_base, price);
        let target_quote = safe_math::solve_quadratic_function_for_target(quote_balance, pool.get_k(), fair_amount);
        // if amount = _BASE_BALANCE_, div error
        let target_quote_with_withdraw = safe_math::solve_quadratic_function_for_target(quote_balance - amount, pool.get_k(), fair_amount);
        std::debug::print(&target_quote);
        std::debug::print(&(target_quote_with_withdraw + amount));
        target_quote - (target_quote_with_withdraw + amount)
    }

    public fun query_sell_base_coin<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>, primitive_price:u64, amount:u64):(u64, u64, u64, RStatus, u64, u64){
        let (new_base_target, new_quote_target) = pool.get_expected_target(primitive_price);
     
        let sell_base_amount = amount;
        let (mut receive_quote, new_r_status) = match (pool.get_r_status()) {
            RStatus::ONE => pool.query_sell_base_coin_by_r_one(primitive_price, sell_base_amount, new_quote_target),
            RStatus::ABOVE_ONE => pool.query_sell_base_coin_by_r_above_one(primitive_price, sell_base_amount, new_base_target, new_quote_target),
            RStatus::BELOW_ONE => pool.query_sell_base_coin_by_r_below_one(primitive_price, sell_base_amount, new_quote_target),
        };

        // count fees
        let lp_fee_quote = safe_math::mul(receive_quote, pool.get_lp_fee_rate());
        let protocol_fee_quote = safe_math::mul(receive_quote, pool.get_protocol_fee_rate());
        receive_quote = receive_quote - lp_fee_quote - protocol_fee_quote;

        (receive_quote, lp_fee_quote, protocol_fee_quote, new_r_status, new_quote_target, new_base_target)
    }

    fun query_sell_base_coin_by_r_one<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>, primitive_price:u64, sell_base_amount:u64, new_quote_target:u64):(u64, RStatus){
        // case 1: R=1
        // R falls below one
        let receive_quote = r_one_sell_base_coin(primitive_price, pool.get_k(), sell_base_amount, new_quote_target);
        (receive_quote, RStatus::BELOW_ONE)
    }

    fun query_sell_base_coin_by_r_above_one<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>, primitive_price:u64, sell_base_amount:u64, new_base_target:u64, new_quote_target:u64):(u64, RStatus){
        // case 2: R>1
        // complex case, R status depends on trading amount
        let back_to_one_pay_base = new_base_target - pool.get_base_balance(); // newBaseTarget.sub(_BASE_BALANCE_);
        let back_to_one_receive_quote = pool.get_quote_balance() - new_quote_target; // _QUOTE_BALANCE_.sub(newQuoteTarget);
        if (sell_base_amount < back_to_one_pay_base) {
            // case 2.1: R status do not change
            let mut receive_quote = r_above_sell_base_coin( primitive_price, pool.get_k(), sell_base_amount, pool.get_base_balance(), new_base_target);
            // new_r_status = RStatus::ABOVE_ONE;
            if (receive_quote > back_to_one_receive_quote) {
                // [Important corner case!] may enter this branch when some precision problem happens. And consequently contribute to negative spare quote amount
                // to make sure spare quote>=0, mannually set receiveQuote=backToOneReceiveQuote
                receive_quote = back_to_one_receive_quote;
            };
            (receive_quote, RStatus::ABOVE_ONE)
        } else if (sell_base_amount == back_to_one_pay_base) {
            // case 2.2: R status changes to ONE
            (back_to_one_receive_quote,RStatus::ONE)
        } else {
            // case 2.3: R status changes to BELOW_ONE
            (back_to_one_receive_quote + r_one_sell_base_coin(
                primitive_price,
                pool.get_k(), 
                sell_base_amount - back_to_one_pay_base, 
                new_quote_target
                ),
            RStatus::BELOW_ONE)
        }
    }

    fun query_sell_base_coin_by_r_below_one<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>, primitive_price:u64, sell_base_amount:u64, new_quote_target:u64):(u64, RStatus){
        // _R_STATUS_ == Types.RStatus.BELOW_ONE
        // case 3: R<1
        let receive_quote = r_below_sell_base_coin(primitive_price, pool.get_k(), sell_base_amount, pool.get_quote_balance(), new_quote_target);
        (receive_quote, RStatus::BELOW_ONE)
    }


    public fun query_buy_base_coin<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>, primitive_price:u64, amount:u64):(u64, u64, u64, RStatus, u64, u64){
        let (new_base_target, new_quote_target) = pool.get_expected_target(primitive_price);

        // charge fee from user receive amount
        let lp_fee_base = safe_math::mul(amount, pool.get_lp_fee_rate());
        let protocol_fee_base = safe_math::mul(amount, pool.get_protocol_fee_rate());
        let buy_base_amount = amount + lp_fee_base + protocol_fee_base;

        let (pay_quote, new_r_status) = match (pool.get_r_status()) {
            RStatus::ONE => pool.query_buy_base_coin_by_r_one(primitive_price, buy_base_amount, new_base_target),
            RStatus::ABOVE_ONE => pool.query_buy_base_coin_by_r_above_one(primitive_price, buy_base_amount, new_base_target),
            RStatus::BELOW_ONE => pool.query_buy_base_coin_by_r_below_one(primitive_price, buy_base_amount, new_base_target, new_quote_target),
        };

        (pay_quote, lp_fee_base, protocol_fee_base, new_r_status, new_quote_target, new_base_target)
    }

    fun query_buy_base_coin_by_r_one<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>, primitive_price:u64, buy_base_amount:u64, new_base_target:u64):(u64, RStatus){
        // case 1: R=1
        let pay_quote = r_one_buy_base_coin(primitive_price, pool.get_k(), buy_base_amount, new_base_target);
        (pay_quote, RStatus::ABOVE_ONE)
    }
    fun query_buy_base_coin_by_r_above_one<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>, primitive_price:u64, buy_base_amount:u64, new_base_target:u64):(u64, RStatus){
        // case 2: R>1
        let pay_quote = r_above_buy_base_coin(primitive_price, pool.get_k(), buy_base_amount, pool.get_base_balance(), new_base_target);
        (pay_quote, RStatus::ABOVE_ONE)
    }

    fun query_buy_base_coin_by_r_below_one<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>, primitive_price:u64, buy_base_amount:u64, new_base_target:u64, new_quote_target:u64):(u64, RStatus){
        // case 3: R<1
        let back_to_one_pay_quote = new_quote_target - pool.get_quote_balance();
        let back_to_one_receive_base = pool.get_base_balance() - new_base_target;
        // complex case, R status may change
        if (buy_base_amount < back_to_one_receive_base) {
            // case 3.1: R status do not change
            // no need to check payQuote because spare base token must be greater than zero
            (r_below_buy_base_coin(primitive_price, pool.get_k(), buy_base_amount, pool.get_quote_balance(), new_quote_target), RStatus::BELOW_ONE)
        } else if (buy_base_amount == back_to_one_receive_base) {
            // case 3.2: R status changes to ONE
            (back_to_one_pay_quote, RStatus::ONE)
        } else {
            // case 3.3: R status changes to ABOVE_ONE
            (back_to_one_pay_quote + r_one_buy_base_coin(primitive_price, pool.get_k(), buy_base_amount - back_to_one_receive_base, new_base_target), RStatus::ABOVE_ONE)
        }
    }

    // ============ Assert ============
    public fun check_parameters<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>) {
        assert!(
            safe_math::lt_one(pool.get_k()),
            EWrongK); // Error: K>=1
        assert!(
            pool.get_k() > 0,
            EWrongK); // Error: K>0
        assert!(
            safe_math::lt_one(pool.get_lp_fee_rate() + pool.get_protocol_fee_rate()),
            EWrongFeeRate); // Error: fee_rate >= 1
    }

    public fun assert_deposit_base_allowed<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>) {
        assert!(
            pool.controls.deposit_base_allowed,
            EDepositBaseNotAllowed);
    }

    public fun assert_deposit_quote_allowed<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>) {
        assert!(
            pool.controls.deposit_quote_allowed,
            EDepositQuoteNotAllowed);
    }

    public fun assert_trade_allowed<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>) {
        assert!(
            pool.controls.trade_allowed,
            ETradeNotAllowed);
    }

    public fun assert_buying_allowed<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>) {
        assert!(
            pool.controls.buying_allowed,
            EBuyingNotAllowed);
    }

    public fun assert_selling_allowed<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>) {
        assert!(
            pool.controls.selling_allowed,
            ESellingNotAllowed);
    }

    public fun assert_not_closed<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>) {
        assert!(
            !pool.get_closed(),
            EClosed);
    }

    public fun assert_closed<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>) {
        assert!(
            pool.get_closed(),
            ENotClosed);
    }

    // ============ Getter ============

    public fun get_closed<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>):bool {
        pool.controls.closed
    }

    public fun get_lp_fee_rate<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>):u64 {
        pool.lp_fee_rate
    }

    public fun get_protocol_fee_rate<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>):u64 {
        pool.protocol_fee_rate
    }

    public fun get_base_usd_price_age<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>):u64 {
        pool.oracle_config.base_usd_price_age
    }

    public fun get_quote_usd_price_age<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>):u64 {
        pool.oracle_config.quote_usd_price_age
    }

    public fun get_base_coin_decimals<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>):u8 {
        pool.quote_coin_decimals
    }

    public fun get_quote_coin_decimals<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>):u8 {
        pool.quote_coin_decimals
    }

    public fun get_price_id<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>):(vector<u8>, vector<u8>) {
        (pool.oracle_config.base_price_id, pool.oracle_config.quote_price_id)
    }

    public fun get_quote_usd_price<CoinTypeBase, CoinTypeQuote>(
        pool: &Pool<CoinTypeBase, CoinTypeQuote>
    ): (u64) {
       pool.tx_data.quote_usd_price
    }

    public fun get_maintainer<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>):(address) {
        pool.maintainer
    }

    public fun get_base_balance<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>):(u64) {
        pool.core_data.base_balance
    }

    public fun get_quote_balance<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>):(u64) {
        pool.core_data.quote_balance
    }

    public fun get_base_capital_coin_supply<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>):(u64) {
        pool.coins.base_capital_coin_supply.supply_value()
    }

    public fun get_quote_capital_coin_supply<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>):(u64) {
        pool.coins.quote_capital_coin_supply.supply_value()
    }

    public fun get_lp_base_balance<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>, primitive_price:u64, base_capital_coin_amount: u64):(u64){
        let total_base_capital =pool.get_base_capital_coin_supply();
        let (base_target,_) = pool.get_expected_target(primitive_price);
        if (total_base_capital == 0) {
            0
        }else {
            safe_math::safe_mul_div_u64(base_capital_coin_amount, base_target, total_base_capital)
        }
    }

    public fun get_lp_quote_balance<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>, primitive_price:u64, quote_capital_coin_amount: u64):(u64){
        let total_quote_capital = pool.get_quote_capital_coin_supply();
        let (_, quote_target) = pool.get_expected_target(primitive_price);
        let (amount) = if (total_quote_capital == 0) {
            0
        }else {
            safe_math::safe_mul_div_u64(quote_capital_coin_amount, quote_target, total_quote_capital)
        };
        amount
    }

    #[test_only]
    public fun get_fee_rate<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>):(u64, u64){
        (pool.lp_fee_rate, pool.protocol_fee_rate)
    }

    #[test_only]
    public fun get_balance_limit<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>):(u64, u64){
        (pool.controls.base_balance_limit, pool.controls.quote_balance_limit)
    }
    
    public fun get_base_balance_limit<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>):(u64){
        (pool.controls.base_balance_limit)
    }

    public fun get_quote_balance_limit<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>):(u64){
        (pool.controls.quote_balance_limit)
    }

    #[test_only]
    public fun get_balance<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>):(u64, u64){
        (pool.get_base_balance(), pool.get_quote_balance())
    }

    public fun get_target_amount<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>):(u64, u64){
        (pool.core_data.target_base_coin_amount, pool.core_data.target_quote_coin_amount)
    }

    public fun get_target_base_coin_amount<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>):(u64){
        (pool.core_data.target_base_coin_amount)
    }

    public fun get_target_quote_coin_amount<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>):(u64){
        (pool.core_data.target_quote_coin_amount)
    }

    public fun get_r_status<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>):(RStatus){
        (pool.core_data.r_status)
    }

    public fun get_k<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>):(u64){
        pool.core_data.k
    }

    public fun get_trade_num<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>):(u64){
        pool.tx_data.trade_num
    }

    public fun get_liquidity_change_num<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>):(u64){
        pool.tx_data.liquidity_change_num
    }

    // ============ Operator Functions ============

    public fun add_pool<CoinTypeBase, CoinTypeQuote>(
        admin_cap: &mut AdminCap,
        base_coin_metadata: &CoinMetadata<CoinTypeBase>,
        quote_coin_metadata: &CoinMetadata<CoinTypeQuote>,
        maintainer: address,
        base_price_id: vector<u8>,
        quote_price_id: vector<u8>,
        lp_fee_rate:u64,
        protocol_fee_rate:u64,
        k:u64,
        base_usd_price_age:u64,
        quote_usd_price_age:u64,
        ctx: &mut TxContext
    ) {
        admin_cap.assert_version();
        let pool = make_pool<CoinTypeBase,CoinTypeQuote>(
            base_coin_metadata.get_decimals(),
            quote_coin_metadata.get_decimals(),
            maintainer,
            base_price_id,
            quote_price_id,
            lp_fee_rate,
            protocol_fee_rate,
            k,
            base_usd_price_age,
            quote_usd_price_age,
            ctx);
        let pool_id = object::id(&pool); 

        pool.check_parameters();

        // register pool
        let baseType = type_name::get<CoinTypeBase>().into_string();
        let quoteType = type_name::get<CoinTypeQuote>().into_string();
        
        let mut lpkey = baseType;
        // ascii::append(&mut baseType, b"_".to_ascii_string());
        ascii::append(&mut lpkey, quoteType);

        admin_cap.register_pool(lpkey.to_string(),pool_id);

        transfer::share_object(pool);

        event::emit(AddPoolEvent{
            sender: ctx.sender(),
            pool_id,
            lp_fee_rate,
            protocol_fee_rate,
            k,
            base_coin_type: baseType.to_string(),
            quote_coin_type: quoteType.to_string(),
        });
    }

    #[test_only]
    public fun t_add_pool<CoinTypeBase, CoinTypeQuote>(
        admin_cap: &mut AdminCap,
        base_coin_decimals: u8,
        quote_coin_decimals: u8,
        maintainer: address,
        base_price_id: vector<u8>,
        quote_price_id: vector<u8>,
        lp_fee_rate:u64,
        protocol_fee_rate:u64,
        k:u64,
        base_usd_price_age:u64,
        quote_usd_price_age:u64,
        ctx: &mut TxContext
    ) {
        admin_cap.assert_version();
        let pool = make_pool<CoinTypeBase,CoinTypeQuote>(
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
            ctx);
        let pool_id = object::id(&pool); 

        pool.check_parameters();

        // register pool
        let baseType = type_name::get<CoinTypeBase>().into_string();
        let quoteType = type_name::get<CoinTypeQuote>().into_string();
        
        let mut lpkey = baseType;
        // ascii::append(&mut baseType, b"_".to_ascii_string());
        ascii::append(&mut lpkey, quoteType);

        admin_cap.register_pool(lpkey.to_string(),pool_id);

        transfer::share_object(pool);

        event::emit(AddPoolEvent{
            sender: ctx.sender(),
            pool_id,
            lp_fee_rate,
            protocol_fee_rate,
            k,
            base_coin_type: baseType.to_string(),
            quote_coin_type: quoteType.to_string(),
        });
    }

    fun make_pool<CoinTypeBase, CoinTypeQuote>(
        base_coin_decimals: u8,
        quote_coin_decimals: u8,
        maintainer: address,
        base_price_id:vector<u8>,
        quote_price_id:vector<u8>,
        lp_fee_rate:u64,
        protocol_fee_rate:u64, 
        k:u64,
        base_usd_price_age:u64,
        quote_usd_price_age:u64,
        ctx: &mut TxContext
    ): Pool<CoinTypeBase, CoinTypeQuote> {

        let base_capital_coin_supply = balance::create_supply(BasePoolLiquidityCoin<CoinTypeBase, CoinTypeQuote>{});
        let quote_capital_coin_supply = balance::create_supply(QuotePoolLiquidityCoin<CoinTypeBase, CoinTypeQuote>{});
        // let maxu64 = 18446744073709551615u64;

        Pool<CoinTypeBase, CoinTypeQuote> {
            id: object::new(ctx),
            version: version::get_program_version(),

            // ============ Variables for Control ============
            controls: PoolControls {
                closed:false,
                deposit_base_allowed:true,
                deposit_quote_allowed:true,
                trade_allowed: true,

                // ============ Advanced Controls ============

                buying_allowed: true,
                selling_allowed: true,
                base_balance_limit: std::u64::max_value!(),
                quote_balance_limit: std::u64::max_value!(),
            },
            // ============ Core Address ============

            maintainer: maintainer,

            oracle_config: PoolOracleConfig{
                base_price_id: base_price_id,
                quote_price_id: quote_price_id,
                base_usd_price_age,
                quote_usd_price_age,
            },
            
            // ============ Variables for PMM Algorithm ============
            base_coin_decimals,
            quote_coin_decimals,
            lp_fee_rate,
            protocol_fee_rate,
            core_data: PoolCoreData{
                k,
                r_status: RStatus::ONE,
                target_base_coin_amount: 0,
                target_quote_coin_amount: 0,

                base_balance: 0,
                quote_balance: 0,
            },

            coins: PoolCoins {
                base_coin: balance::zero<CoinTypeBase>(),
                quote_coin: balance::zero<CoinTypeQuote>(),

                base_capital_coin_supply,
                quote_capital_coin_supply,
            },

            // ============ Variables for Final Settlement ============
            settlement: PoolSettlement {
                base_capital_receive_quote:0,
                quote_capital_receive_base:0,
            },

            tx_data: PoolTxData{
                // ============ prev price cache ============
                base_usd_price: 0,                   
                quote_usd_price: 0,                   
                base_quote_price: 0,                  

                // ============ index data ============
                trade_num: 0,                         // trade num
                liquidity_change_num: 0,              // liquidity change num
            },
        }
    }

    public(package) fun mint_base_capital<CoinTypeBase, CoinTypeQuote>(
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
        balance: Balance<CoinTypeBase>,
        capital: u64,
        ctx: &mut TxContext
    ): Coin<BasePoolLiquidityCoin<CoinTypeBase, CoinTypeQuote>> {
        let amount = balance.value();

        pool.base_coin_pay_in(balance);

        pool.core_data.target_base_coin_amount = pool.get_target_base_coin_amount() + amount;

        coin::from_balance(
            balance::increase_supply(
                &mut pool.coins.base_capital_coin_supply,
                capital
            ), ctx)
    }

    public(package) fun mint_quote_capital<CoinTypeBase, CoinTypeQuote>(
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
        balance: Balance<CoinTypeQuote>,
        capital:u64,
        ctx: &mut TxContext
    ): Coin<QuotePoolLiquidityCoin<CoinTypeBase, CoinTypeQuote>> {
        let amount = balance::value(&balance);

        pool.quote_coin_pay_in(balance);

        pool.core_data.target_quote_coin_amount = pool.get_target_quote_coin_amount() + amount;

        coin::from_balance(
            balance::increase_supply(
                &mut pool.coins.quote_capital_coin_supply,
                capital
            ), ctx)
    }

    public(package) fun burn_base_capital_coin<CoinTypeBase, CoinTypeQuote>(
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
        to_burn: Balance<BasePoolLiquidityCoin<CoinTypeBase, CoinTypeQuote>>,
        penalty: u64,
    ) {
        balance::decrease_supply(&mut pool.coins.base_capital_coin_supply, to_burn);
        let index = pool.get_liquidity_change_num();
        pool.donate_base_coin(penalty, false, index);
    }

    public(package) fun burn_quote_capital_coin<CoinTypeBase, CoinTypeQuote>(
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
        to_burn: Balance<QuotePoolLiquidityCoin<CoinTypeBase, CoinTypeQuote>>,
        penalty: u64,
    ) {
        balance::decrease_supply(&mut pool.coins.quote_capital_coin_supply, to_burn);
        let index = pool.get_liquidity_change_num();
        pool.donate_quote_coin(penalty, false, index);
    }
    
    // ============ Assets IN/OUT Functions ============

    public(package) fun base_coin_pay_in<CoinTypeBase, CoinTypeQuote>(pool: &mut Pool<CoinTypeBase, CoinTypeQuote>, balance: Balance<CoinTypeBase>) {
        pool.core_data.base_balance = pool.get_base_balance() + balance.value();
        assert!(pool.get_base_balance() <= pool.get_base_balance_limit(), EBaseBalanceLimitExceeded);
        pool.coins.base_coin.join(balance);
    }

    public(package) fun base_coin_pay_out<CoinTypeBase, CoinTypeQuote>(pool: &mut Pool<CoinTypeBase, CoinTypeQuote>, receive_base_amount: u64, to:address, ctx: &mut TxContext) {
        pool.core_data.base_balance = pool.get_base_balance() - receive_base_amount;
        let receive_base_balance = balance::split(&mut pool.coins.base_coin, receive_base_amount);
        let base_coin = coin::from_balance(receive_base_balance, ctx);
        transfer::public_transfer(base_coin, to)
    }

    public(package) fun quote_coin_pay_in<CoinTypeBase, CoinTypeQuote>(pool: &mut Pool<CoinTypeBase, CoinTypeQuote>, balance: Balance<CoinTypeQuote>) {
        pool.core_data.quote_balance = pool.get_quote_balance() + balance.value();
        assert!(pool.get_quote_balance() <= pool.get_quote_balance_limit(), EQuoteBalanceLimitExceeded);
        pool.coins.quote_coin.join(balance);
    }

    public(package) fun quote_coin_pay_out<CoinTypeBase, CoinTypeQuote>(pool: &mut Pool<CoinTypeBase, CoinTypeQuote>, receive_quote_amount: u64, to:address, ctx: &mut TxContext) {
        pool.core_data.quote_balance = pool.get_quote_balance() - receive_quote_amount;
        let receive_quote_balance = balance::split(&mut pool.coins.quote_coin, receive_quote_amount);
        let quote_coin = coin::from_balance(receive_quote_balance, ctx);
        transfer::public_transfer(quote_coin, to)
    }

    // ============ Donate to Liquidity Pool Functions ============

    public(package) fun donate_base_coin<CoinTypeBase, CoinTypeQuote>(pool: &mut Pool<CoinTypeBase, CoinTypeQuote>, amount:u64, is_lp_fee: bool, index: u64) {
        pool.core_data.target_base_coin_amount = pool.get_target_base_coin_amount() + amount;
        event::emit(DonateEvent{
            pool_id: object::id(pool),
            amount: amount, 
            is_base_coin: true,
            is_lp_fee: is_lp_fee,
            index: index
        })
    }

    public(package) fun donate_quote_coin<CoinTypeBase, CoinTypeQuote>(pool: &mut Pool<CoinTypeBase, CoinTypeQuote>, amount:u64, is_lp_fee: bool, index: u64) {
        pool.core_data.target_quote_coin_amount = pool.get_target_quote_coin_amount() + amount;
        event::emit(DonateEvent{
            pool_id: object::id(pool),
            amount: amount, 
            is_base_coin: false,
            is_lp_fee: is_lp_fee,
            index: index
        })
    }

    // ============ Final Settlement Functions ============

    public(package) fun final_settlement<CoinTypeBase, CoinTypeQuote>(pool: &mut Pool<CoinTypeBase, CoinTypeQuote>) {
        pool.assert_not_closed();

        pool.controls.closed = true;
        pool.controls.deposit_base_allowed = false;
        pool.controls.deposit_quote_allowed = false;
        pool.controls.trade_allowed = false;
        
        let total_base_capital = pool.get_base_capital_coin_supply();
        let total_quote_capital = pool.get_quote_capital_coin_supply();

        if (pool.get_quote_balance() > pool.get_target_quote_coin_amount()) {
            let spare_quote = pool.get_quote_balance() - pool.get_target_quote_coin_amount();
            pool.settlement.base_capital_receive_quote = safe_math::div_floor(spare_quote, total_base_capital);
        } else {
            pool.core_data.target_quote_coin_amount = pool.get_quote_balance();
        };

        if (pool.get_base_balance() > pool.get_target_base_coin_amount()) {
            let spare_base = pool.get_base_balance() - pool.get_target_base_coin_amount();
            pool.settlement.quote_capital_receive_base = safe_math::div_floor(spare_base, total_quote_capital);
        }else {
            pool.core_data.target_base_coin_amount = pool.get_base_balance();
        };

        pool.core_data.r_status = RStatus::ONE;
    }

    public(package) fun claim_assets<CoinTypeBase, CoinTypeQuote>(
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
        base_capital_coin: Coin<BasePoolLiquidityCoin<CoinTypeBase, CoinTypeQuote>>,
        quote_capital_coin: Coin<QuotePoolLiquidityCoin<CoinTypeBase, CoinTypeQuote>>,
        ctx: &mut TxContext
    ) {
        pool.assert_closed();
        pool.increase_liquidity_change_num();

        let quote_capital = quote_capital_coin.value();
        let base_capital = base_capital_coin.value();

        assert!(quote_capital > 0 || base_capital > 0, EBaseOrQuoteCapitalBalanceNotEnough); 

        let mut _quote_amount = if (quote_capital > 0) {
            safe_math::safe_mul_div_u64( pool.get_target_quote_coin_amount(), quote_capital, pool.get_quote_capital_coin_supply())
        }else {
            0
        };

        let mut _base_amount = if (base_capital > 0) {
            safe_math::safe_mul_div_u64( pool.get_target_base_coin_amount(), base_capital, pool.get_base_capital_coin_supply())
        }else {
            0
        };

        pool.core_data.target_quote_coin_amount = pool.get_target_quote_coin_amount() - _quote_amount;
        pool.core_data.target_base_coin_amount = pool.get_target_base_coin_amount() - _base_amount;

        _quote_amount = _quote_amount + safe_math::mul(base_capital, pool.settlement.base_capital_receive_quote);
        _base_amount = _base_amount + safe_math::mul(quote_capital, pool.settlement.quote_capital_receive_base);

        pool.base_coin_pay_out(_base_amount, ctx.sender(), ctx);
        pool.quote_coin_pay_out(_quote_amount, ctx.sender(), ctx);

        let base_capital_balance = coin::into_balance(base_capital_coin);
        let quote_capital_balance = coin::into_balance(quote_capital_coin);

        balance::decrease_supply(&mut pool.coins.base_capital_coin_supply, base_capital_balance);
        balance::decrease_supply(&mut pool.coins.quote_capital_coin_supply, quote_capital_balance);

        event::emit(ClaimAssetsEvent{
            pool_id: object::id(pool),
            user: ctx.sender(),
            base_coin_amount:_base_amount,
            quote_coin_amount:_quote_amount,
            liquidity_change_num: pool.get_liquidity_change_num()
        })
    }

    #[allow(lint(self_transfer))]
    public(package) fun return_back_or_delete<CoinType>(
        balance: Balance<CoinType>,
        ctx: &mut TxContext
    ) {
        if(balance::value(&balance) > 0) {
            transfer::public_transfer(coin::from_balance(balance , ctx), ctx.sender());
        } else {
            balance::destroy_zero(balance);
        }
    }


    public(package) fun destroy_pool<CoinTypeBase, CoinTypeQuote>(
        admin_cap: &mut AdminCap,
    ) {
        // delete pool
        let baseType = type_name::get<CoinTypeBase>().into_string();
        let quoteType = type_name::get<CoinTypeQuote>().into_string();
        
        let mut lpkey = baseType;
        // ascii::append(&mut baseType, b"_".to_ascii_string());
        ascii::append(&mut lpkey, quoteType);

        admin_cap.destroy_pool(lpkey.to_string());
    }

    public fun assert_version<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>) {
        assert!(pool.version == version::get_program_version(), EDataNotMatchProgram);
    }

    public(package) fun migrate<CoinTypeBase, CoinTypeQuote>(pool: &mut Pool<CoinTypeBase, CoinTypeQuote>, ctx: &TxContext) {
        let version = version::get_program_version();
        assert!(pool.version < version, EDataNotMatchProgram);
        event::emit(PoolVersionUpdated{old_version: pool.version, new_version: version, operator: ctx.sender()});
        pool.version = version;
    }
}

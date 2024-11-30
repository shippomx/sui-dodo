module haedal_pmm::trader {

    use sui::event;
    use sui::balance;
    use sui::coin::{Self,Coin};    
    use sui::clock::Clock;
    
    use pyth::price_info::PriceInfoObject;

    use haedal_pmm::oracle;
    use haedal_pmm::oracle_driven_pool::{Self,Pool};

    const ESellBaseReceiveNotEnough: u64 = 1;
    const EBuyBaseCostTooMuch: u64 = 2;

    public struct ChargeMaintainerFeeEvent has copy, drop {
        pool_id: ID,
        maintainer:address, 
        is_base_coin:bool,
        amount:u64,
        base_quote_price:u64,
        quote_usd_price:u64,
        trade_num:u64
    }

    public struct SellBaseTokenEvent has copy, drop {
        pool_id: ID,
        seller: address, 
        pay_base: u64,
        receive_quote: u64,
        base_quote_price:u64,
        quote_usd_price:u64,
        trade_num:u64
    }

    public struct BuyBaseTokenEvent has copy, drop {
        pool_id: ID,
        buyer: address, 
        receive_base: u64,
        pay_quote: u64,
        base_quote_price:u64,
        quote_usd_price:u64,
        trade_num:u64
    }

    public fun sell_base_coin<CoinTypeBase, CoinTypeQuote>(
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>, 
        clock: &Clock, 
        base_price_pair_obj: &PriceInfoObject, 
        quote_price_pair_obj: &PriceInfoObject, 
        base_coin: Coin<CoinTypeBase>, 
        amount:u64, 
        min_receive_quote: u64, 
        ctx: &mut TxContext)
    {
        pool.assert_version();

        let (base_price_id, quote_price_id) = pool.get_price_id();

        let (primitive_price, _, quote_usd_price ) = oracle::calculate_pyth_primitive_prices(
            base_price_id,
            quote_price_id,
            clock,
            base_price_pair_obj,
            quote_price_pair_obj,
            pool.get_quote_coin_decimals(),
            pool.get_base_usd_price_age(),
            pool.get_quote_usd_price_age(),
        );
        pool.set_prices(quote_usd_price);

        sell_base_coin_internal(pool, primitive_price, base_coin, amount, min_receive_quote, ctx)
    }

    #[test_only]
    public fun t_sell_base_coin_internal<CoinTypeBase, CoinTypeQuote>(pool: &mut Pool<CoinTypeBase, CoinTypeQuote>, primitive_price: u64, base_coin: Coin<CoinTypeBase>, amount:u64, min_receive_quote: u64, ctx: &mut TxContext) {
        sell_base_coin_internal(pool, primitive_price, base_coin, amount, min_receive_quote, ctx)
    }
    
    fun sell_base_coin_internal<CoinTypeBase, CoinTypeQuote>(pool: &mut Pool<CoinTypeBase, CoinTypeQuote>, primitive_price: u64, base_coin: Coin<CoinTypeBase>, amount:u64, min_receive_quote: u64, ctx: &mut TxContext) {
        pool.assert_trade_allowed();
        pool.assert_selling_allowed();
        pool.increase_trade_num();

        let mut base_coin_balance = coin::into_balance(base_coin);
        let sell_base_balance = balance::split(&mut base_coin_balance, amount);

        let (receive_quote, lp_fee_quote, protocol_fee_quote, new_r_status, new_quote_target, new_base_target) = pool.query_sell_base_coin(primitive_price, amount);

        assert!(receive_quote >= min_receive_quote, ESellBaseReceiveNotEnough);

        // settle assets
        pool.quote_coin_pay_out(receive_quote, ctx.sender(), ctx);
        // TODO Not Arbitrageur
        // if (data.length > 0) {
        //     IDODOCallee(msg.sender).dodoCall(false, amount, receiveQuote, data);
        // }
        pool.base_coin_pay_in(sell_base_balance);
        oracle_driven_pool::return_back_or_delete(base_coin_balance,ctx);

        let trade_num = pool.get_trade_num();
        // charge fee
        if (protocol_fee_quote != 0) {
            let maintainer = pool.get_maintainer();
            pool.quote_coin_pay_out(protocol_fee_quote, maintainer, ctx);
            event::emit(ChargeMaintainerFeeEvent{
                pool_id: object::id(pool),
                maintainer: maintainer,
                is_base_coin: false,
                amount: protocol_fee_quote,
                base_quote_price: primitive_price,
                quote_usd_price: pool.get_quote_usd_price(),
                trade_num: trade_num,
            })
        };

        // update TARGET
        pool.set_target_base_coin_amount(new_base_target);
        pool.set_target_quote_coin_amount(new_quote_target);
        pool.set_r_status(new_r_status);

        pool.donate_quote_coin(lp_fee_quote, true, trade_num);
        event::emit(SellBaseTokenEvent{
            pool_id: object::id(pool),
            seller: ctx.sender(),
            pay_base: amount,
            receive_quote: receive_quote,
            base_quote_price: primitive_price,
            quote_usd_price: pool.get_quote_usd_price(),
            trade_num: trade_num,
        });
    }

    public fun buy_base_coin<CoinTypeBase, CoinTypeQuote>(
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>, 
        clock: &Clock, 
        base_price_pair_obj: &PriceInfoObject, 
        quote_price_pair_obj: &PriceInfoObject,
        quote_coin: Coin<CoinTypeQuote>, 
        amount:u64,
        max_pay_quote: u64, 
        ctx: &mut TxContext) {

        pool.assert_version();
        let (base_price_id, quote_price_id) = pool.get_price_id();

        let (primitive_price, _, quote_usd_price ) = oracle::calculate_pyth_primitive_prices(
            base_price_id,
            quote_price_id,
            clock,
            base_price_pair_obj,
            quote_price_pair_obj,
            pool.get_quote_coin_decimals(),
            pool.get_base_usd_price_age(),
            pool.get_quote_usd_price_age(),
        );
        pool.set_prices(quote_usd_price);

        
        buy_base_coin_internal(pool, primitive_price, quote_coin, amount, max_pay_quote, ctx)
    }

    #[test_only]
    public fun t_buy_base_coin_internal<CoinTypeBase, CoinTypeQuote>(pool: &mut Pool<CoinTypeBase, CoinTypeQuote>, primitive_price: u64, quote_coin: Coin<CoinTypeQuote>, amount:u64, max_pay_quote: u64, ctx: &mut TxContext) {
        buy_base_coin_internal(pool, primitive_price, quote_coin, amount, max_pay_quote, ctx)
    }

    fun buy_base_coin_internal<CoinTypeBase, CoinTypeQuote>(pool: &mut Pool<CoinTypeBase, CoinTypeQuote>, primitive_price: u64, quote_coin: Coin<CoinTypeQuote>, amount:u64, max_pay_quote: u64, ctx: &mut TxContext) {
        pool.assert_trade_allowed();
        pool.assert_buying_allowed();
        pool.increase_trade_num();

        let mut quote_coin_balance = coin::into_balance(quote_coin);
        let (pay_quote, lp_fee_base, protocol_fee_base, new_r_status, new_quote_target, new_base_target) = pool.query_buy_base_coin(primitive_price, amount);
        assert!(pay_quote <= max_pay_quote, EBuyBaseCostTooMuch);

        // settle assets
        let pay_quote_balance = balance::split(&mut quote_coin_balance, pay_quote);
        pool.base_coin_pay_out(amount, ctx.sender(), ctx);
        // TODO Not Arbitrageur
        // if (data.length > 0) {
        //     IDODOCallee(msg.sender).dodoCall(true, amount, payQuote, data);
        // }
        pool.quote_coin_pay_in(pay_quote_balance);
        oracle_driven_pool::return_back_or_delete(quote_coin_balance,ctx);

        let trade_num = pool.get_trade_num();
        // charge fee
        if (protocol_fee_base != 0) {
            let maintainer = pool.get_maintainer();
            pool.base_coin_pay_out(protocol_fee_base, maintainer, ctx);
            event::emit(ChargeMaintainerFeeEvent{
                pool_id: object::id(pool),
                maintainer: maintainer,
                is_base_coin: true,
                amount: protocol_fee_base,
                base_quote_price: primitive_price,
                quote_usd_price: pool.get_quote_usd_price(),
                trade_num: trade_num,
            })
        };
        // update TARGET
        pool.set_target_base_coin_amount(new_base_target);
        pool.set_target_quote_coin_amount(new_quote_target);
        pool.set_r_status(new_r_status);

        pool.donate_base_coin(lp_fee_base, true, trade_num);
        event::emit(BuyBaseTokenEvent{
            pool_id: object::id(pool),
            buyer: ctx.sender(),
            receive_base: amount,
            pay_quote: pay_quote,
            base_quote_price: primitive_price,
            quote_usd_price: pool.get_quote_usd_price(),
            trade_num: trade_num,
        });
    }

    // ============ Query Functions ============
    public fun query_sell_base_coin<CoinTypeBase, CoinTypeQuote>(
        pool: &Pool<CoinTypeBase, CoinTypeQuote>, 
        clock: &Clock, 
        base_price_pair_obj: &PriceInfoObject, 
        quote_price_pair_obj: &PriceInfoObject,
        amount: u64):u64 {
        let (base_price_id, quote_price_id) = pool.get_price_id();

        let (primitive_price, _, _ ) = oracle::calculate_pyth_primitive_prices(
            base_price_id,
            quote_price_id,
            clock,
            base_price_pair_obj,
            quote_price_pair_obj,
            pool.get_quote_coin_decimals(),
            pool.get_base_usd_price_age(),
            pool.get_quote_usd_price_age(),
        );
        query_sell_base_coin_internal(pool, primitive_price, amount)
    }

    #[test_only]
    public fun t_query_sell_base_coin_internal<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>, primitive_price: u64, amount: u64):u64 {
        query_sell_base_coin_internal(pool, primitive_price, amount)
    }

    fun query_sell_base_coin_internal<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>, primitive_price: u64, amount: u64):u64 {
        let (receive_quote, _, _, _, _, _) = pool.query_sell_base_coin(primitive_price, amount);
        receive_quote
    }
    
    public fun query_buy_base_coin<CoinTypeBase, CoinTypeQuote>(
        pool: &Pool<CoinTypeBase, CoinTypeQuote>, 
        clock: &Clock, 
        base_price_pair_obj: &PriceInfoObject, 
        quote_price_pair_obj: &PriceInfoObject, 
        amount: u64
    ):u64 
    {
        let (base_price_id, quote_price_id) = pool.get_price_id();

        let (primitive_price, _, _ ) = oracle::calculate_pyth_primitive_prices(
            base_price_id,
            quote_price_id,
            clock,
            base_price_pair_obj,
            quote_price_pair_obj,
            pool.get_quote_coin_decimals(),
            pool.get_base_usd_price_age(),
            pool.get_quote_usd_price_age(),
        );
        query_buy_base_coin_internal(pool, primitive_price, amount)
    }

    #[test_only]
    public fun t_query_buy_base_coin_internal<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>, primitive_price: u64, amount: u64):u64 {
        query_buy_base_coin_internal(pool, primitive_price, amount)
    }

    public fun query_buy_base_coin_internal<CoinTypeBase, CoinTypeQuote>(pool: &Pool<CoinTypeBase, CoinTypeQuote>, primitive_price: u64, amount: u64):u64 {
        let (pay_quote, _, _, _, _, _) = pool.query_buy_base_coin(primitive_price, amount);
        pay_quote
    }
}
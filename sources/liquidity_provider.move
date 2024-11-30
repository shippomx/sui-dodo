
module haedal_pmm::liquidity_provider {

    use sui::pay;
    use sui::event;
    use sui::coin::{Self,Coin};
    use sui::balance::{Self, Balance};
    use sui::clock::Clock;
    
    use pyth::price_info::PriceInfoObject;

    use haedal_pmm::oracle;
    use haedal_pmm::safe_math;
    use haedal_pmm::ownable::{ LiquidityOperatorCap };
    use haedal_pmm::oracle_driven_pool::{Self, Pool, BasePoolLiquidityCoin,QuotePoolLiquidityCoin};

    const ENotEnough: u64 = 1;
    const ELiquidityAddLiquidityFailed: u64 = 2;
    const ENoBaseLP: u64 = 3;
    const ENoQuoteLP: u64 = 4;
    const ELPBaseCapitalBalanceNotEnough: u64 = 5;
    const ELPQuoteCapitalBalanceNotEnough: u64 = 6;
    const EPenaltyExceed: u64 = 7;

    public struct DepositEvent has copy, drop {
        sender: address,
        pool_id: ID,
        is_base_coin: bool,
        amount: u64,
        capital: u64,
        base_quote_price: u64,
        quote_usd_price: u64,
        liquidity_change_num: u64,
    }

    public struct WithdrawEvent has copy, drop {
        sender: address,
        pool_id: ID,
        is_base_coin: bool,
        amount: u64,
        capital: u64,
        base_quote_price: u64,
        quote_usd_price: u64,
        liquidity_change_num: u64,
    }

    public struct ChargePenaltyEvent has copy, drop {
        sender: address,
        pool_id: ID,
        is_base_coin: bool,
        amount: u64,
        base_quote_price: u64,
        quote_usd_price: u64,
        liquidity_change_num: u64,
    }

    // ============ Deposit Base ============

    public fun deposit_base<CoinTypeBase, CoinTypeQuote>(
        _: &LiquidityOperatorCap<CoinTypeBase, CoinTypeQuote>,
        pool: &mut Pool<CoinTypeBase,CoinTypeQuote>,
        coin_base: Coin<CoinTypeBase>, 
        clock: &Clock, 
        base_price_pair_obj: &PriceInfoObject, 
        quote_price_pair_obj: &PriceInfoObject,         
        amount: u64,
        ctx: &mut TxContext) {
        
        pool.assert_version();
        pool.assert_deposit_base_allowed();

        assert!(coin::value(&coin_base) >= amount, ENotEnough);
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

        deposit_base_internal(
            pool,
            coin_base,
            primitive_price,
            amount,
            ctx,
        )
    }

    #[test_only]
    public fun t_deposit_base_internal<CoinTypeBase, CoinTypeQuote>(
        pool: &mut Pool<CoinTypeBase,CoinTypeQuote>,
        coin_base: Coin<CoinTypeBase>,
        primitive_price: u64,
        amount: u64,
        ctx: &mut TxContext) {
        deposit_base_internal(  
            pool,
            coin_base,
            primitive_price,
            amount,
            ctx,
        )
    }

    fun deposit_base_internal<CoinTypeBase, CoinTypeQuote>(
        pool: &mut Pool<CoinTypeBase,CoinTypeQuote>,
        coin_base: Coin<CoinTypeBase>,
        primitive_price: u64,
        amount: u64,
        ctx: &mut TxContext) {
        pool.increase_liquidity_change_num(); // increase liquidity change num
        let (base_target,_) = pool.get_expected_target(primitive_price);
        let total_base_capital = pool.get_base_capital_coin_supply();
        let mut capital =  amount;

        if (total_base_capital == 0) {
            // give remaining base token to lp as a gift
            capital = amount+base_target;
        } else if (base_target > 0) {
            capital = safe_math::safe_mul_div_u64(amount,total_base_capital,base_target);
        };

        let mut balance_base = coin::into_balance(coin_base);
        let deposit_base = balance::split(&mut balance_base, amount);
        let coin_liquidity = mint_base(
            pool,
            deposit_base,
            capital,
            ctx
        );

        assert!(coin::value(&coin_liquidity) > 0, ELiquidityAddLiquidityFailed);
        pay::keep(coin_liquidity, ctx);

        oracle_driven_pool::return_back_or_delete(balance_base, ctx);
        
        event::emit(DepositEvent{
            sender: ctx.sender(),
            pool_id: object::id(pool),
            is_base_coin: true,
            amount,
            capital,
            base_quote_price: primitive_price,
            quote_usd_price: pool.get_quote_usd_price(),
            liquidity_change_num: pool.get_liquidity_change_num(),
        });
    }

    fun mint_base<CoinTypeBase, CoinTypeQuote>(
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
        balance_base: Balance<CoinTypeBase>,
        capital: u64,
        ctx: &mut TxContext
    ): Coin<BasePoolLiquidityCoin<CoinTypeBase, CoinTypeQuote>> {
        let coin_liquidity = oracle_driven_pool::mint_base_capital(pool, balance_base, capital,ctx);
        coin_liquidity
    }


    // ============ Deposit Quote ============

    public fun deposit_quote<CoinTypeBase, CoinTypeQuote>(
        _: &LiquidityOperatorCap<CoinTypeBase, CoinTypeQuote>,
        pool: &mut Pool<CoinTypeBase,CoinTypeQuote>,
        coin_quote: Coin<CoinTypeQuote>,
        clock: &Clock, 
        base_price_pair_obj: &PriceInfoObject, 
        quote_price_pair_obj: &PriceInfoObject,
        amount: u64,
        ctx: &mut TxContext) {
        
        pool.assert_version();
        pool.assert_deposit_quote_allowed();
        assert!(coin::value(&coin_quote) >= amount, ENotEnough);
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

        deposit_quote_internal(
            pool,
            coin_quote,
            primitive_price,
            amount,
            ctx,
        )
    }

    #[test_only]
    public fun t_deposit_quote_internal<CoinTypeBase, CoinTypeQuote>(
        pool: &mut Pool<CoinTypeBase,CoinTypeQuote>,
        coin_quote: Coin<CoinTypeQuote>,
        primitive_price: u64,
        amount: u64,
        ctx: &mut TxContext) {
        deposit_quote_internal(  
            pool,
            coin_quote,
            primitive_price,
            amount,
            ctx,
        )
    }

    fun deposit_quote_internal<CoinTypeBase, CoinTypeQuote>(
        pool: &mut Pool<CoinTypeBase,CoinTypeQuote>,
        coin_quote: Coin<CoinTypeQuote>,
        primitive_price: u64,
        amount: u64,
        ctx: &mut TxContext) {
        pool.increase_liquidity_change_num(); // increase liquidity change num

        let (_,quote_target) = pool.get_expected_target(primitive_price);
        let total_quote_capital = pool.get_quote_capital_coin_supply();
        let mut capital =  amount;

        if (total_quote_capital == 0) {
            // give remaining base token to lp as a gift
            capital = amount+quote_target;
        } else if (quote_target > 0) {
            capital = safe_math::safe_mul_div_u64(amount,total_quote_capital,quote_target);
        };

        let mut balance_quote = coin::into_balance(coin_quote);
        let deposit_quote = balance::split(&mut balance_quote, amount);
        let coin_liquidity = mint_quote(
            pool,
            deposit_quote,
            capital,
            ctx
        );
        assert!(coin::value(&coin_liquidity) > 0, ELiquidityAddLiquidityFailed);
        pay::keep(coin_liquidity, ctx);

        oracle_driven_pool::return_back_or_delete(balance_quote, ctx);

        event::emit(DepositEvent{
            sender: ctx.sender(),
            pool_id: object::id(pool),
            is_base_coin: false,
            amount: amount,
            capital: capital,
            base_quote_price: primitive_price,
            quote_usd_price: pool.get_quote_usd_price(),
            liquidity_change_num: pool.get_liquidity_change_num(),
        });
    }

     fun mint_quote<CoinTypeBase, CoinTypeQuote>(
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
        balance_quote: Balance<CoinTypeQuote>,
        capital: u64,
        ctx: &mut TxContext
    ): Coin<QuotePoolLiquidityCoin<CoinTypeBase, CoinTypeQuote>> {
        let coin_liquidity = oracle_driven_pool::mint_quote_capital(pool, balance_quote,capital, ctx);
        coin_liquidity
    }

    // ============ Withdraw Base ============

    public fun withdraw_base<CoinTypeBase, CoinTypeQuote>(
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
        base_capital_coin: Coin<BasePoolLiquidityCoin<CoinTypeBase, CoinTypeQuote>>,
        clock: &Clock, 
        base_price_pair_obj: &PriceInfoObject, 
        quote_price_pair_obj: &PriceInfoObject,
        amount: u64,
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

        withdraw_base_internal(pool, base_capital_coin, primitive_price, amount, ctx)
    }

    #[test_only]
    public fun t_withdraw_base_internal<CoinTypeBase, CoinTypeQuote>(
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
        base_capital_coin: Coin<BasePoolLiquidityCoin<CoinTypeBase, CoinTypeQuote>>,
        primitive_price: u64, 
        amount: u64,
        ctx: &mut TxContext) {
        withdraw_base_internal(pool, base_capital_coin, primitive_price, amount, ctx)
    }

    fun withdraw_base_internal<CoinTypeBase, CoinTypeQuote>(
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
        base_capital_coin: Coin<BasePoolLiquidityCoin<CoinTypeBase, CoinTypeQuote>>,
        primitive_price: u64, 
        amount: u64,
        ctx: &mut TxContext) {

        pool.increase_liquidity_change_num(); // increase liquidity change num

        let (base_target,  _) = pool.get_expected_target(primitive_price);
        let total_base_capital = pool.get_base_capital_coin_supply();
        assert!(total_base_capital > 0, ENoBaseLP);

        let require_base_capital = safe_math::safe_div_ceil_u64(safe_math::safe_mul_u64(amount, total_base_capital), base_target);
        assert!(require_base_capital <= base_capital_coin.value(), ELPBaseCapitalBalanceNotEnough);

        // handle penalty, penalty may exceed amount
        let penalty = pool.get_withdraw_base_penalty(primitive_price, amount);
        assert!(penalty <= amount, EPenaltyExceed);
        
        // settlement
        let mut base_capital_balance = coin::into_balance(base_capital_coin);
        let base_capital_burn = balance::split(&mut base_capital_balance, require_base_capital);

        let (target_base_coin_amount, _) = pool.get_target_amount();
        // update target
        pool.set_target_base_coin_amount(target_base_coin_amount - amount);

        let withdraw_amount = amount - penalty;
        base_capital_burn(pool, base_capital_burn, penalty);

        pool.base_coin_pay_out(amount, ctx.sender(), ctx);

        oracle_driven_pool::return_back_or_delete(base_capital_balance, ctx);

        event::emit(WithdrawEvent{
            sender: ctx.sender(),
            pool_id: object::id(pool),
            is_base_coin: true,
            amount: withdraw_amount,
            capital: require_base_capital,
            base_quote_price: primitive_price,
            quote_usd_price: pool.get_quote_usd_price(),
            liquidity_change_num: pool.get_liquidity_change_num(),
        });

        event::emit(ChargePenaltyEvent{
            sender: ctx.sender(),
            pool_id: object::id(pool),
            is_base_coin: true,
            amount: penalty,
            base_quote_price: primitive_price,
            quote_usd_price: pool.get_quote_usd_price(),
            liquidity_change_num: pool.get_liquidity_change_num(),
        });
        
    }

    fun base_capital_burn<CoinTypeBase, CoinTypeQuote>(
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
        to_burn: Balance<BasePoolLiquidityCoin<CoinTypeBase, CoinTypeQuote>>,
        penalty:u64,
    ) {
        pool.burn_base_capital_coin(to_burn, penalty);
    }

    // ============ Withdraw Quote ============

    public fun withdraw_quote<CoinTypeBase, CoinTypeQuote>(
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
        quote_capital_coin: Coin<QuotePoolLiquidityCoin<CoinTypeBase, CoinTypeQuote>>,
        clock: &Clock, 
        base_price_pair_obj: &PriceInfoObject, 
        quote_price_pair_obj: &PriceInfoObject,
        amount: u64,
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

        withdraw_quote_internal(pool, quote_capital_coin, primitive_price, amount, ctx)
    }

    #[test_only]
    public fun t_withdraw_quote_internal<CoinTypeBase, CoinTypeQuote>(
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
        base_capital_coin: Coin<QuotePoolLiquidityCoin<CoinTypeBase, CoinTypeQuote>>,
        primitive_price: u64, 
        amount: u64,
        ctx: &mut TxContext) {
        withdraw_quote_internal(pool, base_capital_coin, primitive_price, amount, ctx)
    }

    fun withdraw_quote_internal<CoinTypeBase, CoinTypeQuote>(
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
        quote_capital_coin: Coin<QuotePoolLiquidityCoin<CoinTypeBase, CoinTypeQuote>>,
        primitive_price: u64, 
        amount: u64,
        ctx: &mut TxContext) {
        pool.increase_liquidity_change_num(); // increase liquidity change num

        let (_,  quote_target) = pool.get_expected_target(primitive_price);
        let total_quote_capital = pool.get_quote_capital_coin_supply();
        assert!(total_quote_capital > 0, ENoQuoteLP);

        let require_quote_capital = safe_math::safe_div_ceil_u64(safe_math::safe_mul_u64(amount, total_quote_capital), quote_target);
        assert!(require_quote_capital <= quote_capital_coin.value(), ELPQuoteCapitalBalanceNotEnough);

        // handle penalty, penalty may exceed amount
        let penalty = pool.get_withdraw_quote_penalty(primitive_price, amount);
        assert!(penalty <= amount, EPenaltyExceed);
        
        // settlement
        let mut quote_capital_balance = coin::into_balance(quote_capital_coin);
        let quote_capital_burn = balance::split(&mut quote_capital_balance, require_quote_capital);

        let (_, target_quote_coin_amount) = pool.get_target_amount();
        // update target
        pool.set_target_quote_coin_amount(target_quote_coin_amount - amount);
        
        let withdraw_amount = amount - penalty;
        // burn
        quote_capital_burn(pool, quote_capital_burn, penalty);
        // pay quote coin
        pool.quote_coin_pay_out(withdraw_amount, ctx.sender(), ctx);
        // return back or delete
        oracle_driven_pool::return_back_or_delete(quote_capital_balance, ctx);

        event::emit(WithdrawEvent{
            sender: ctx.sender(),
            pool_id: object::id(pool),
            is_base_coin: false,
            amount: withdraw_amount,
            capital: require_quote_capital,
            base_quote_price: primitive_price,
            quote_usd_price: pool.get_quote_usd_price(),
            liquidity_change_num: pool.get_liquidity_change_num(),
        });

        event::emit(ChargePenaltyEvent{
            sender: ctx.sender(),
            pool_id: object::id(pool),
            is_base_coin: false,
            amount: penalty,
            base_quote_price: primitive_price,
            quote_usd_price: pool.get_quote_usd_price(),
            liquidity_change_num: pool.get_liquidity_change_num(),
        });
    }

    fun quote_capital_burn<CoinTypeBase, CoinTypeQuote>(
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
        to_burn: Balance<QuotePoolLiquidityCoin<CoinTypeBase, CoinTypeQuote>>,
        penalty:u64,
    ) {
        pool.burn_quote_capital_coin(to_burn, penalty);
    }

    // ============ Withdraw all Functions ============

    public fun withdraw_all_base<CoinTypeBase, CoinTypeQuote>(
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
        base_capital_coin: Coin<BasePoolLiquidityCoin<CoinTypeBase, CoinTypeQuote>>,
        clock: &Clock, 
        base_price_pair_obj: &PriceInfoObject, 
        quote_price_pair_obj: &PriceInfoObject,
        ctx:  &mut TxContext
    ) {        
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

        withdraw_all_base_internal(pool, base_capital_coin, primitive_price, ctx)
    }

    #[test_only]
    public fun t_withdraw_all_base_internal<CoinTypeBase, CoinTypeQuote>(
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
        base_capital_coin: Coin<BasePoolLiquidityCoin<CoinTypeBase, CoinTypeQuote>>,
        primitive_price: u64, 
        ctx:  &mut TxContext
    ) {
        withdraw_all_base_internal(pool, base_capital_coin, primitive_price, ctx)
    }
    
    fun withdraw_all_base_internal<CoinTypeBase, CoinTypeQuote>(
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
        base_capital_coin: Coin<BasePoolLiquidityCoin<CoinTypeBase, CoinTypeQuote>>,
        primitive_price: u64, 
        ctx:  &mut TxContext
    ) {
        pool.increase_liquidity_change_num(); // increase liquidity change num

        let withdraw_amount = pool.get_lp_base_balance(primitive_price, base_capital_coin.value());
        let capital = base_capital_coin.value();

        // handle penalty, penalty may exceed amount
        let penalty = pool.get_withdraw_base_penalty(primitive_price, withdraw_amount);
        assert!(penalty <= withdraw_amount, EPenaltyExceed);

        // settlement
        let mut base_capital_balance = coin::into_balance(base_capital_coin);
        let base_capital_burn = balance::split(&mut base_capital_balance, capital);

        let (target_base_coin_amount, _) = pool.get_target_amount();
        // update target
        pool.set_target_base_coin_amount(target_base_coin_amount - withdraw_amount);

        let withdraw_amount = withdraw_amount - penalty;

        base_capital_burn(pool, base_capital_burn, penalty);

        pool.base_coin_pay_out(withdraw_amount, ctx.sender(), ctx);
        oracle_driven_pool::return_back_or_delete(base_capital_balance, ctx);

        event::emit(WithdrawEvent{
            sender: ctx.sender(),
            pool_id: object::id(pool),
            is_base_coin: true,
            amount: withdraw_amount,
            capital: capital,
            base_quote_price: primitive_price,
            quote_usd_price: pool.get_quote_usd_price(),
            liquidity_change_num: pool.get_liquidity_change_num(),
        });

        event::emit(ChargePenaltyEvent{
            sender: ctx.sender(),
            pool_id: object::id(pool),
            is_base_coin: true,
            amount: penalty,
            base_quote_price: primitive_price,
            quote_usd_price: pool.get_quote_usd_price(),
            liquidity_change_num: pool.get_liquidity_change_num(),
        });
    }

    public entry fun withdraw_all_quote<CoinTypeBase, CoinTypeQuote>(
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
        quote_capital_coin: Coin<QuotePoolLiquidityCoin<CoinTypeBase, CoinTypeQuote>>,
        clock: &Clock, 
        base_price_pair_obj: &PriceInfoObject, 
        quote_price_pair_obj: &PriceInfoObject,
        ctx:  &mut TxContext
    ) {
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

        withdraw_all_quote_internal(pool, quote_capital_coin, primitive_price, ctx)
    }

    #[test_only]
    public fun t_withdraw_all_quote_internal<CoinTypeBase, CoinTypeQuote>(
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
        quote_capital_coin: Coin<QuotePoolLiquidityCoin<CoinTypeBase, CoinTypeQuote>>,
        primitive_price: u64, 
        ctx:  &mut TxContext
    ) { 
        withdraw_all_quote_internal(pool, quote_capital_coin, primitive_price, ctx)
    } 

    fun withdraw_all_quote_internal<CoinTypeBase, CoinTypeQuote>(
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
        quote_capital_coin: Coin<QuotePoolLiquidityCoin<CoinTypeBase, CoinTypeQuote>>,
        primitive_price: u64, 
        ctx:  &mut TxContext
    ) {        
        pool.increase_liquidity_change_num(); // increase liquidity change num
        
        let withdraw_amount = pool.get_lp_quote_balance(primitive_price, quote_capital_coin.value());
        let capital = quote_capital_coin.value();

        // handle penalty, penalty may exceed amount
        let penalty = pool.get_withdraw_quote_penalty(primitive_price, withdraw_amount);
        assert!(penalty <= withdraw_amount, EPenaltyExceed);

        // settlement
        let mut quote_capital_balance = coin::into_balance(quote_capital_coin);
        let quote_capital_burn = balance::split(&mut quote_capital_balance, capital);

        let (_, target_quote_coin_amount) = pool.get_target_amount();
        // update target
        pool.set_target_quote_coin_amount(target_quote_coin_amount - withdraw_amount);

        let withdraw_amount = withdraw_amount - penalty;

        quote_capital_burn(pool, quote_capital_burn, penalty);

        pool.quote_coin_pay_out(withdraw_amount, ctx.sender(),ctx);
        oracle_driven_pool::return_back_or_delete(quote_capital_balance, ctx);

        event::emit(WithdrawEvent{
            sender: ctx.sender(),
            pool_id: object::id(pool),
            is_base_coin: false,
            amount: withdraw_amount,
            capital: capital,
            base_quote_price: primitive_price,
            quote_usd_price: pool.get_quote_usd_price(),
            liquidity_change_num: pool.get_liquidity_change_num(),
        });

        event::emit(ChargePenaltyEvent{
            sender: ctx.sender(),
            pool_id: object::id(pool),
            is_base_coin: false,
            amount: penalty,
            base_quote_price: primitive_price,
            quote_usd_price: pool.get_quote_usd_price(),
            liquidity_change_num: pool.get_liquidity_change_num(),
        });
    }

     // ============ Query Functions ============
    public fun query_withdraw_base_coin<CoinTypeBase, CoinTypeQuote>(
        pool: &Pool<CoinTypeBase, CoinTypeQuote>, 
        clock: &Clock, 
        base_price_pair_obj: &PriceInfoObject, 
        quote_price_pair_obj: &PriceInfoObject,
        lp_base_amount: u64):(u64,u64) {
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
        query_withdraw_base_coin_internal(pool, primitive_price, lp_base_amount)
    }

    public(package) fun query_withdraw_base_coin_internal<CoinTypeBase, CoinTypeQuote>(
        pool: &Pool<CoinTypeBase, CoinTypeQuote>, 
        primitive_price: u64,
        lp_base_amount: u64):(u64, u64) {
        let withdraw_amount = pool.get_lp_base_balance(primitive_price, lp_base_amount);

        // handle penalty, penalty may exceed amount
        let penalty = pool.get_withdraw_base_penalty(primitive_price, withdraw_amount);
        (withdraw_amount, penalty)
    }

    public fun query_withdraw_quote_coin<CoinTypeBase, CoinTypeQuote>(
        pool: &Pool<CoinTypeBase, CoinTypeQuote>, 
        clock: &Clock, 
        base_price_pair_obj: &PriceInfoObject, 
        quote_price_pair_obj: &PriceInfoObject,
        lp_quote_amount: u64):(u64,u64) {
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
        query_withdraw_quote_coin_internal(pool, primitive_price, lp_quote_amount)
    }

    public(package) fun query_withdraw_quote_coin_internal<CoinTypeBase, CoinTypeQuote>(
        pool: &Pool<CoinTypeBase, CoinTypeQuote>, 
        primitive_price: u64,
        lp_quote_amount: u64):(u64, u64) {
        let withdraw_amount = pool.get_lp_base_balance(primitive_price, lp_quote_amount);

        // handle penalty, penalty may exceed amount
        let penalty = pool.get_withdraw_quote_penalty(primitive_price, withdraw_amount);
        (withdraw_amount, penalty)
    }
}
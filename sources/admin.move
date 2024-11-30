module haedal_pmm::admin {

    use haedal_pmm::oracle_driven_pool::{Pool};
    use haedal_pmm::ownable::{Self, AdminCap, PoolAdminCap};

    // ============ Params Setting Functions ============

    public entry fun grant_pool_admin_cap<CoinTypeBase, CoinTypeQuote>(admin_cap: &AdminCap, user:address, ctx: &mut TxContext) {
        admin_cap.assert_version();
        ownable::grant_pool_admin_cap<CoinTypeBase, CoinTypeQuote>(user, ctx);
    }
    
    public entry fun grant_liquidity_operator_cap<CoinTypeBase, CoinTypeQuote>(
        _: &PoolAdminCap<CoinTypeBase, CoinTypeQuote>, 
        user:address, 
        ctx: &mut TxContext,
    ) {
        ownable::grant_liquidity_operator_cap<CoinTypeBase, CoinTypeQuote>(user, ctx);
    }

    // ============ Params Setting Functions ============

    public entry fun set_liquidity_provider_fee_rate<CoinTypeBase, CoinTypeQuote>(
        _: &PoolAdminCap<CoinTypeBase, CoinTypeQuote>,
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
        new_liquidity_provider_fee_rate: u64,
        ctx: &TxContext,
    ) {
        pool.assert_version();
        pool.set_liquidity_provider_fee_rate(
            new_liquidity_provider_fee_rate, 
            ctx,
        );
    }

    public entry fun set_k<CoinTypeBase, CoinTypeQuote>(
        _: &PoolAdminCap<CoinTypeBase, CoinTypeQuote>,
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
        new_k: u64,
        ctx: &TxContext,
    ) {
        pool.assert_version();
        pool.set_k(
            new_k, 
            ctx,
        );
    }
    
    public entry fun set_protocol_fee_rate<CoinTypeBase, CoinTypeQuote>(
        _: &PoolAdminCap<CoinTypeBase, CoinTypeQuote>,
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
        new_protocol_fee_rate: u64,
        ctx: &TxContext,
    ) {
        pool.assert_version();
        pool.set_protocol_fee_rate(
            new_protocol_fee_rate, 
            ctx,
        );
    }
    
    public entry fun set_quote_usd_price_age<CoinTypeBase, CoinTypeQuote>(
        _: &PoolAdminCap<CoinTypeBase, CoinTypeQuote>,
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
        new_quote_usd_price_age: u64,
    ) {
        pool.assert_version();
        pool.set_quote_usd_price_age(
            new_quote_usd_price_age, 
        );
    }
    
    public entry fun set_base_usd_price_age<CoinTypeBase, CoinTypeQuote>(
        _: &PoolAdminCap<CoinTypeBase, CoinTypeQuote>,
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
        new_base_usd_price_age: u64,
    ) {
        pool.assert_version();
        pool.set_base_usd_price_age(
            new_base_usd_price_age, 
        );
    }

    // ============ System Control Functions ============

    public entry fun disable_trading<CoinTypeBase, CoinTypeQuote>(
        _: &PoolAdminCap<CoinTypeBase, CoinTypeQuote>,
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
    ) {
        pool.assert_version();
        pool.set_trade_allowed(false)
    }
    
    public entry fun enable_trading<CoinTypeBase, CoinTypeQuote>(
        _: &PoolAdminCap<CoinTypeBase, CoinTypeQuote>,
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
    ) {
        pool.assert_version();
        pool.set_trade_allowed(true)
    }

    public entry fun disable_deposit_quote<CoinTypeBase, CoinTypeQuote>(
        _: &PoolAdminCap<CoinTypeBase, CoinTypeQuote>,
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
    ) {
        pool.assert_version();
        pool.set_deposit_quote_allowed(false)
    }

    public entry fun enable_deposit_quote<CoinTypeBase, CoinTypeQuote>(
        _: &PoolAdminCap<CoinTypeBase, CoinTypeQuote>,
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
    ) {
        pool.assert_version();
        pool.set_deposit_quote_allowed(true)
    }

    public entry fun disable_deposit_base<CoinTypeBase, CoinTypeQuote>(
        _: &PoolAdminCap<CoinTypeBase, CoinTypeQuote>,
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
    ) {
        pool.assert_version();
        pool.set_deposit_base_allowed(false)
    }

    public entry fun enable_deposit_base<CoinTypeBase, CoinTypeQuote>(
        _: &PoolAdminCap<CoinTypeBase, CoinTypeQuote>,
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
    ) {
        pool.assert_version();
        pool.set_deposit_base_allowed(true)
    }

    // ============ Advanced Control Functions ============

    public entry fun disable_buying<CoinTypeBase, CoinTypeQuote>(
        _: &PoolAdminCap<CoinTypeBase, CoinTypeQuote>,
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
    ) {
        pool.assert_version();
        pool.set_buying_allowed(false)
    }

    public entry fun enable_buying<CoinTypeBase, CoinTypeQuote>(
        _: &PoolAdminCap<CoinTypeBase, CoinTypeQuote>,
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
    ) {
        pool.assert_version();
        pool.set_buying_allowed(true)
    }

    public entry fun disable_selling<CoinTypeBase, CoinTypeQuote>(
        _: &PoolAdminCap<CoinTypeBase, CoinTypeQuote>,
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
    ) {
        pool.assert_version();
        pool.set_selling_allowed(false)
    }

    public entry fun enable_selling<CoinTypeBase, CoinTypeQuote>(
        _: &PoolAdminCap<CoinTypeBase, CoinTypeQuote>,
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
    ) {
        pool.assert_version();
        pool.set_selling_allowed(true)
    }

    public entry fun set_base_balance_limit<CoinTypeBase, CoinTypeQuote>(
        _: &PoolAdminCap<CoinTypeBase, CoinTypeQuote>,
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
        new_base_balance_limit:u64,
    ) {
        pool.assert_version();
        pool.set_base_balance_limit(new_base_balance_limit)
    }

    public entry fun set_quote_balance_limit<CoinTypeBase, CoinTypeQuote>(
        _: &PoolAdminCap<CoinTypeBase, CoinTypeQuote>,
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
        new_quote_balance_limit:u64,
    ) {
        pool.assert_version();
        pool.set_quote_balance_limit(new_quote_balance_limit)
    }
}
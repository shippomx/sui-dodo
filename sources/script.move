
module haedal_pmm::script {

    use sui::coin::{CoinMetadata};
    
    use haedal_pmm::ownable::{AdminCap};
    use haedal_pmm::oracle_driven_pool::{Self, Pool};

    // Pool
    public entry fun add_pool<CoinTypeBase, CoinTypeQuote>(
        admin_cap: &mut AdminCap,
        base_coin_metadata: &CoinMetadata<CoinTypeBase>,
        quote_coin_metadata: &CoinMetadata<CoinTypeQuote>,
        maintainer:address,
        base_price_id: vector<u8>,
        quote_price_id: vector<u8>,
        lp_fee_rate:u64,
        protocol_fee_rate:u64, 
        k:u64,
        base_usd_price_age:u64,
        quote_usd_price_age:u64,
        ctx: &mut TxContext
    ) {
        oracle_driven_pool::add_pool<CoinTypeBase, CoinTypeQuote>(
            admin_cap,
            base_coin_metadata,
            quote_coin_metadata,
            maintainer,
            base_price_id,
            quote_price_id,
            lp_fee_rate,
            protocol_fee_rate, 
            k,
            base_usd_price_age,
            quote_usd_price_age,
            ctx
        );
    }

    public entry fun destroy_pool<CoinTypeBase, CoinTypeQuote>(
        admin_cap: &mut AdminCap,
    ) {
        admin_cap.assert_version();
        oracle_driven_pool::destroy_pool<CoinTypeBase, CoinTypeQuote>(
            admin_cap,
        );
    }
 
    /// Migrate the data version, this is called by the new package after upgrade.
    public entry fun migrate<CoinTypeBase, CoinTypeQuote>(admin_cap: &mut AdminCap, pool: &mut Pool<CoinTypeBase, CoinTypeQuote>, ctx: &TxContext) {
        pool.migrate(ctx);
        admin_cap.migrate(ctx)
    }

    // // LP
    // public entry fun deposit_base<CoinTypeBase, CoinTypeQuote>(
    //     liquidity_operator_cap: &LiquidityOperatorCap<CoinTypeBase, CoinTypeQuote>,
    //     pool: &mut Pool<CoinTypeBase,CoinTypeQuote>,
    //     coin_base: Coin<CoinTypeBase>,
    //     clock: &Clock, 
    //     base_price_pair_obj: &PriceInfoObject, 
    //     quote_price_pair_obj: &PriceInfoObject,
    //     amount: u64,
    //     ctx: &mut TxContext) {
    //         liquidity_provider::deposit_base(
    //             liquidity_operator_cap,
    //             pool, 
    //             coin_base, 
    //             clock,
    //             base_price_pair_obj,
    //             quote_price_pair_obj,

    //             amount, 
    //             ctx)
    // }

    // public entry fun deposit_quote<CoinTypeBase, CoinTypeQuote>(
    //     liquidity_operator_cap: &LiquidityOperatorCap<CoinTypeBase, CoinTypeQuote>,
    //     pool: &mut Pool<CoinTypeBase,CoinTypeQuote>,
    //     coin_quote: Coin<CoinTypeQuote>,
    //     clock: &Clock, 
    //     base_price_pair_obj: &PriceInfoObject, 
    //     quote_price_pair_obj: &PriceInfoObject,
    //     amount: u64,
    //     ctx: &mut TxContext) {
    //         liquidity_provider::deposit_quote(
    //             liquidity_operator_cap,
    //             pool, 
    //             coin_quote, 
    //             clock,
    //             base_price_pair_obj,
    //             quote_price_pair_obj,
    //             amount, 
    //             ctx)
    // }
}
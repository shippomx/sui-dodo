module haedal_pmm::settlement {
    
    use sui::coin::{Self, Coin};
    use sui::balance;


    use haedal_pmm::ownable::{PoolAdminCap};
    use haedal_pmm::oracle_driven_pool::{Pool, BasePoolLiquidityCoin, QuotePoolLiquidityCoin};

    // ============ Final Settlement Functions ============

    // last step to shut down pool
    public entry fun final_settlement<CoinTypeBase, CoinTypeQuote>(
        _: &PoolAdminCap<CoinTypeBase, CoinTypeQuote>, 
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>
    ) {
        pool.assert_version();
        pool.final_settlement();
    }

    // claim remaining assets after final settlement
    public entry fun claim_assets<CoinTypeBase, CoinTypeQuote>(
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
        base_capital_coin: Coin<BasePoolLiquidityCoin<CoinTypeBase, CoinTypeQuote>>,
        quote_capital_coin: Coin<QuotePoolLiquidityCoin<CoinTypeBase, CoinTypeQuote>>,
        ctx: &mut TxContext
    ) {
        pool.assert_version();
        pool.claim_assets(base_capital_coin, quote_capital_coin, ctx);
    }

    // claim remaining base assets after final settlement
    public entry fun claim_base<CoinTypeBase, CoinTypeQuote>(
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
        base_capital_coin: Coin<BasePoolLiquidityCoin<CoinTypeBase, CoinTypeQuote>>,
        ctx: &mut TxContext
    ) {
        pool.assert_version();
        let quote_capital_coin = coin::from_balance(balance::zero<QuotePoolLiquidityCoin<CoinTypeBase, CoinTypeQuote>>(), ctx);
        pool.claim_assets(base_capital_coin, quote_capital_coin, ctx);
    }

    // claim remaining quote assets after final settlement
    public entry fun claim_quote<CoinTypeBase, CoinTypeQuote>(
        pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
        quote_capital_coin: Coin<QuotePoolLiquidityCoin<CoinTypeBase, CoinTypeQuote>>,
        ctx: &mut TxContext
    ) {
        pool.assert_version();
        let base_capital_coin = coin::from_balance<BasePoolLiquidityCoin<CoinTypeBase, CoinTypeQuote>>(balance::zero(), ctx);
        pool.claim_assets(base_capital_coin, quote_capital_coin, ctx);
    }
}
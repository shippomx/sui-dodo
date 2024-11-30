source ./scripts/config.sh

# public entry fun claim_assets<CoinTypeBase, CoinTypeQuote>(
#         pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
#         base_capital_coin: Coin<PoolLiquidityCoin<CoinTypeBase>>,
#         quote_capital_coin: Coin<PoolLiquidityCoin<CoinTypeQuote>>,
#         ctx: &mut TxContext
#     )

sui client switch --address $liquidity_provider1

base_capital_coin=0xf5d98e074627e837792807bd704d493b9adf808c96d5caceef6437c780c04db4
quote_capital_coin=0xab7f73ff417ceb9f70ecc27e7d62aa42527f98a8ec5c197a52958f6f658022ea

sui client call --package $contract --module settlement --function claim_assets \
--type-args $base_coin_type $quote_coin_type \
--args $pool_id $base_capital_coin $quote_capital_coin

sui client switch --address $admin
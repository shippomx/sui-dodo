source ./scripts/config.sh

# public entry fun withdraw_all_quote<withdraw_quote, CoinTypeQuote>(
#         pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
#         quote_capital_coin: Coin<PoolLiquidityCoin<CoinTypeQuote>>,
#         clock: &Clock, 
#         priceInfoObject: &PriceInfoObject,
#         ctx: &mut TxContext) 

sui client switch --address $liquidity_provider2

sui client call --package $contract --module liquidity_provider --function withdraw_all_quote \
--type-args $base_coin_type $quote_coin_type \
--args $pool_id 0xfcea5aef2dc185a71a7c45ea7ceb1d1cd04ab938076b60b2cd16c6870452de01 \
 $clock_id $sui_usd_price_info_obj_id

sui client switch --address $admin
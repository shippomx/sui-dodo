source ./scripts/config.sh

# public entry fun withdraw_all_base<CoinTypeBase, CoinTypeQuote>(
#         pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
#         base_capital_coin: Coin<PoolLiquidityCoin<CoinTypeBase>>,
#         clock: &Clock, 
#         priceInfoObject: &PriceInfoObject,
#         ctx: &mut TxContext) 

sui client switch --address $liquidity_provider2

sui client call --package $contract --module liquidity_provider --function withdraw_all_base \
--type-args $base_coin_type $quote_coin_type \
--args $pool_id 0xea1354fbeeadcd1fd17b7051868d7b5d455900ac596a4cbbe9b8801d32ef0ea7 \
 $clock_id $sui_usd_price_info_obj_id

sui client switch --address $admin
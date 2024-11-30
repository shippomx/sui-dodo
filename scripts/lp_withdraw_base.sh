source ./scripts/config.sh

# public entry fun withdraw_base<CoinTypeBase, CoinTypeQuote>(
#         pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
#         base_capital_coin: Coin<PoolLiquidityCoin<CoinTypeBase>>,
#         clock: &Clock, 
#         priceInfoObject: &PriceInfoObject,
#         amount: u64,
#         ctx: &mut TxContext) 

sui client switch --address $liquidity_provider1

amount=0.3
base_coin_id=0xe9fad184cddb9d38342d5ece17b822409c8a86dd2ea85b95bb221bd8d2a1fadb

sui client call --package $contract --module liquidity_provider --function withdraw_base \
--type-args $base_coin_type $quote_coin_type \
--args $pool_id $base_coin_id $clock_id \
 $sui_usd_price_info_obj_id $usdc_usd_price_info_obj_id $(format_uint_func $amount $base_coin_decimals)

sui client switch --address $admin
source ./scripts/config.sh

# public entry fun withdraw_base<withdraw_quote, CoinTypeQuote>(
#         pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
#         quote_capital_coin: Coin<PoolLiquidityCoin<CoinTypeQuote>>,
#         clock: &Clock, 
#         priceInfoObject: &PriceInfoObject,
#         amount: u64,
#         ctx: &mut TxContext) 

sui client switch --address $liquidity_provider1

amount=30
quote_coin_id=0xfb307a778c95aed9b2ab464f401c9128c5da5062b9a7f0018cc328f14b23f342

sui client call --package $contract --module liquidity_provider --function withdraw_quote \
--type-args $base_coin_type $quote_coin_type \
--args $pool_id $quote_coin_id $clock_id \
 $sui_usd_price_info_obj_id $usdc_usd_price_info_obj_id $(format_uint_func $amount $quote_coin_decimals)

sui client switch --address $admin
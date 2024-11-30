source ./scripts/config.sh

#  public fun query_sell_base_coin<CoinTypeBase, CoinTypeQuote>(
#         pool: &Pool<CoinTypeBase, CoinTypeQuote>, 
#         clock: &Clock, 
#         priceInfoObject: &PriceInfoObject, 
#         amount: u64):u64

sui client switch --address $trader1

sell_amount=0.2

sui client call --package $contract --module trader --function query_sell_base_coin \
--type-args $base_coin_type $quote_coin_type \
--args $pool_id $clock_id $sui_usd_price_info_obj_id $(format_uint_func $sell_amount $base_coin_decimals)

sui client switch --address $admin
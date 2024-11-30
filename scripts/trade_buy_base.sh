source ./scripts/config.sh

# public entry fun buy_base_coin<CoinTypeBase, CoinTypeQuote>(
#         pool: &mut Pool<CoinTypeBase, CoinTypeQuote>, 
#         clock: &Clock, 
#         priceInfoObject: &PriceInfoObject, 
#         quote_coin: Coin<CoinTypeQuote>, 
#         amount:u64,
#         max_pay_quote: u64, 
#         ctx: &mut TxContext)

sui client switch --address $trader1

buy_amount=0.5
max_pay_quote=2
quote_coin_id=0x4ad88babcf604ad54bbb5ed9bcaaf43d5492021e13c2bb87d5b026b8b6c1e84a

sui client call --package $contract --module trader --function buy_base_coin \
--type-args $base_coin_type $quote_coin_type \
--args $pool_id $clock_id $sui_usd_price_info_obj_id $usdc_usd_price_info_obj_id $quote_coin_id \
 $(format_uint_func $buy_amount $base_coin_decimals) $(format_uint_func $max_pay_quote $quote_coin_decimals)

sui client switch --address $admin
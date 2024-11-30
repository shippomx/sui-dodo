source ./scripts/config.sh

# public entry fun sell_base_coin<CoinTypeBase, CoinTypeQuote>(
#         pool: &mut Pool<CoinTypeBase, CoinTypeQuote>, 
#         clock: &Clock, 
#         priceInfoObject: &PriceInfoObject, 
#         base_coin: Coin<CoinTypeBase>, 
#         amount:u64, 
#         min_receive_quote: u64, 
#         ctx: &mut TxContext)

sui client switch --address $trader1

sell_amount=0.2
min_receive_quote=0.6
base_coin_id=0x69d0bd3b6a3e846e0e4818453bd3eb213f02cfe89afc2947e72c9da24768186a

sui client call --package $contract --module trader --function sell_base_coin \
--type-args $base_coin_type $quote_coin_type \
--args $pool_id $clock_id $sui_usd_price_info_obj_id $usdc_usd_price_info_obj_id $base_coin_id \
 $(format_uint_func $sell_amount $base_coin_decimals) $(format_uint_func $min_receive_quote $quote_coin_decimals)

sui client switch --address $admin
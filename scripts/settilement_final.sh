source ./scripts/config.sh

# public entry fun sell_base_coin<CoinTypeBase, CoinTypeQuote>(
#         pool: &mut Pool<CoinTypeBase, CoinTypeQuote>, 
#         clock: &Clock, 
#         priceInfoObject: &PriceInfoObject, 
#         base_coin: Coin<CoinTypeBase>, 
#         amount:u64, 
#         min_receive_quote: u64, 
#         ctx: &mut TxContext)

sui client switch --address $pool_admin


sui client call --package $contract --module settlement --function final_settlement \
--type-args $base_coin_type $quote_coin_type \
--args $pool_admin_cap_id $pool_id

sui client switch --address $admin
source ./scripts/config.sh
# public entry fun add_pool<CoinTypeBase, CoinTypeQuote>(
#         admin_cap: &AdminCap,
#         maintainer:address,
#         base_price_id: vector<u8>,
#         quote_price_id: vector<u8>,
#         lp_fee_rate:u64,
#         protocol_fee_rate:u64, 
#         k:u64,
#         ctx: &mut TxContext
#     )
sui client switch --address $admin

sui client call --package $contract --module script --function add_pool \
--type-args $base_coin_type $quote_coin_type \
--args $admin_cap_id $base_metadata_object_id $quote_metadata_object_id $maintainer \
 $sui_price_id $usdc_price_id $(format_uint_func $lp_fee_rate 9) $(format_uint_func $protocol_fee_rate 9) $(format_uint_func $k 9) 60 60

sui client switch --address $admin


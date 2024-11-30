source ./scripts/config.sh

# public entry fun set_protocol_fee_rate<CoinTypeBase, CoinTypeQuote>(
#         _: &PoolAdminCap<CoinTypeBase, CoinTypeQuote>,
#         pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
#         new_protocol_fee_rate: u64,
#         ctx: &TxContext,
#     )

sui client switch --address $pool_admin

new_protocol_fee_rate=0.00125

sui client call --package $contract --module admin --function set_protocol_fee_rate \
--type-args $base_coin_type $quote_coin_type \
--args $pool_admin_cap_id $pool_id $(format_uint_func $new_protocol_fee_rate 9)

sui client switch --address $admin
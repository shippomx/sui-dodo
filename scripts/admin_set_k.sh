source ./scripts/config.sh

# public entry fun set_k<CoinTypeBase, CoinTypeQuote>(
#         _: &PoolAdminCap<CoinTypeBase, CoinTypeQuote>,
#         pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
#         new_k: u64,
#         ctx: &TxContext,
#     )

sui client switch --address $pool_admin

new_k=0.1

sui client call --package $contract --module admin --function set_k \
--type-args $base_coin_type $quote_coin_type \
--args $pool_admin_cap_id $pool_id $(format_uint_func $new_k 9)

sui client switch --address $admin
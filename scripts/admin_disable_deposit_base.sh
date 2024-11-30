source ./scripts/config.sh

# public entry fun disable_deposit_base<CoinTypeBase, CoinTypeQuote>(
#         _: &PoolAdminCap<CoinTypeBase, CoinTypeQuote>,
#         pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
#     )
sui client switch --address $pool_admin

sui client call --package $contract --module admin --function disable_deposit_base \
--type-args $base_coin_type $quote_coin_type \
--args $pool_admin_cap_id $pool_id 

sui client switch --address $admin
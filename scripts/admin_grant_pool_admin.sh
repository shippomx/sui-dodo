source ./scripts/config.sh

# public entry fun grant_pool_admin_cap<CoinTypeBase, CoinTypeQuote>(_: &AdminCap, user:address, ctx: &mut TxContext)

sui client switch --address $admin

sui client call --package $contract --module admin --function grant_pool_admin_cap \
--type-args $base_coin_type $quote_coin_type \
--args $admin_cap_id $pool_admin

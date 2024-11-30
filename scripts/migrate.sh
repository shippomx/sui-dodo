source ./scripts/config.sh

sui client switch --address $admin

# public entry fun migrate<CoinTypeBase, CoinTypeQuote>(admin_cap: &mut AdminCap, pool: &mut Pool<CoinTypeBase, CoinTypeQuote>, ctx: &TxContext)

sui client call --package $contract --module script --function migrate \
--type-args $base_coin_type $quote_coin_type \
--args $admin_cap_id $pool_id

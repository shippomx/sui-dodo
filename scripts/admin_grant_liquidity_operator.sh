source ./scripts/config.sh
#     public entry fun grant_liquidity_operator_cap<CoinTypeBase, CoinTypeQuote>(
#         _: &PoolAdminCap<CoinTypeBase, CoinTypeQuote>, 
#         user:address, 
#         ctx: &mut TxContext,
#     )
sui client switch --address $pool_admin

sui client call --package $contract --module admin --function grant_liquidity_operator_cap \
--type-args $base_coin_type $quote_coin_type \
--args $pool_admin_cap_id $liquidity_provider1

sui client switch --address $admin
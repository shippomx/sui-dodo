source ./scripts/config.sh

# public entry fun deposit_base<CoinTypeBase, CoinTypeQuote>(
#         liquidity_operator_cap: &LiquidityOperatorCap<CoinTypeBase, CoinTypeQuote>,
#         pool: &mut Pool<CoinTypeBase,CoinTypeQuote>,
#         coin_base: Coin<CoinTypeBase>,
#         clock: &Clock, 
#         priceInfoObject: &PriceInfoObject,
#         amount: u64,
#         ctx: &mut TxContext)

sui client switch --address $liquidity_provider1

amount=2
base_coin_id=0x594a8a778e35be4a168c757cab5280f7c9f1c8849d1298b9389061052e578c91

# echo "sui client call --package $contract --module liquidity_provider --function deposit_base \
# --type-args $base_coin_type $quote_coin_type \
# --args $liquidity_operator1_cap_id $pool_id $base_coin_id \
#  $clock_id $sui_usd_price_info_obj_id $usdc_usd_price_info_obj_id $(format_uint_func $amount $base_coin_decimals) "
sui client call --package $contract --module liquidity_provider --function deposit_base \
--type-args $base_coin_type $quote_coin_type \
--args $liquidity_operator1_cap_id $pool_id $base_coin_id \
 $clock_id $sui_usd_price_info_obj_id $usdc_usd_price_info_obj_id $(format_uint_func $amount $base_coin_decimals)

sui client switch --address $admin
source ./scripts/config.sh

# public entry fun deposit_quote<CoinTypeBase, CoinTypeQuote>(
#         liquidity_operator_cap: &LiquidityOperatorCap<CoinTypeBase, CoinTypeQuote>,
#         pool: &mut Pool<CoinTypeBase,CoinTypeQuote>,
#         coin_quote: Coin<CoinTypeQuote>,
#         clock: &Clock, 
#         priceInfoObject: &PriceInfoObject,
#         amount: u64,
#         ctx: &mut TxContext)

sui client switch --address $liquidity_provider1

amount=20
quote_coin_id=0x628522fb3fe84d495975a15348b77b7f92ba540ef697306e128c6954ceb0446e

sui client call --package $contract --module liquidity_provider --function deposit_quote \
--type-args $base_coin_type $quote_coin_type \
--args $liquidity_operator1_cap_id $pool_id $quote_coin_id \
 $clock_id $sui_usd_price_info_obj_id $usdc_usd_price_info_obj_id $(format_uint_func $amount $quote_coin_decimals) \

sui client switch --address $admin
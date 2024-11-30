source ./scripts/config.sh

amount=1000

sui client call --package $quote_coin_id --module $quote_coin_mint_module --function $quote_coin_mint_func \
 --args $quote_coin_treasury_cap_id $(format_uint_func $amount $quote_coin_decimals) \
 0x3975b862933807b3ed73f18edf350c1f2022927c2d17bdc5b4f06d4920cd1944

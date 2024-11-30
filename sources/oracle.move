module haedal_pmm::oracle {
    use sui::clock::Clock;
    use std::u64;

    use haedal_pmm::safe_math::{Self};
    use pyth::price_info;
    use pyth::price_identifier;
    use pyth::price;
    use pyth::pyth;
    use pyth::price_info::PriceInfoObject;
 
    const EInvalidId: u64 = 1;
    const EInvalidPrice: u64 = 2;

    fun get_pyth_price(
       _price_id: vector<u8>,
        // Other arguments
        clock: &Clock,
        pyth_price_pair_obj: &PriceInfoObject, 
        quote_coin_decimals: u8,
        max_age: u64,
    ):u64 {
        // Make sure the price is not older than max_age seconds
        let pyth_price = pyth::get_price_no_older_than(pyth_price_pair_obj, clock, max_age);
 
        // Check the price feed ID
        let pyth_price_info = price_info::get_price_info_from_price_info_object(pyth_price_pair_obj);
        let price_id = price_identifier::get_bytes(&price_info::get_price_identifier(&pyth_price_info));
 
        // SUI/USD price feed ID
        // The complete list of feed IDs is available at https://pyth.network/developers/price-feed-ids
        // Note: Sui uses the Pyth price feed ID without the `0x` prefix.
        assert!(_price_id == price_id, EInvalidId);

        // Extract the price, decimal, and timestamp from the price struct and use them
        let decimal_i64 = price::get_expo(&pyth_price);
        let price_i64 = price::get_price(&pyth_price);
        let priceu64 = if (price_i64.get_is_negative()) {
            price_i64.get_magnitude_if_negative()
        } else {
            price_i64.get_magnitude_if_positive()
        };
        assert!(priceu64 != 0, EInvalidPrice);

        if (decimal_i64.get_is_negative()) {
            let price_decimals = decimal_i64.get_magnitude_if_negative() as u8;
            let price_value_with_formatted_decimals = if (price_decimals < quote_coin_decimals) {
                priceu64 * u64::pow(10, quote_coin_decimals - price_decimals)
            } else {
                // This should rarely happen, since formatted_decimals is 9 and price_decimals is usually smaller than 8
                priceu64 / u64::pow(10, price_decimals - quote_coin_decimals)
            };
            price_value_with_formatted_decimals
        } else {
            priceu64 * u64::pow(10, decimal_i64.get_magnitude_if_positive() as u8 + quote_coin_decimals)
        }
    }

    public fun calculate_pyth_primitive_prices(
        base_price_id: vector<u8>,
        quote_price_id: vector<u8>,
        clock: &Clock, 
        base_price_pair_obj: &PriceInfoObject, 
        quote_price_pair_obj: &PriceInfoObject, 
        quote_coin_decimals: u8,
        base_price_max_age: u64,
        quote_price_max_age: u64,
    ): (u64, u64, u64) {
        let base_price = get_pyth_price(
        base_price_id,
        clock,
        base_price_pair_obj,
        quote_coin_decimals,
        base_price_max_age);

        let quote_price = get_pyth_price(
        quote_price_id,
        clock,
        quote_price_pair_obj,
        quote_coin_decimals,
        quote_price_max_age);

        let primitive_price = safe_math::safe_mul_div_u64(base_price , u64::pow(10, quote_coin_decimals), quote_price);
        (primitive_price, base_price, quote_price)
    }

}
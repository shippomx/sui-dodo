
# Trader API 说明

## SellBaseCoin - 卖出基础代币

**Module:** `trader`

**Function:** `sell_base_coin`

| 参数 | 说明 | 例如 |
| :--- | :--- | :--- |
| `base_coin_type` | Base Coin Type, 基础代币的 coinType |  `0x2::sui::SUI` |
| `quote_coin_type` | Quote Coin Type, 基础代币的 coinType | `0x2::sui::SUI` |
| `pool_id` | 流动池的 object id | `0x...` |
| `clock_id` | 区块时间 Object | `0x6` |
| `base_usd_price_info_obj_id` | Pyth 基础代币/USD 价格信息的 ObjectID | `0x...` |
| `quote_usd_price_info_obj_id` | Pyth 计价代币/USD 价格信息的 ObjectID | `0x...` |
| `base_coin_id` |  用户用于交易卖出的基础代币的ObjectId（自己拥有的Coin Object） | `0x...` |
| `amount` | 交易中卖出的基础代币数量 | `10000000000` |
| `min_receive_quote` | 要求交易中买入的最小计价代币数量，可加滑点 | `10000000000` |

> command example

    ```shell
    sell_amount=0.2
    min_receive_quote=0.6
    base_coin_id=0xad278853e14e3027678d6dd6a226840d4520b351bf6e239042a353a7d24b053c

    sui client call --package $contract --module trader --function sell_base_coin \
    --type-args $base_coin_type $quote_coin_type \
    --args $pool_id $clock_id $base_usd_price_info_obj_id $quote_usd_price_info_obj_id $base_coin_id \
    $sell_amount $min_receive_quote
    ```

## BuyBaseCoin - 买入基础代币

**Module:** `trader`

**Function:** `buy_base_coin`

| 参数 | 说明 | 例如 |
| :--- | :--- | :--- |
| `base_coin_type` | Base Coin Type, 基础代币的 coinType |  `0x2::sui::SUI` |
| `quote_coin_type` | Quote Coin Type, 基础代币的 coinType | `0x2::sui::SUI` |
| `pool_id` | 流动池的 object id | `0x...` |
| `clock_id` | 区块时间 Object | `0x6` |
| `base_usd_price_info_obj_id` | Pyth 基础代币/USD 价格信息的 ObjectID | `0x...` |
| `quote_usd_price_info_obj_id` | Pyth 计价代币/USD 价格信息的 ObjectID | `0x...` |
| `quote_coin_id` |  用户用于交易卖出的计价代币的ObjectId（自己拥有的Coin Object） | `0x...` |
| `amount` | 交易中买入的基础代币数量 | `10000000000` |
| `max_pay_quote` | 要求交易中最大支付的计价代币数量，可加滑点 | `10000000000` |

> command example

    ```shell
    buy_amount=0.2
    max_pay_quote=1
    quote_coin_id=0x9a9a7b2a99a430e0dd64ac7542c6d07c3b0d1715bff479847f8f32cd125d71b6

    sui client call --package $contract --module trader --function buy_base_coin \
    --type-args $base_coin_type $quote_coin_type \
    --args $pool_id $clock_id $base_usd_price_info_obj_id $quote_usd_price_info_obj_id $quote_coin_id \
    $buy_amount $max_pay_quote
    ```

## QuerySellBaseCoin - 查询卖出基础代币能获得多少计价代币

**Module:** `trader`

**Function:** `query_sell_base_coin`

| 参数 | 说明 | 例如 |
| :--- | :--- | :--- |
| `base_coin_type` | Base Coin Type, 基础代币的 coinType |  `0x2::sui::SUI` |
| `quote_coin_type` | Quote Coin Type, 基础代币的 coinType | `0x2::sui::SUI` |
| `pool_id` | 流动池的 object id | `0x...` |
| `clock_id` | 区块时间 Object | `0x6` |
| `base_usd_price_info_obj_id` | Pyth 基础代币/USD 价格信息的 ObjectID | `0x...` |
| `quote_usd_price_info_obj_id` | Pyth 计价代币/USD 价格信息的 ObjectID | `0x...` |
| `amount` | 交易中买入的基础代币数量 | `10000000000` |

> command example

    ```shell
    sui client call --package $contract --module trader --function query_sell_base_coin \
    --type-args $base_coin_type $quote_coin_type \
    --args $pool_id $clock_id $base_usd_price_info_obj_id $quote_usd_price_info_obj_id $amount
    ```

    ```move
    public fun query_sell_base_coin<CoinTypeBase, CoinTypeQuote>(
        pool: &Pool<CoinTypeBase, CoinTypeQuote>, 
        clock: &Clock, 
        priceInfoObject: &PriceInfoObject, 
        amount: u64,
    ): u64
    ```

## QueryBuyBaseCoin - 查询买入基础代币需要支付多少计价代币

**Module:** `trader`

**Function:** `query_buy_base_coin`

| 参数 | 说明 | 例如 |
| :--- | :--- | :--- |
| `base_coin_type` | Base Coin Type, 基础代币的 coinType |  `0x2::sui::SUI` |
| `quote_coin_type` | Quote Coin Type, 基础代币的 coinType | `0x2::sui::SUI` |
| `pool_id` | 流动池的 object id | `0x...` |
| `clock_id` | 区块时间 Object | `0x6` |
| `base_usd_price_info_obj_id` | Pyth 基础代币/USD 价格信息的 ObjectID | `0x...` |
| `quote_usd_price_info_obj_id` | Pyth 计价代币/USD 价格信息的 ObjectID | `0x...` |
| `amount` | 交易中买入的基础代币数量 | `10000000000` |

> command example

    ```shell
    sui client call --package $contract --module trader --function query_buy_base_coin \
    --type-args $base_coin_type $quote_coin_type \
    --args $pool_id $clock_id $base_usd_price_info_obj_id $quote_usd_price_info_obj_id $amount
    ```

    ```move
    public fun query_buy_base_coin<CoinTypeBase, CoinTypeQuote>(
        pool: &Pool<CoinTypeBase, CoinTypeQuote>, 
        clock: &Clock, 
        priceInfoObject: &PriceInfoObject, 
        amount: u64,
    ): u64
    ```

source ./scripts/config.sh

#  public entry fun claim_base<CoinTypeBase, CoinTypeQuote>(
#         pool: &mut Pool<CoinTypeBase, CoinTypeQuote>,
#         base_capital_coin: Coin<PoolLiquidityCoin<CoinTypeBase>>,
#         ctx: &mut TxContext
#     ) 

sui client switch --address $liquidity_provider2

base_coin_id=0x117054fbda0d9339d7ca1f81bd8e82111ec1873052125a325be66611634cb22e

sui client call --package $contract --module settlement --function claim_base \
--type-args $base_coin_type $quote_coin_type \
--args $pool_id $base_coin_id  --gas-budget 100000000 --gas 0x85709137b4006ddfb6df5999e0dcbaa9ceef1b9f9b78f39f82deac2147b363bb

sui client switch --address $admin
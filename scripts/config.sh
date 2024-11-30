SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

if [ -f $SCRIPT_DIR/.env ]; then
  source $SCRIPT_DIR/.env
else
  echo ".env file not found!"
  exit 1
fi

# Addresses
admin=$ADMIN
maintainer=$MAINTAINER
pool_admin=$POOL_ADMIN
liquidity_provider1=$LIQUIDITY_PROVIDER1
liquidity_provider2=$LIQUIDITY_PROVIDER2
trader1=$TRADER1
trader2=$TRADER2

# Pool
contract=$PACKAGE
pool_id=$POOL_OBJECT_ID
upgrade_cap_id=$UPGRADE_CAP_ID

lp_fee_rate=$LP_FEE_RATE
protocol_fee_rate=$PROTOCOL_FEE_RATE
k=$K

# Capablity
admin_cap_id=$ADMIN_CAP_ID
pool_admin_cap_id=$POOL_ADMIN_CAP_ID
liquidity_operator1_cap_id=$LIQUIDITY_OPERATOR1_CAP_ID
liquidity_operator2_cap_id=$LIQUIDITY_OPERATOR2_CAP_ID

# Pyth beta
sui_price_id="0x50c67b3fd225db8912a424dd4baed60ffdde625ed2feaaf283724f9608fea266"
usdc_price_id="0x41f3625971ca2ed2263e78573fe5ce23e13d2558ed3f2e47ab0f84fb9e7ae722"
sui_usd_price_info_obj_id="0x1ebb295c789cc42b3b2a1606482cd1c7124076a0f5676718501fda8c7fd075a0"
usdc_usd_price_info_obj_id="0x9c4dd4008297ffa5e480684b8100ec21cc934405ed9a25d4e4d7b6259aad9c81"

# Base Coin
base_coin_id="0x6472974eb5ce28e76256bce0b5d0b9645d2e09164cb151bfe760a9e619fc1847"
base_coin_type="0x0000000000000000000000000000000000000000000000000000000000000002::sui::SUI"
base_coin_decimals=9
base_metadata_object_id=0x587c29de216efd4219573e08a1f6964d4fa7cb714518c2c8a0f29abfa264327d

# Quote Coin
quote_coin_id="0x6472974eb5ce28e76256bce0b5d0b9645d2e09164cb151bfe760a9e619fc1847"
quote_coin_type="0x6472974eb5ce28e76256bce0b5d0b9645d2e09164cb151bfe760a9e619fc1847::faucetcoin::FAUCETCOIN"
quote_coin_treasury_cap_id="0x8f024a8f7b75324355bf0a1836ee02bf11bc6f80ae2cd88d1d550513a8aca2b0"
quote_coin_mint_module="faucetcoin"
quote_coin_mint_func="mint_to_anyone"
quote_coin_decimals=6
quote_metadata_object_id=0x6d80b1d418b6a1ac26753e92fca613ebed8cbe2d6d8a2bfadcaaeba2a8dec8c2

# Clock
clock_id="0x6"

one=1e9

format_uint_func() {
    local input=$1  # amount
    local decimal=$2  # decimal
    local result=$(echo "$input * 10 ^ $decimal" | bc -l | awk '{print int($1)}')
    echo $result
}
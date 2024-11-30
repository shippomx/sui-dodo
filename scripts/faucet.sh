source ./scripts/config.sh

sui client switch --address $liquidity_provider1

sui client faucet

sui client switch --address $admin

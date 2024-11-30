source ./scripts/config.sh

sui client switch --address $admin


sui client call --package $contract --module script --function destroy_pool \
--type-args $base_coin_type $quote_coin_type \
--args $admin_cap_id

sui client switch --address $admin
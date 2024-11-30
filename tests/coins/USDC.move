module haedal_pmm::usdc {
  
  use sui::coin::{Self, TreasuryCap, Coin};
  use std::u64::pow;
  
  public struct USDC has drop {}
  
  public struct Treasury has key {
    id: UID,
    cap: TreasuryCap<USDC>
  }

  fun init(wtiness: USDC, ctx: &mut TxContext) {
    let decimals = 9u8;
    let symbol = b"USDC";
    let name = b"USDC";
    let description = b"Test USDC";
    let icon_url_option = option::none();
    let (mut treasuryCap, coinMeta) = coin::create_currency(
      wtiness,
      decimals,
      symbol,
      name,
      description,
      icon_url_option,
      ctx
    );
    let sender = tx_context::sender(ctx);
    coin::mint_and_transfer(
      &mut treasuryCap,
      pow(10, decimals + 3),
      sender,
      ctx
    );
    transfer::share_object(
      Treasury { id: object::new(ctx), cap: treasuryCap }
    );
    transfer::public_freeze_object(coinMeta)
  }
  
  public fun mint(treasury: &mut Treasury, amount: u64, ctx: &mut TxContext): Coin<USDC> {
    coin::mint(
      &mut treasury.cap,
      amount,
      ctx,
    )
  }
}

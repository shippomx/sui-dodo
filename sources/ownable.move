module haedal_pmm::ownable {

    use std::string::String;
    use sui::vec_map::{Self, VecMap};
    use sui::event;

    use haedal_pmm::version;

    const EPoolExists:u64 = 1;
    const EPoolNotExists:u64 = 2;
    const EDataNotMatchProgram:u64 = 2;

    public struct AdminCapVersionUpdated has copy, drop {
        operator: address,
        old_version: u64,
        new_version: u64,
    }

    // package admin
    public struct AdminCap has key {
        id: UID,
        pools: VecMap<String,ID>,
        version: u64
    }

    // pool admin
    public struct PoolAdminCap<phantom CoinTypeBase, phantom CoinTypeQuote> has key {
        id: UID,
    }

    // liquidity operator
    public struct LiquidityOperatorCap<phantom CoinTypeBase, phantom CoinTypeQuote> has key {
        id: UID,
    }

    public(package) fun grant_admin_cap(user:address, ctx: &mut TxContext) {
        let admin_cap = AdminCap{
            id: object::new(ctx),
            pools: vec_map::empty(),
            version:version::get_program_version(),
        };

        transfer::transfer(
            admin_cap,
            user
        );
    }
    
    public(package) fun grant_pool_admin_cap<CoinTypeBase, CoinTypeQuote>(user:address, ctx: &mut TxContext) {
        transfer::transfer(
            PoolAdminCap<CoinTypeBase, CoinTypeQuote>{
                id: object::new(ctx)
            },
            user
        );
    }

    public(package) fun grant_liquidity_operator_cap<CoinTypeBase, CoinTypeQuote>(user:address, ctx: &mut TxContext) {
        transfer::transfer(
            LiquidityOperatorCap<CoinTypeBase, CoinTypeQuote>{
                id: object::new(ctx)
            },
            user
        );
    }

    public fun assert_version(admin_cap: &AdminCap) {
        assert!(admin_cap.version == version::get_program_version(), EDataNotMatchProgram);
    }

    public(package) fun migrate(admin_cap: &mut AdminCap, ctx: &TxContext) {
        let version = version::get_program_version();
        assert!(admin_cap.version < version, EDataNotMatchProgram);
        event::emit(AdminCapVersionUpdated{old_version: admin_cap.version, new_version: version, operator: ctx.sender()});
        admin_cap.version = version;
    }

    public(package) fun register_pool(admin_cap: &mut AdminCap, key: String, pool_id:ID) {
        assert!(!admin_cap.pools.contains(&key), EPoolExists);
        admin_cap.pools.insert(key, pool_id);
    }

    public(package) fun destroy_pool(admin_cap: &mut AdminCap, key: String) {
        assert!(admin_cap.pools.contains(&key), EPoolNotExists);
        admin_cap.pools.remove(&key); // remove a key-value pair from the map
    }
} 

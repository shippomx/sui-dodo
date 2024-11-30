
module haedal_pmm::version {
    
    const PROGRAM_VERSION: u64 = 1;

    public fun get_program_version():u64 {
        PROGRAM_VERSION
    }
}
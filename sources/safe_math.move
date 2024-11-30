module haedal_pmm::safe_math {
    const One: u64 = 1_000_000_000;

    const EValueOverflow:u64 = 1;

    // left < One
    public fun lt_one(left: u64): bool {
        left < One
    }
    
    // left <= One
    public fun lte_one(left: u64): bool {
        left <= One
    }

    // left = One
    public fun eq_one(left: u64): bool {
        left == One
    }

    // left > One
    public fun gt_one(left: u64): bool {
        left > One
    }

    // left >= One
    public fun gte_one(left: u64): bool {
        left >= One
    }

    public fun check_u128_to_u64_overflow(value: u128) {
        assert!(value <= (std::u64::max_value!() as u128), EValueOverflow);
    }

    // x * y / z 
    public fun safe_mul_div_u64(x: u64, y: u64, z: u64): u64 {
        let value = (x as u128) * (y as u128) / (z as u128);
        check_u128_to_u64_overflow(value);
        (value as u64)
    }

    // (a1 * b1) >= (a2 * b2)
    public fun safe_compare_mul_u64(a1: u64, b1: u64, a2: u64, b2: u64): bool {
        let left = (a1 as u128) * (b1 as u128);
        let right = (a2 as u128) * (b2 as u128);
        left >= right
    }

    // x * y
    public fun safe_mul_u64(x: u64, y: u64): u64 {
        let value = (x as u128) * (y as u128);
        check_u128_to_u64_overflow(value);
        (value as u64)
    }

    // ceil(x / y)
    public fun safe_div_ceil_u64(x: u64, y: u64): u64 {
        let quotient = x / y;
        let remainder = x - quotient * y;
        if (remainder > 0) {
            (quotient + 1)
        } else {
            (quotient)
        }
    }
    // ceil(x * y / z)
    public fun safe_mul_div_ceil_u64(x: u64, y: u64, z: u64): u64 {
        let t:u128 = (x as u128) * (y as u128);
        let quotient = t / (z as u128);
        let remainder = t - quotient * (z as u128);
        let value = if (remainder > 0) {
            (quotient + 1)
        } else {
            (quotient)
        };
        check_u128_to_u64_overflow(value);
        (value as u64)
    }

    // target * d / One
    public fun mul( target:u64,  d:u64) :(u64) {
        safe_mul_div_u64(target,d,One)
    }

    // ceil(target * d / One)
    public fun mul_ceil( target:u64,  d:u64):(u64) {
        safe_div_ceil_u64(safe_mul_u64(target,d),One)
    }

    // floor(target / d)
    public fun div_floor( target:u64,  d:u64): (u64) {
        safe_mul_div_u64(target,One,d)
    }

    // ceil(target / d)
    public fun div_ceil( target:u64,  d:u64): (u64) {
         safe_mul_div_ceil_u64(target,One, d)
    }

    /*
        Integrate dodo curve fron V1 to V2
        require V0>=V1>=V2>0
        res = (1-k)i(V1-V2)+ikV0*V0(1/V2-1/V1)
        let V1-V2=delta
        res = i*delta*(1-k+k(V0^2/V1/V2))
    */
    public fun general_integrate(
        v0:u64,
        v1:u64,
        v2:u64,
        i:u64,
        k:u64
    ) :u64{
        let fair_amount = mul(i, v1 - v2); // i*delta
        let v0v0v1v2 = div_ceil(safe_mul_div_u64(v0,v0, v1), v2); // v0^2/v1/v2
        let penalty = mul(k, v0v0v1v2); // k(V0^2/V1/V2)
        mul(fair_amount, One - k + penalty)
    }

    /*
        The same with integration expression above, we have:
        i*deltaB = (Q2-Q1)*(1-k+kQ0^2/Q1/Q2)
        Given Q1 and deltaB, solve Q2
        This is a quadratic function and the standard version is
        aQ2^2 + bQ2 + c = 0, where
        a=1-k
        -b=(1-k)Q1-kQ0^2/Q1+i*deltaB
        c=-kQ0^2
        and Q2=(-b+sqrt(b^2+4(1-k)kQ0^2))/2(1-k)
        note: another root is negative, abondan
        if deltaBSig=true, then Q2>Q1
        if deltaBSig=false, then Q2<Q1
    */
    public fun solve_quadratic_function_for_trade (q0:u64, q1:u64, idelta_b:u64, delta_b_sig:bool, k:u64):(u64) {
        // calculate -b value and sig
        // -b = (1-k)Q1-kQ0^2/Q1+i*deltaB
        let mut kq02q1 = safe_mul_div_u64(mul(k,q0), q0, q1) ;
        let mut b = mul(One - k, q1); // (1-k)Q1
        if (delta_b_sig) {
            b = b + idelta_b; // (1-k)Q1+i*deltaB
        } else {
            kq02q1 = kq02q1 + idelta_b; // i*deltaB+kQ0^2/Q1
        };
       
        let (minusb_sig) = if (b >= kq02q1) {
            b = b - kq02q1;
            true
        }else {
            b = kq02q1 - b;
            false
        };

        let square_root = get_square_root(k,q0,b); // sqrt(b*b+4(1-k)kQ0*Q0)

        // final res
        let denominator = safe_mul_u64( One - k, 2); // 2(1-k)
        let numerator:u64;
        if (minusb_sig) {
            numerator = b + square_root;
        } else {
            numerator = square_root - b;
        };

        if (delta_b_sig) {
            div_floor(numerator, denominator)
        } else {
            div_ceil(numerator, denominator)
        }
    }
    // TODO check overflow cut
    fun get_square_root(k:u64, q0:u64, b:u64):u64 {
        // calculate sqrt
        let mut square_root = 4 * (One - k as u128) *  // 4(1-k)
        ((k as u128) * (q0 as u128) / (One as u128) * (q0 as u128)) / (One as u128); // kQ0^2
        
        square_root = std::u128::sqrt((b as u128) * (b as u128) + square_root); // sqrt(b*b+4(1-k)kQ0*Q0)
        check_u128_to_u64_overflow(square_root);
        square_root as u64
    }

    /*
        Start from the integration function
        i*deltaB = (Q2-Q1)*(1-k+kQ0^2/Q1/Q2)
        Assume Q2=Q0, Given Q1 and deltaB, solve Q0
        let fairAmount = i*deltaB
    */
    public fun solve_quadratic_function_for_target(
         v1:u64,
         k:u64,
         fair_amount:u64
    ) :(u64) {
        // V0 = V1+V1*(sqrt-1)/2k
        let mut sqrt = div_ceil(mul(k,fair_amount)*4, v1);
        sqrt = std::u128::sqrt(((sqrt as u128) + (One as u128)) * (One as u128)) as u64;
        let premium = div_ceil(sqrt - One,safe_mul_u64(k, 2));
        // // V0 is greater than or equal to V1 according to the solution
        mul(v1, One + premium)
    }
}
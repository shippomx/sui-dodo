#[test_only]
module haedal_pmm::safe_math_tests;

// use sui::test_scenario;

use haedal_pmm::safe_math;

const ELtOne:u64 = 1;
const ELteOne:u64 = 2;
const EEqOne:u64 = 3;
const EGtOne:u64 = 4;
const EGteOne:u64 = 5;
const EMulDiv:u64 = 6;
const ECompareMul:u64 = 7;
const EMul:u64 = 8;

#[test]
fun test_lt_one_lt() {
    let left = 100_000_000;
    assert!(safe_math::lt_one(left), ELtOne);
}

#[test]
#[expected_failure(abort_code = ELtOne)]
fun test_lt_one_eq() {
    let left = 1_000_000_000;
    assert!(safe_math::lt_one(left), ELtOne);
}

#[test]
#[expected_failure(abort_code = ELtOne)]
fun test_lt_one_gt() {
    let left = 2_000_000_000;
    assert!(safe_math::lt_one(left), ELtOne);
}

#[test]
fun test_lte_one_lt() {
    let left = 100_000_000;
    assert!(safe_math::lte_one(left), ELteOne);
}

#[test]
fun test_lte_one_eq() {
    let left = 1_000_000_000;
    assert!(safe_math::lte_one(left), ELteOne);
}

#[test]
#[expected_failure(abort_code = ELteOne)]
fun test_lte_one_gt() {
    let left = 2_000_000_000;
    assert!(safe_math::lte_one(left), ELteOne);
}

#[test]
fun test_eq_one() {
    let left = 1_000_000_000;
    assert!(safe_math::eq_one(left), EEqOne);
}

#[test]
#[expected_failure(abort_code = EEqOne)]
fun test_eq_one_gt() {
    let left = 2_000_000_000;
    assert!(safe_math::eq_one(left), EEqOne);
}

#[test]
#[expected_failure(abort_code = EEqOne)]
fun test_eq_one_lt() {
    let left = 200_000_000;
    assert!(safe_math::eq_one(left), EEqOne);
}

#[test]
fun test_gt_one_gt() {
    let left = 2_000_000_000;
    assert!(safe_math::gt_one(left), EGtOne);
}

#[test]
#[expected_failure(abort_code = EGtOne)]
fun test_gt_one_eq() {
    let left = 1_000_000_000;
    assert!(safe_math::gt_one(left), EGtOne);
}

#[test]
#[expected_failure(abort_code = EGtOne)]
fun test_gt_one_lt() {
    let left = 100_000_000;
    assert!(safe_math::gt_one(left), EGtOne);
}

#[test]
fun test_gte_one_gt() {
    let left = 2_000_000_000;
    assert!(safe_math::gte_one(left), EGteOne);
}

#[test]
fun test_gte_one_eq() {
    let left = 1_000_000_000;
    assert!(safe_math::gte_one(left), EGteOne);
}

#[test]
#[expected_failure(abort_code = EGteOne)]
fun test_gte_one_lt() {
    let left = 100_000_000;
    assert!(safe_math::gte_one(left), EGteOne);
}

#[test]
fun test_safe_mul_div_u64() {
    let x = 1;
    let y = 2;
    let z = 2;
    // 1 * 2 / 2 = 1
    assert!(safe_math::safe_mul_div_u64(x, y, z) == 1, EMulDiv);
}

#[test]
#[expected_failure(abort_code = EMulDiv)]
fun test_safe_mul_div_u64_failure() {
    let x = 1;
    let y = 2;
    let z = 2;
    // 1 * 2 / 2 != 2
    assert!(safe_math::safe_mul_div_u64(x, y, z) == 2, EMulDiv);
}

#[test]
fun test_safe_compare_mul_u64_eq() {
    let a1 = 2;
    let b1 = 1;
    let a2 = 1;
    let b2 = 2;
    // (1 * 2) == (1 * 2)
    assert!(safe_math::safe_compare_mul_u64(a1,b1, a2, b2), ECompareMul);
}

#[test]
fun test_safe_compare_mul_u64_gt() {
    let a1 = 2;
    let b1 = 2;
    let a2 = 1;
    let b2 = 2;
    // (2 * 2) > (1 * 2)
    assert!(safe_math::safe_compare_mul_u64(a1,b1, a2, b2), ECompareMul);
}

#[test]
#[expected_failure(abort_code = ECompareMul)]
fun test_safe_compare_mul_u64_failure() {
    let a1 = 2;
    let b1 = 1;
    let a2 = 2;
    let b2 = 2;
    // (1 * 2) < (2 * 2)
    assert!(safe_math::safe_compare_mul_u64(a1,b1, a2, b2), ECompareMul);
}

#[test]
fun test_safe_mul_u64() {
    let x = 2;
    let y = 2;
    assert!(safe_math::safe_mul_u64(x, y) == 4, EMul);
}

#[test]
#[expected_failure(abort_code = EMul)]
fun test_safe_mul_u64_failure() {
    let x = 1;
    let y = 2;
    assert!(safe_math::safe_mul_u64(x, y) == 4, EMul);
}

#[test]
fun test_safe_div_ceil_u64() {
    let x = 9;
    let y = 10;
    // ceil( 9 / 10 ) = 1
    assert!(safe_math::safe_div_ceil_u64(x, y) == 1, 0);
}

#[test]
fun test_mul() {
    let x = 20;
    let y = 100_000_000;
    // 20 * 1_100_000_000 / One
    assert!(safe_math::mul(x, y) == 2, 0);
}

#[test]
fun test_mul_ceil() {
    let x = 19;
    let y = 100_000_000;
    // ceil( 19 * 1_100_000_000 / One )
    assert!(safe_math::mul_ceil(x, y) == 2, 0);
}

#[test]
fun test_div_floor() {
    let x = 19;
    let y = 10_000_000_000;
    // floor( 19 * One / 10_000_000_000 )
    assert!(safe_math::div_floor(x, y) == 1, 0);
}

#[test]
fun test_div_ceil() {
    let x = 19;
    let y = 10_000_000_000;
    // ceil( 19 * One / 10_000_000_000 )
    assert!(safe_math::div_ceil(x, y) == 2, 0);
}

#[test]
fun test_general_integrate() {
    let v0 = 1_000_000_000;
    let v1 = 1_000_000_000;
    let v2 = 900_000_000;
    let i = 1_500_000_000;
    let k = 20_000_000;

    assert!(safe_math::general_integrate(v0,v1,v2,i,k) == 150333333, 0);
}

#[test]
fun test_general_integrate_max() {
    let v0 = 1_000_000_000_000;
    let v1 = 1_000_000_000_000;
    let v2 = 900_000_000_000;
    let i = 1_500_000_000_000;
    let k = 20_000_000;

    assert!(safe_math::general_integrate(v0,v1,v2,i,k) == 150333333300000, 0);
}

%lang starknet

from src.utils.math import clamp, mul_then_div

@external
func test_clamp{range_check_ptr}() {
    alloc_locals;
    let res1 = clamp(10, 15, 20);
    let res2 = clamp(10, 25, 20);
    let res3 = clamp(10, 5, 20);
    let res4 = clamp(10, 10, 20);
    let res5 = clamp(10, 20, 20);
    let res6 = clamp(10, -1, 20);
    let res7 = clamp(-1, 5, 20);
    let res8 = clamp(-10, -7, -1);

    assert res1 = 15;
    assert res2 = 20;
    assert res3 = 10;
    assert res4 = 10;
    assert res5 = 20;
    assert res6 = 10;
    assert res7 = 5;
    assert res8 = -7;

    return ();
}

@external
func test_mul_then_div{range_check_ptr}() {
    assert mul_then_div(10, 80, 100) = 8;
    assert mul_then_div(26, 50, 100) = 13;
    assert mul_then_div(1, 100, 100) = 1;
    assert mul_then_div(10, 99, 100) = 9;
    assert mul_then_div(10, 101, 100) = 10;
    assert mul_then_div(10, 109, 100) = 10;
    assert mul_then_div(10, 110, 100) = 11;

    assert mul_then_div(10, 100, 110) = 9;
    return ();
}

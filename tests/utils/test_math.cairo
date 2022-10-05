%lang starknet

from src.utils.math import clamp, percentage

@external
func test_clamp{range_check_ptr}() {
    alloc_locals;
    let (local res1) = clamp(10, 15, 20);
    let (local res2) = clamp(10, 25, 20);
    let (local res3) = clamp(10, 5, 20);
    let (local res4) = clamp(10, 10, 20);
    let (local res5) = clamp(10, 20, 20);
    let (local res6) = clamp(10, -1, 20);
    let (local res7) = clamp(-1, 5, 20);
    let (local res8) = clamp(-10, -7, -1);

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
func test_percentage{range_check_ptr}() {
    assert percentage(10, 80) = 8;
    assert percentage(26, 50) = 13;
    assert percentage(1, 100) = 1;
    assert percentage(10, 99) = 9;
    assert percentage(10, 101) = 10;
    assert percentage(10, 109) = 10;
    assert percentage(10, 110) = 11;
    return ();
}

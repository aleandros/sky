defmodule SkyTest do
  use ExUnit.Case
  doctest Sky

  # Since basic functionality is checked in
  # the doctests, let's focus on composing
  # this library's functions.

  test "compose a safe float division" do
    safe_float_div =
      fn(a, b) -> a / b end
      |> Sky.tupleize
      |> Sky.noraise

    assert safe_float_div.({1, 2}) == {:ok, 0.5}
  end

  test "make a function work on lists" do
    inc = fn v -> v + 1 end
    dec = fn v -> v - 1 end

    lift_to_list =
      (&Enum.map/2)
      |> Sky.swap
      |> Sky.curry

    inc_list = lift_to_list.(inc)
    dec_list = lift_to_list.(dec)

    assert inc_list.([1,2,3]) == [2, 3, 4]
    assert dec_list.([1,2,3]) == [0, 1, 2]
  end

  test "negate a predicate" do
    target_map = %{a: 1, b: 2}

    missing? =
      (&Map.has_key?/2)
      |> Sky.curry([target_map])
      |> Sky.negate

    assert missing?.(:c)
    refute missing?.(:a)
  end

  test "compose for avoiding branching" do
    map = %{a: 1, b: 2, c: 3}
    inc = fn n -> n + 1 end

    inc_value =
      inc
      |> Sky.apply_if(Sky.negate(&is_nil/1))

    assert (map |> Map.get(:a) |> inc_value.()) == 2
    assert (map |> Map.get(:d) |> inc_value.()) == nil

    inc_lifted = inc |> Sky.noraise

    assert (map |> Map.get(:a) |> inc_lifted.()) == {:ok, 2}
    assert {:error, _} = (map |> Map.get(:d) |> inc_lifted.())
  end

  test "compose for creating different types of lift functions" do
    lift_predicate =
      (&Sky.reject_if/2)
      |> Sky.swap
      |> Sky.curry

    non_negative? = fn x -> x >= 0 end

    lift_positive = lift_predicate.(non_negative?)
    safe_sqrt = lift_positive.(&:math.sqrt/1)

    assert {:ok, 3.0} = safe_sqrt.(9)
    assert :error = safe_sqrt.(-1)

    lift_non_zero = lift_predicate.(fn n -> n != 0 end)
    safe_log = lift_non_zero.(&:math.log/1)

    assert {:ok, 0.0} == safe_log.(1)
    assert :error = safe_log.(0)
  end
end

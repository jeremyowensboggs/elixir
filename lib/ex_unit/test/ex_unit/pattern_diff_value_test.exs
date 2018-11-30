Code.require_file("../test_helper.exs", __DIR__)

defmodule ExUnit.PatternDiffValueTest do
  use ExUnit.Case

  alias ExUnit.{ContainerDiff, Pattern, PatternDiff, PinDiff}

  describe "value matching" do
    test "integer pattern match" do
      simple =
        quote do
          1
        end

      pattern = Pattern.new(simple, [], %{})

      expected_match = %PatternDiff{
        type: :value,
        lh: %{ast: pattern.val},
        rh: 1,
        diff_result: :eq
      }

      actual = PatternDiff.compare(pattern, 1)

      assert actual == expected_match

      expected_no_match = %{expected_match | rh: 2, diff_result: :neq}

      actual = PatternDiff.compare(pattern, 2)

      assert actual == expected_no_match
    end

    test "string pattern match" do
      simple =
        quote do
          "hello"
        end

      pattern = Pattern.new(simple, [], %{})

      expected_match = %PatternDiff{
        type: :value,
        lh: %{ast: pattern.val},
        rh: "hello",
        diff_result: :eq
      }

      actual = PatternDiff.compare(pattern, "hello")

      assert actual == expected_match

      expected_no_match = %{
        expected_match
        | rh: "good bye",
          diff_result: :neq
      }

      actual = PatternDiff.compare(pattern, "good bye")

      assert actual == expected_no_match
    end

    test "atom match" do
      simple =
        quote do
          :a
        end

      pattern = Pattern.new(simple, [], %{})

      expected_match = %PatternDiff{
        type: :value,
        lh: %{ast: pattern.val},
        rh: :a,
        diff_result: :eq
      }

      actual = PatternDiff.compare(pattern, :a)

      assert actual == expected_match

      expected_no_match = %{expected_match | rh: :b, diff_result: :neq}

      actual = PatternDiff.compare(pattern, :b)

      assert actual == expected_no_match
    end

    test "float pattern match" do
      simple =
        quote do
          1.0
        end

      pattern = Pattern.new(simple, [], %{})

      expected_match = %PatternDiff{
        type: :value,
        lh: %{ast: pattern.val},
        rh: 1.0,
        diff_result: :eq
      }

      actual = PatternDiff.compare(pattern, 1.0)

      assert actual == expected_match

      expected_no_match = %{expected_match | rh: 2.0, diff_result: :neq}

      actual = PatternDiff.compare(pattern, 2.0)

      assert actual == expected_no_match
    end
  end

  describe "that dissimilar things are labeled as different" do
    test "that map is not anything else" do
      map =
        quote do
          %{a: 1}
        end

      pattern = Pattern.new(map, [], %{})
      actual = PatternDiff.compare(pattern, 1)
      assert actual.type == :different

      actual = PatternDiff.compare(pattern, "string")
      assert actual.type == :different

      actual = PatternDiff.compare(pattern, 2.0)
      assert actual.type == :different

      actual = PatternDiff.compare(pattern, [1, 2, 3])
      assert actual.type == :different

      actual = PatternDiff.compare(pattern, {1, 2})
      assert actual.type == :different

      actual = PatternDiff.compare(pattern, {1, 2, 3})
      assert actual.type == :different

      actual = PatternDiff.compare(pattern, :a)
      assert actual.type == :different
    end

    test "that a list is not anything else" do
      map =
        quote do
          [1, 2, 3]
        end

      pattern = Pattern.new(map, [], %{})
      actual = PatternDiff.compare(pattern, 1)
      assert actual.type == :different

      actual = PatternDiff.compare(pattern, "string")
      assert actual.type == :different

      actual = PatternDiff.compare(pattern, 2.0)
      assert actual.type == :different

      actual = PatternDiff.compare(pattern, %{a: 1, b: 2})
      assert actual.type == :different

      actual = PatternDiff.compare(pattern, {1, 2})
      assert actual.type == :different

      actual = PatternDiff.compare(pattern, {1, 2, 3})
      assert actual.type == :different

      actual = PatternDiff.compare(pattern, :a)
      assert actual.type == :different
    end

    test "that a tuple is not anything else" do
      tuple =
        quote do
          {1, 2, 3}
        end

      pattern = Pattern.new(tuple, [], %{})
      actual = PatternDiff.compare(pattern, 1)
      assert actual.type == :different

      actual = PatternDiff.compare(pattern, "string")
      assert actual.type == :different

      actual = PatternDiff.compare(pattern, 2.0)
      assert actual.type == :different

      actual = PatternDiff.compare(pattern, %{a: 1, b: 2})
      assert actual.type == :different

      actual = PatternDiff.compare(pattern, [1, 2])
      assert actual.type == :different

      actual = PatternDiff.compare(pattern, [1, 2, 3])
      assert actual.type == :different

      actual = PatternDiff.compare(pattern, :a)
      assert actual.type == :different

      tuple =
        quote do
          {1, 2}
        end

      pattern = Pattern.new(tuple, [], %{})
      actual = PatternDiff.compare(pattern, 1)
      assert actual.type == :different

      actual = PatternDiff.compare(pattern, "string")
      assert actual.type == :different

      actual = PatternDiff.compare(pattern, 2.0)
      assert actual.type == :different

      actual = PatternDiff.compare(pattern, %{a: 1, b: 2})
      assert actual.type == :different

      actual = PatternDiff.compare(pattern, [1, 2])
      assert actual.type == :different

      actual = PatternDiff.compare(pattern, [1, 2, 3])
      assert actual.type == :different

      actual = PatternDiff.compare(pattern, :a)
      assert actual.type == :different
    end
  end

  test "simple unbound var" do
    simple =
      quote do
        a
      end

    pattern = Pattern.new(simple, [], %{a: :ex_unit_unbound_var})

    expected_match = %PatternDiff{
      type: :value,
      lh: %{ast: pattern.val},
      rh: 1,
      diff_result: :eq
    }

    actual = PatternDiff.compare(pattern, 1)
    assert actual == expected_match
  end

  test "simple bound var" do
    simple =
      quote do
        {a, a}
      end

    pattern = Pattern.new(simple, [], %{a: :ex_unit_unbound_var})
    expected_var_pattern = %{ast: {:a, [], ExUnit.PatternDiffValueTest}}

    expected_match = %ContainerDiff{
      type: :tuple,
      items: [
        %PatternDiff{
          type: :value,
          lh: expected_var_pattern,
          rh: 1,
          diff_result: :eq
        },
        %PatternDiff{
          type: :value,
          lh: expected_var_pattern,
          rh: 1,
          diff_result: :eq
        }
      ]
    }

    actual = PatternDiff.compare(pattern, {1, 1})
    assert actual == expected_match

    expected_no_match = %ContainerDiff{
      type: :tuple,
      items: [
        %PatternDiff{
          type: :value,
          lh: expected_var_pattern,
          rh: 1,
          diff_result: :eq
        },
        %PatternDiff{
          type: :value,
          lh: expected_var_pattern,
          rh: 2,
          diff_result: :neq
        }
      ]
    }

    actual = PatternDiff.compare(pattern, {1, 2})
    assert actual == expected_no_match
  end

  test "pin" do
    simple =
      quote do
        ^a
      end

    pattern = Pattern.new(simple, [a: 1], %{})

    expected_match = %PatternDiff{
      type: :value,
      lh: %{ast: {:^, [], [{:a, [], ExUnit.PatternDiffValueTest}]}},
      rh: 1,
      diff_result: :eq
    }

    actual = PatternDiff.compare(pattern, 1)
    assert actual == expected_match

    actual = PatternDiff.compare(pattern, 2)

    expected_match = %PinDiff{
      diff: %PatternDiff{
        type: :value,
        lh: %{ast: 1},
        rh: 2,
        diff_result: :neq
      },
      diff_result: :neq,
      pin: :a
    }

    assert actual == expected_match
  end
end
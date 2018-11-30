Code.require_file("../test_helper.exs", __DIR__)

defmodule ExUnit.PatternDiffWhenTest do
  use ExUnit.Case

  alias ExUnit.{ContainerDiff, Pattern, PatternDiff, WhenDiff}

  test "when" do
    simple =
      quote do
        a when is_integer(a)
      end

    pattern = Pattern.new(simple, [], %{{:a, ExUnit.PatternDiffWhenTest} => :ex_unit_unbound_var})

    expected_match = %ContainerDiff{
      type: :when,
      items: [
        %PatternDiff{
          type: :value,
          lh: %{ast: {:a, [], ExUnit.PatternDiffWhenTest}},
          rh: 1,
          diff_result: :eq
        },
        %WhenDiff{
          op:
            {:is_integer, [context: ExUnit.PatternDiffWhenTest, import: Kernel],
             [{:a, [], ExUnit.PatternDiffWhenTest}]},
          bindings: %{{:a, ExUnit.PatternDiffWhenTest} => 1},
          result: :eq
        }
      ]
    }

    actual = PatternDiff.compare(pattern, 1)

    assert actual == expected_match

    expected_no_match = %ContainerDiff{
      type: :when,
      items: [
        %PatternDiff{
          type: :value,
          lh: %{ast: {:a, [], ExUnit.PatternDiffWhenTest}},
          rh: "foo",
          diff_result: :eq
        },
        %WhenDiff{
          op:
            {:is_integer, [context: ExUnit.PatternDiffWhenTest, import: Kernel],
             [{:a, [], ExUnit.PatternDiffWhenTest}]},
          bindings: %{{:a, ExUnit.PatternDiffWhenTest} => "foo"},
          result: :neq
        }
      ]
    }

    actual = PatternDiff.compare(pattern, "foo")
    assert actual == expected_no_match
  end

  test "multiple when clauses, :or" do
    simple =
      quote do
        a when is_integer(a) or is_binary(a)
      end

    pattern = Pattern.new(simple, [], %{{:a, ExUnit.PatternDiffWhenTest} => :ex_unit_unbound_var})

    expected_match = %ContainerDiff{
      type: :when,
      items: [
        %PatternDiff{
          type: :value,
          lh: %{ast: {:a, [], ExUnit.PatternDiffWhenTest}},
          rh: 1,
          diff_result: :eq
        },
        %WhenDiff{
          op: :or,
          bindings: [
            %WhenDiff{
              op:
                {:is_integer, [context: ExUnit.PatternDiffWhenTest, import: Kernel],
                 [{:a, [], ExUnit.PatternDiffWhenTest}]},
              bindings: %{{:a, ExUnit.PatternDiffWhenTest} => 1},
              result: :eq
            },
            %WhenDiff{
              op:
                {:is_binary, [context: ExUnit.PatternDiffWhenTest, import: Kernel],
                 [{:a, [], ExUnit.PatternDiffWhenTest}]},
              bindings: %{{:a, ExUnit.PatternDiffWhenTest} => 1},
              result: :neq
            }
          ],
          result: :eq
        }
      ]
    }

    actual = PatternDiff.compare(pattern, 1)
    assert actual == expected_match

    expected_no_match = %ContainerDiff{
      type: :when,
      items: [
        %PatternDiff{
          type: :value,
          lh: %{ast: {:a, [], ExUnit.PatternDiffWhenTest}},
          rh: :foo,
          diff_result: :eq
        },
        %WhenDiff{
          op: :or,
          bindings: [
            %WhenDiff{
              op:
                {:is_integer, [context: ExUnit.PatternDiffWhenTest, import: Kernel],
                 [{:a, [], ExUnit.PatternDiffWhenTest}]},
              bindings: %{{:a, ExUnit.PatternDiffWhenTest} => :foo},
              result: :neq
            },
            %WhenDiff{
              op:
                {:is_binary, [context: ExUnit.PatternDiffWhenTest, import: Kernel],
                 [{:a, [], ExUnit.PatternDiffWhenTest}]},
              bindings: %{{:a, ExUnit.PatternDiffWhenTest} => :foo},
              result: :neq
            }
          ],
          result: :neq
        }
      ]
    }

    actual = PatternDiff.compare(pattern, :foo)
    assert actual == expected_no_match
  end

  test "multiple when clauses, :and" do
    simple =
      quote do
        {a, b} when is_integer(a) and is_binary(b)
      end

    pattern =
      Pattern.new(simple, [], %{
        {:a, ExUnit.PatternDiffWhenTest} => :ex_unit_unbound_var,
        {:b, ExUnit.PatternDiffWhenTest} => :ex_unit_unbound_var
      })

    expected_match = %ContainerDiff{
      type: :when,
      items: [
        %ContainerDiff{
          type: :tuple,
          items: [
            %PatternDiff{
              type: :value,
              lh: %{ast: {:a, [], ExUnit.PatternDiffWhenTest}},
              rh: 1,
              diff_result: :eq
            },
            %PatternDiff{
              type: :value,
              lh: %{ast: {:b, [], ExUnit.PatternDiffWhenTest}},
              rh: "foo",
              diff_result: :eq
            }
          ]
        },
        %WhenDiff{
          op: :and,
          bindings: [
            %WhenDiff{
              op:
                {:is_integer, [context: ExUnit.PatternDiffWhenTest, import: Kernel],
                 [{:a, [], ExUnit.PatternDiffWhenTest}]},
              bindings: %{
                {:a, ExUnit.PatternDiffWhenTest} => 1,
                {:b, ExUnit.PatternDiffWhenTest} => "foo"
              },
              result: :eq
            },
            %WhenDiff{
              op:
                {:is_binary, [context: ExUnit.PatternDiffWhenTest, import: Kernel],
                 [{:b, [], ExUnit.PatternDiffWhenTest}]},
              bindings: %{
                {:b, ExUnit.PatternDiffWhenTest} => "foo",
                {:a, ExUnit.PatternDiffWhenTest} => 1
              },
              result: :eq
            }
          ],
          result: :eq
        }
      ]
    }

    actual = PatternDiff.compare(pattern, {1, "foo"})
    assert actual == expected_match
  end
end
# Sky

[![Build Status](https://travis-ci.org/aleandros/sky.svg?branch=master)](https://travis-ci.org/aleandros/sky)

A small set of functions for manipulation functions in elixir.

## Rationale

The pipe operator is probably one of the coolest features of the language. While
not exclusive to elixir, it's a core part of writing readable programs. You just
begin with your data and transform it step by step.

But Elixir is functional. Functions are data too. Why not transforming them as we see fit?
This small collection of functions attempts to provide a way to do just that.

One important aspect of this library is that it tries to be useful as much as it
is intended to be fun thought experiment. That's why everything is provided with
functions instead of macros. Why? Maybe I'm not smart enough for macros. But also
I believe that we can go a long, long way without them.

## Examples

You can find more of these in the documentation or in the tests, but let's
begin with a simple one:

```elixir
safe_float_div = 
  fn(a, b) -> a / b end
  |> Sky.tupleize
  |> Sky.noraise

safe_float_div.({1, 0})
# => {:error, %ArithmeticError{message: "bad argument in arithmetic expression"}}

safe_float_div.({1, 2})
# => {:ok, 0.5}
```

The idea is to create more sophisticated functions without complicated branching
that distracts us from our original intent.

Let's look at something more interesting. The square root of a number is not defined
for negative numbers, and the logarithm is undefined for non-positive numbers
(negative numbers and zero). How could we take our arithmetic functions and make
them safe, yet leave our code free of conditionals and unnecessary pattern matching?

```elixir
lift_predicate =
  (&Sky.reject_if/2)
  |> Sky.swap
  |> Sky.curry

non_negative? = fn x -> x >= 0 end

lift_positive = lift_predicate.(non_negative?)
safe_sqrt = lift_positive.(&:math.sqrt/1)

safe_sqrt.(9)  # => {:ok, 3.0}
safe_sqrt.(-1) # => :error
```
Now let's reuse our `lift_predicate` function to do something a the non-zero numbers.

```elixir
lift_non_zero = lift_predicate.(fn n -> n != 0 end)
safe_log = lift_non_zero.(&:math.log/1)

safe_log.(1) # => {:ok, 0.0}
safe_log.(0) # => :error
```

## Gotchas

There are probably missing functions and possible use patterns that can arise
if this thing is used in more realistic environments.

Also, modifying functions through piping, while powerful, can probably get unreadable
pretty soon, so piping functions through the Sky API probably should be done in small
steps.

Another important thing is that when we create anonymous functions and bind them
to variables, the syntax for using them in pipes is kind of clunky.

```elixir
inc = fn x -> x + 1 end
x = 1 |> inc.() |> inc.()
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `sky` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:sky, "~> 0.1.0"}]
end
```


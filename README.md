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
is intended to be fun thought experiment. ~~That's why everything is provided with
functions instead of macros. Why? Maybe I'm not smart enough for macros. But also
I believe that we can go a long, long way without them.~~ While the original idea was to use only functions, turns out that's stupid since it undervalues useful
functionality that can be added with them. The core of Sky is functions only, but
a module named `Sky.Ext` in order to have a richer API.

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

## Syntax extensions

The module `Sky.Ext` provides a couple of macros and a couple of operators
in order to have a more complete experience. The most basic macro, `op/1`,
attempts to make easier to partially apply arguments to operators.

```elixir
import Sky.Ext

4
|> op(1 / _)
|> op(_ * 2) # => 0.5
```

The other macros attempt to provide pseudo-inverse functionality for
`tupleize/1` and `curry/1` via `untuple/2` and `uncurry/2` respectively. Note
that the arity must be explicitly provided and that guards cannot be recovered.

```elixir
import Sky.Ext

add = fn(a, b) -> a + b end
addc = Sky.curry(add)
addt = Sky.tupleize(add)

addc.(1).(2) # => 3
addt.({1, 2}) # => 3

uncurry(addc, 2).(1, 2) # => 3
untuple(addt, 2).(1, 2) # => 3
```

The operators provided are explained in the next section.

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
x = 1 |> inc.() |> inc.() # => 3
```

This can be made more readable by using the operators provided in `Sky.Ext`
(Credit goes to [Vic](http://github.com/vic))

```elixir
import Sky.Ext

inc = fn x -> x + 1 end
x = 1 ~> inc ~> inc # => 3
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `sky` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:sky, "~> 0.1.0"}]
end
```


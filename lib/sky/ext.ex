defmodule Sky.Ext do
  @moduledoc """
  A set of operators and macros to enhance
  the experience of composing and manipulating
  functions through the `Sky` functions.
  """

  @doc """
  Feed a value into a unary function.
  Credit for this one goes to Víctor Borja (github.com/vic)

  This provides a syntactically cleaner way
  to pipe a value through a set of anonymous functions.

  ## Example

  On its most basic form, pipe a value from left
  to right through unary functions.

      iex> import Sky.Ext, only: [~>: 2]
      iex> inc = fn x -> x + 1 end
      iex> halve = fn x -> x / 2 end
      iex> 11 ~> inc ~> halve
      6.0

  It can also be used to compose functions and
  create new ones.

      iex> import Sky.Ext, only: [~>: 2]
      iex> invert = fn x -> 1 / x end
      iex> double = fn x -> x * 2 end
      iex> f = invert ~> double
      iex> f.(0.5)
      4.0
  """
  def f ~> g when is_function(f) and is_function(g) do
    fn x -> x |> f.() |> g.() end
  end
  def v ~> f when is_function(f), do: f.(v)

  @doc """
  Pipe functions from right to left, effectively
  achieving the same effect as the classic *compose*
  function.

  All functions are assumed to be unary.

  ## Examples

      iex> import Sky.Ext, only: [<~: 2]
      iex> inc = fn x -> x + 1 end
      iex> halve = fn x -> x / 2 end
      iex> composed = halve <~ halve <~ inc
      iex> composed.(11)
      3.0

  Values can be fed directly into the pipe:

      iex> import Sky.Ext, only: [<~: 2]
      iex> inc = fn x -> x + 1 end
      iex> halve = fn x -> x / 2 end
      iex> halve <~ halve <~ inc <~ 11
      3.0
  """
  def g <~ f when is_function(g) and is_function(f) do
    fn x -> x ~> f ~> g end
  end
  def f <~ v when is_function(f), do: f.(v)

  @doc """
  Uncurry takes a unary function *f* curreid until *n* = *arity*
  places, and returns a function of arity *n*, that is in charge
  of evaluating the curried function until a value is produced.

  Note that this is **almost**, but not quite, the inverse of
  the `Sky.curry/1` function, but there's no attempt to recover
  the original guards, and the arity is required for it to work.

  ## Example

      iex> import Sky.Ext, only: [uncurry: 2]
      iex> import Sky, only: [curry: 1]
      iex> volume = fn (x, y, z) -> x * y * z end
      iex> vc = curry(volume)
      iex> vc.(1).(2).(3)
      6
      iex> uncurry(vc, 3).(1, 2, 3)
      6
  """
  defmacro uncurry(f, arity) do
    vars = n_vars(arity)

    quote do
      fn(unquote_splicing(vars)) ->
        list = [unquote_splicing(vars)]
        Enum.reduce(list, unquote(f), fn(var, func) ->
          apply(func, [var])
        end)
      end
    end
  end

  @doc """
  Given an unary function *f* that receives a tuple of size
  *n* = *arity*, return a function of arity *n* that invokes
  *f* with the given arguments.

  This serves **almost** like the inverse of `Sky.tupleize/1`,
  but keep in mind that since this function does not add any
  guards that were in the original function, `untuple` is *not*
  the strict inverse of `Sky.tupleize/1`.

  ## Example

      iex> import Sky.Ext, only: [untuple: 2]
      iex> reverse = fn {a, b} -> {b, a} end
      iex> untuple(reverse, 2).(:a, :b)
      {:b, :a}
  """
  defmacro untuple(f, arity) do
    vars = n_vars(arity)

    quote do
      fn(unquote_splicing(vars)) ->
        apply(unquote(f), [{unquote_splicing(vars)}])
      end
    end
  end

  @doc """
  ## Examples

      iex> import Sky.Ext, only: [op: 1]
      iex> positive = op(_ > 0)
      iex> positive.(10)
      true

      iex> import Sky.Ext, only: [op: 1]
      iex> invert = op(1 / _)
      iex> invert.(2)
      0.5
  """
  defmacro op({operator, _meta, [{:_, _, _}, rhs]}) do
    quote bind_quoted: [operator: operator, rhs: rhs] do
      fn x ->
        apply(Kernel, operator, [x, rhs])
      end
    end
  end
  defmacro op({operator, _meta, [lhs, {:_, _, _}]}) do
    quote bind_quoted:  [operator: operator, lhs: lhs] do
      fn x ->
        apply(Kernel, operator, [lhs, x])
      end
    end
  end

  defp n_vars(n) do
    1..n |> Enum.map(&var_from_n/1)
  end

  defp var_from_n(n) do
    "var#{n}"
    |> String.to_atom
    |> Macro.var(nil)
  end
end

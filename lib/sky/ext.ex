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
  Given an elixir expression, return a curried function
  that applies every argument in place of underscores (`_`)
  placeholders, in the order in which they appear, from left
  to right.

  ## Examples

      iex> import Sky.Ext, only: [fill: 1]
      iex> fill([_, 1, _, 3]).(0).(2)
      [0, 1, 2, 3]

      iex> import Sky.Ext, only: [fill: 1]
      iex> fill({_, 1, _, 3}).(0).(2)
      {0, 1, 2, 3}

      iex> import Sky.Ext, only: [fill: 1]
      iex> fill(_ / _).(10).(2)
      5.0

      iex> import Sky.Ext, only: [fill: 1]
      iex> fill(1 / _).(2)
      0.5

      iex> import Sky.Ext, only: [fill: 1]
      iex> fill(_ > 0).(2)
      true

      iex> import Sky.Ext, only: [fill: 1]
      iex> fill(Enum.reduce([1, 2, 3], _, &Kernel.+/2)).(10)
      16
  """
  defmacro fill(list) when is_list(list) do
    {args, values} = placeholder_args(list)
    quote do
      Sky.curry(fn unquote_splicing(args) ->
        unquote(values)
      end)
    end
  end
  defmacro fill({call, meta, args}) do
    {args, values} = placeholder_args(args)
    quote do
      Sky.curry(fn unquote_splicing(args) ->
        unquote({call, meta, values})
      end)
    end
  end

  defp placeholder_args(exprs) do
    values =
      exprs
      |> Stream.with_index
      |> Enum.map(fn
        {_placeholder = {:_, _, _}, index} ->
          {:"var#{index}", [placeholder: true], nil}
        {other, _index} ->
          other
      end)

    args =
      values
      |> Enum.filter(fn
        {_, [placeholder: true], _} -> true
        _ -> false
      end)

    {args, values}
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

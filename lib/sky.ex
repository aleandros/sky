defmodule Sky do
  @moduledoc """
  Collection of higher-oder functions
  not present in the standard library.
  """

  @doc """
  Curries the given function, starting with an optional list of given params.

  ## Examples

  The order of the arguments is respected.

    iex> Sky.curry(fn(a, b) -> a - b end).(5).(4)
    1

  You can also pass it a list of predefined parameters.

    iex> Sky.curry(fn(a, b, c) -> a + b + c end, [1, 2]).(3)
    6
  """
  def curry(f, given \\ []) when is_function(f) do
    n = arity(f)

    if length(given) == n do
      apply(f, given)
    else
      fn x ->
        curry(f, Enum.reverse([x|given]))
      end
    end
  end

  @doc """
  Given a function *f* with arity *n*, return a function that receives a
  single tuple of *n* elements and applies them to the original *f*.

  ## Example

    iex> Sky.tupleize(fn(a, b) -> a + b end).({1, 2})
    3

  It might seem less useful for functions of one argument, but you might
  gain composability with other functions from the module.
  """
  def tupleize(f) when is_function(f) do
    n = arity(f)

    fn tuple when is_tuple(tuple) and tuple_size(tuple) == n ->
      apply(f, Tuple.to_list(tuple))
    end
  end

  @doc """
  Given a *single-argument* function *f*, return a new function that
  receives either a tuple in the form `{:ok, value}` which would execute
  `f.(value)`, or any other term, which would be returned without change.

  In case of success, the return value of the returned function is *always*
  in the form `{:ok, value}` even if the result of *f* was in the same form.
  This means that any nesting is eliminated.

  ## Example

    iex> inc = Sky.lift_ok(fn n -> n + 1 end)
    iex> inc.({:ok, 1})
    {:ok, 2}
    iex> inc.({:error, :bad_input})
    {:error, :bad_input}

  Note that the value is always a two-element tuple `{:ok, v}`.

    iex> inc = Sky.lift_ok(fn n -> n + 1 end)
    iex> inc.(inc.({:ok, 1}))
    {:ok, 3}

  """
  def lift_ok(f) when is_function(f) do
    fn
      {:ok, value} -> flatten(f.(value))
      error -> error
    end
  end

  defp flatten({:ok, value}), do: flatten(value)
  defp flatten(value), do: {:ok, value}

  @doc """
  Given a two argument functions, swap the order in wich the arguments
  are received.

  ## Examples

    iex> Sky.swap(&rem/2).(7, 5)
    5

    iex> Sky.swap(fn(a, b) -> a - b end).(2, 1)
    -1
  """
  def swap(f) when is_function(f) do
    fn(a, b) -> f.(b, a) end
  end

  @doc """
  Creates a function that receives an argument and always returns the
  original given value.

  ## Example

    iex> one = Sky.constant(1)
    iex> one.(2)
    1
    iex> one.(nil)
    1
  """
  def constant(value) do
    fn _ -> value end
  end

  @doc ~S"""
  Given a *one-argument* function that raises an exception, return a function
  that instead returns any of the following tuples:

  * {:ok, value} when no exception is raised
  * {:error, exception} when an exception is raised.

  ## Examples

    iex> safe_float_div = Sky.noraise(fn ({a, b}) -> a / b end)
    iex> safe_float_div.({1, 0})
    {:error, %ArithmeticError{message: "bad argument in arithmetic expression"}}
    iex> safe_float_div.({1, 2})
    {:ok, 0.5}
  """
  def noraise(f) when is_function(f) do
    fn x ->
      try do
        {:ok, f.(x)}
      rescue
        exception -> {:error, exception}
      end
    end
  end

  @doc """
  Given two one-argument functions, a subject *f* and a predicate *p*, return
  a function that takes an argument *x*.

  Such function returns `{:ok, f.(x)}` only if `p.(x)` is truthy, :error otherwise.

  ## Example

    iex> f = fn x -> x - 1 end
    iex> p = fn x -> x > 0 end
    iex> Sky.reject_if(f, p).(1)
    {:ok, 0}
    iex> Sky.reject_if(f, p).(0)
    :error
  """
  def reject_if(f, p) when is_function(f) and is_function(p) do
    fn x ->
      if p.(x), do: {:ok, f.(x)}, else: :error
    end
  end

  @doc """
  Given two one-argument functions, a subject *f* and a predicate *p*, return
  a function that takes an argument *x*.

  However, in contrast to `Sky.reject_if/2`, if the predicate is not satisfied,
  the parameter *x* is returned. Otherwise the return value is `f.(x)`.

  ## Example

    iex> trim = (&tl/1)
    iex> non_empty? = fn list -> length(list) > 0 end
    iex> safetrim = Sky.apply_if(trim, non_empty?)
    iex> safetrim.([1,2])
    [2]
    iex> safetrim.([])
    []
  """
  def apply_if(f, p) when is_function(f) and is_function(p) do
    fn x ->
      if p.(x), do: f.(x), else: x
    end
  end

  @doc """
  Given a predicate *p*, which receives a single argument and returns a
  boolean value, return a function which is equivalent to `not p.(x)`

  ## Example
    iex> negative? = fn x -> x < 0 end
    iex> no_negative? = Sky.negate(negative?)
    iex> no_negative?.(1)
    true

  """
  def negate(p) when is_function(p) do
    fn v -> not p.(v) end
  end

  @doc """
  Get the arity of the given function.

  ## Examples

    iex> Sky.arity(&Enum.map/2)
    2

    iex> Sky.arity(fn(_, _, _) -> nil end)
    3
  """
  def arity(f) when is_function(f) do
    :erlang.fun_info(f)[:arity]
  end

  @doc ~S"""
  Feed a value into an unary function.

  Can be used to *pipe* a value to Sky generated unary functions.

      iex> import Sky, only: [~>: 2]
      iex> "Hello"
      ...> ~> (&String.downcase/1)
      ...> ~> (&String.to_atom/1)
      :hello

  """
  def v ~> f, do: f.(v)

  @doc ~S"""
  Given two unary functions *f* and *g*, return their composition `f  ∘ g`.

      iex> x = Sky.compose(&String.to_atom/1, &String.downcase/1)
      iex> x.("HELLO")
      :hello

  """
  def compose(f, g) do
    fn x -> g.(x) |> f.() end
  end


  @doc ~S"""
  Partially applies a function.

  This is `curry`'s cousin. Both can be used to partially apply functions,
  however `partial` returns an unary function that expects a *list* with more arguments
  instead of just the next one. This can be useful for making a function of any arity
  into an unary function that expects a list.

      iex> x = Sky.partial(fn a, b, c -> a + b + c end)
      iex> x.([1, 2, 3])
      6

  An optional list of partial arguments can be provided:

      iex> x = Sky.partial(fn a, b, c -> a + b + c end, [1, 2])
      iex> x.([3])
      6
  """
  def partial(f, given \\ []) do
    partial(f, given, arity(f))
  end

  defp partial(f, args, arity) when length(args) != arity do
    fn more_args when is_list(more_args) ->
      partial(f, args ++ more_args, arity)
    end
  end

  defp partial(f, args, _arity) do
    apply(f, args)
  end

end

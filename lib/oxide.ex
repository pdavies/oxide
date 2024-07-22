defmodule Oxide do
  @moduledoc false
end

defmodule Oxide.Result do
  @moduledoc """
  Helpers for working with result tuples, `{:ok, value}` and `{:error, reason}`.

  Unless otherwise stated, functions raise `FunctionClauseError` when given an unexpected
  non-result.
  """

  @type t :: {:ok, any()} | {:error, any()}
  @type t(v) :: {:ok, v} | {:error, any()}
  @type t(v, e) :: {:ok, v} | {:error, e}

  @doc ~S"""
  Result pipe operator.

  The result pipe operator `&&&/2` is a result-aware analogue to the pipe operator `|>`.
  It allows chaining functions that return results, piping the inner value of `:ok` results
  and short-circuiting the pipeline if any of the functions return an error. For example

      with {:ok, x1} <- f1(x),
           {:ok, x2} <- f2(x1) do
        f3(x2)
      end

  can be written as

      x |> f1() &&& f2() &&& f3()

  More examples:

      iex> {:ok, :foo} &&& Atom.to_string()
      "foo"
      iex> {:ok, 3} &&& then(fn x -> {:ok, x + 1} end) &&& List.wrap()
      [4]
      iex> {:ok, :foo} &&& Atom.to_string() |> String.capitalize()
      "Foo"
      iex> {:error, :oops} &&& Atom.to_string() |> String.capitalize()
      {:error, :oops}

  """
  defmacro left &&& right do
    quote do
      case unquote(left) do
        {:ok, t} -> t |> unquote(right)
        {:error, e} -> {:error, e}
      end
    end
  end

  @doc """
  Returns true if the given value is a result tuple.

      iex> Result.result?({:ok, 42})
      true
      iex> Result.result?({:error, :not_found})
      true
      iex> Result.result?(42)
      false
      iex> Result.result?({:ok, 42, 43})
      false
      iex> Result.result?(:ok)
      false

  """
  @spec result?(any()) :: boolean()
  def result?(maybe_result)
  def result?({:ok, _}), do: true
  def result?({:error, _}), do: true
  def result?(_), do: false

  @doc """
  Assert a result.

  Returns the value unchanged if it is a result; raises `RuntimeError` otherwise.

      iex> Result.assert_result!({:ok, 42})
      {:ok, 42}
      iex> Result.assert_result!({:error, :not_found})
      {:error, :not_found}
      iex> Result.assert_result!(42)
      ** (RuntimeError) Not a result

      iex> Result.assert_result!({:ok, 42, 43})
      ** (RuntimeError) Not a result

      iex> Result.assert_result!(:ok)
      ** (RuntimeError) Not a result

  """
  @spec assert_result!(any()) :: t() | no_return()
  def assert_result!(maybe_result)
  def assert_result!({:ok, value}), do: {:ok, value}
  def assert_result!({:error, reason}), do: {:error, reason}
  def assert_result!(_), do: raise("Not a result")

  @doc ~S"""
  Return whether a result is ok.

      iex> Result.is_ok?({:ok, 3})
      true
      iex> Result.is_ok?({:error, 3})
      false

  """
  @spec is_ok?(t()) :: boolean
  def is_ok?(result)
  def is_ok?({:ok, _}), do: true
  def is_ok?({:error, _}), do: false

  @doc ~S"""
  Wrap a value in an ok result.

      iex> 3 |> Result.ok()
      {:ok, 3}
      iex> Result.ok({:ok, 3})
      {:ok, {:ok, 3}}

  """
  @spec ok(v) :: {:ok, v} when v: var
  def ok(t), do: {:ok, t}

  @doc ~S"""
  Return whether a result is an error.

      iex> Result.is_error?({:ok, 3})
      false
      iex> Result.is_error?({:error, 3})
      true

  """
  @spec is_error?(t()) :: boolean
  def is_error?(result)
  def is_error?({:ok, _}), do: false
  def is_error?({:error, _}), do: true

  @doc ~S"""
  Wrap a value in an error result.

      iex> :some_error_reason |> Result.error()
      {:error, :some_error_reason}

  """
  @spec error(e) :: {:error, e} when e: var
  def error(e), do: {:error, e}

  @doc ~S"""
  Unwrap an `:ok` result, and raise an `:error` reason.

  If an error reason is an exception, it is raised as-is; otherwise, a `RuntimeError`
  is raised with the inspected error reason in the exception message.

      iex> Result.unwrap!({:ok, :value})
      :value
      iex> Result.unwrap!({:error, %{code: 500}})
      ** (RuntimeError) Unwrapped an error: %{code: 500}

      iex> Result.unwrap!({:error, ArgumentError.exception("oh no")})
      ** (ArgumentError) oh no

  """
  @spec unwrap!(t(v)) :: v when v: var
  def unwrap!(result)
  def unwrap!({:ok, t}), do: t
  def unwrap!({:error, e}) when is_exception(e), do: raise(e)
  def unwrap!({:error, e}), do: raise("Unwrapped an error: #{inspect(e)}")

  @doc ~S"""
  Unwrap an `:ok` result, falling back to `default` for an `:error` result.

      iex> Result.unwrap_or({:ok, :cake}, :icecream)
      :cake
      iex> Result.unwrap_or({:error, :peas}, :icecream)
      :icecream

  """
  @spec unwrap_or(t(v), w) :: v | w when v: var, w: var
  def unwrap_or(result, default)
  def unwrap_or({:ok, t}, _default), do: t
  def unwrap_or({:error, _}, default), do: default

  @doc ~S"""
  Unwrap an `:ok` result, falling back to executing a zero-arity function if the result
  is an error.

      iex> Result.unwrap_or_else({:ok, :cake}, fn -> :icecream end)
      :cake
      iex> Result.unwrap_or_else({:error, :peas}, fn -> :icecream end)
      :icecream

  """
  @spec unwrap_or_else(t(v), (-> w)) :: v | w when v: var, w: var
  def unwrap_or_else(result, f)
  def unwrap_or_else({:ok, t}, _f), do: t
  def unwrap_or_else({:error, _}, f), do: f.()

  @spec unwrap_err!(t(any, e)) :: e when e: var
  def unwrap_err!(result)
  def unwrap_err!({:ok, _}), do: raise("called `Result.unwrap_err()` on an `:ok` value")
  def unwrap_err!({:error, e}), do: e

  # def expect_err

  @doc ~S"""
  Return a result leaving errors unchanged but transforming the value of an `:ok` result.

      iex> Result.map({:ok, 3}, fn x -> x + 1 end)
      {:ok, 4}
      iex> Result.map({:error, :nan}, fn x -> x + 1 end)
      {:error, :nan}

  """
  @spec map(t(v, e), (v -> w)) :: t(w, e) when v: var, w: var, e: var
  def map(result, f)
  def map({:ok, t}, f), do: {:ok, f.(t)}
  def map({:error, e}, _f), do: {:error, e}

  @doc ~S"""
  Return a result leaving ok values unchanged but transforming an error reason with `f`.

      iex> Result.map_err({:ok, 3}, fn x -> x + 1 end)
      {:ok, 3}
      iex> Result.map_err({:error, :nan}, &:erlang.atom_to_binary/1)
      {:error, "nan"}

  """
  @spec map_err(t(v, e), (e -> f)) :: t(v, f) when v: var, e: var, f: var
  def map_err(result, f)
  def map_err({:ok, t}, _f), do: {:ok, t}
  def map_err({:error, e}, f), do: {:error, f.(e)}

  @doc ~S"""
  Return an _unwrapped_ ok value transformed by f, or `default` if `result` is an error.

      iex> Result.map_or({:ok, 3}, 0, fn x -> x + 1 end)
      4
      iex> Result.map_or({:error, :nan}, 0, fn x -> x + 1 end)
      0

  """
  @spec map_or(t(v, any()), w, (v -> x)) :: x | w when v: var, w: var, x: var
  def map_or(result, default, f)
  def map_or({:ok, t}, _default, f), do: f.(t)
  def map_or({:error, _}, default, _f), do: default

  @spec and_then(t(v, e), (v -> w)) :: w | {:error, e} when v: var, w: var, e: var
  def and_then(result, f)
  def and_then({:ok, t}, f), do: f.(t)
  def and_then({:error, e}, _f), do: {:error, e}

  @doc ~S"""
  Return an ok result unchanged, or transform an unwrapped error reason with `f`.

      iex> Result.or_else({:ok, :xylophone}, fn err -> err + 1 end)
      {:ok, :xylophone}
      iex> Result.or_else({:error, 3}, fn err -> err + 1 end)
      4

  """
  @spec or_else(t(v, e), (e -> f)) :: {:ok, v} | f when v: var, e: var, f: var
  def or_else(result, f)
  def or_else({:ok, t}, _f), do: {:ok, t}
  def or_else({:error, e}, f), do: f.(e)

  @doc ~S"""
  Convert a maybe-nil value to a result.

  Maps `nil` and `{:ok, nil}` to `{:error, reason}`, passes errors through and otherwise maps `value`, or {:ok, value}` to `{:ok, value}`.

      iex> %{"key" => "value"} |> Map.get("key") |> Result.err_if_nil(:notfound)
      {:ok, "value"}
      iex> %{"key" => "value"} |> Map.get("missing") |> Result.err_if_nil(:notfound)
      {:error, :notfound}
      iex> {:ok, nil} |> Result.err_if_nil(:notfound)
      {:error, :notfound}
      iex> {:ok, "value"} |> Result.err_if_nil(:notfound)
      {:ok, "value"}
      iex> {:error, :badthing} |> Result.err_if_nil(:notfound)
      {:error, :badthing}

  """
  @spec err_if_nil(v | nil, e) :: t(v, e) when v: var, e: var
  def err_if_nil(value, reason)
  def err_if_nil(value, reason) when is_nil(value), do: {:error, reason}
  def err_if_nil({:ok, value}, reason) when is_nil(value), do: {:error, reason}
  def err_if_nil({:ok, value}, _reason) when not is_nil(value), do: {:ok, value}
  def err_if_nil({:error, reason}, _reason), do: {:error, reason}
  def err_if_nil(value, _reason) when not is_nil(value), do: {:ok, value}

  @doc ~S"""
  Equivalent to `Kernel.tap/2` for ok results.

  Calls `f` with the value of an `:ok` result, and returns the result unchanged.

      iex> {:ok, 3} |> Result.tap_ok(&IO.inspect/1)
      3
      {:ok, 3}
      iex> {:error, :oops} |> Result.tap_ok(&IO.inspect/1)
      {:error, :oops}

  """
  @spec tap_ok(t(v), (v -> any())) :: t(v) when v: var
  def tap_ok(result, f)

  def tap_ok({:ok, t}, f) do
    f.(t)
    {:ok, t}
  end

  def tap_ok({:error, e}, _f), do: {:error, e}

  @doc ~S"""
  Equivalent to `Kernel.tap/2` for error results.

  Calls `f` with the reason of an `:error` result, and returns the result unchanged.

      iex> {:ok, 3} |> Result.tap_err(&IO.inspect/1)
      {:ok, 3}
      iex> {:error, :oops} |> Result.tap_err(&IO.inspect/1)
      :oops
      {:error, :oops}

  """
  @spec tap_err(t(v, e), (e -> any())) :: t(v, e) when v: var, e: var
  def tap_err(result, f)
  def tap_err({:ok, t}, _f), do: {:ok, t}

  def tap_err({:error, e}, f) do
    f.(e)
    {:error, e}
  end

  @doc ~S"""
  Collects a list of results into a single result.

  If any of the results is an error, the first error is returned. Otherwise, a single
  ok result is returned with a list of the result values.

      iex> [{:ok, 1}, {:ok, 2}, {:ok, 3}] |> Result.collect()
      {:ok, [1, 2, 3]}
      iex> [{:ok, 1}, {:error, 2}, {:ok, 3}, {:error, 4}] |> Result.collect()
      {:error, 2}

  """
  @spec collect([t()]) :: t()
  def collect(results) do
    Enum.find(results, false, fn r -> is_error?(r) end) ||
      results |> Enum.map(&unwrap!/1) |> ok()
  end
end

defmodule Oxide.Result.Dangerous do
  @moduledoc """
  Result helpers you should use with extreme care, or better yet, not at all.
  """

  @doc ~S"""
  Dangerous result pipe operator.

  The result pipe operator `~>/2` is defined identically to `Oxide.Result.&&&/2`, and in
  many circumstances behaves the same:

      iex> {:ok, :foo} ~> Atom.to_string()
      "foo"
      iex> {:ok, 3} ~> then(fn x -> {:ok, x + 1} end) ~> List.wrap()
      [4]
      iex> {:ok, :foo} ~> Atom.to_string() |> String.capitalize()
      "Foo"
      iex> {:error, :oops} ~> then(fn x -> {:ok, x + 1} end) ~> List.wrap()
      {:error, :oops}

  However, Elixir's operator precedence means that when `~>` is followed by `|>`,
  an early error can pipe into later stages of the pipeline in a way that is
  almost never what you want.

      iex> {:error, :oops} &&& Atom.to_string() |> String.capitalize()
      {:error, :oops}
      iex> {:error, :oops} ~> Atom.to_string() |> String.capitalize()  # String.capitalize({:error, :oops})
      ** (FunctionClauseError) no function clause matching in String.capitalize/2

  """
  defmacro left ~> right do
    quote do
      case unquote(left) do
        {:ok, t} -> t |> unquote(right)
        {:error, e} -> {:error, e}
      end
    end
  end
end

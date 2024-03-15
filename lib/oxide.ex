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

  """
  defmacro left &&& right do
    quote do
      case unquote(left) do
        {:ok, t} -> t |> unquote(right)
        {:error, e} -> {:error, e}
      end
    end
  end

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
  """
  @spec ok(any()) :: t()
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
  @spec error(any()) :: t()
  def error(e), do: {:error, e}

  @doc ~S"""
  Unwrap an `:ok` result, and raise an `:error` reason.

      iex> Result.unwrap!({:ok, :value})
      :value
      iex> Result.unwrap!({:error, "message"})
      ** (RuntimeError) message

  """
  @spec unwrap!(t()) :: any()
  def unwrap!(result)
  def unwrap!({:ok, t}), do: t
  def unwrap!({:error, e}), do: raise(e)

  @doc ~S"""
  Unwrap an `:ok` result, falling back to `default` for an `:error` result.

      iex> Result.unwrap_or({:ok, :cake}, :icecream)
      :cake
      iex> Result.unwrap_or({:error, :peas}, :icecream)
      :icecream

  """
  @spec unwrap_or(t(), any()) :: any()
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
  @spec unwrap_or_else(t(), (-> any())) :: any()
  def unwrap_or_else(result, f)
  def unwrap_or_else({:ok, t}, _f), do: t
  def unwrap_or_else({:error, _}, f), do: f.()

  @spec unwrap_err!(t()) :: any()
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
  @spec map(t(), (any() -> any())) :: t()
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
  @spec map_err(t(), (any() -> any())) :: t()
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
  @spec map_or(t(), any(), (any() -> any())) :: any()
  def map_or(result, default, f)
  def map_or({:ok, t}, _default, f), do: f.(t)
  def map_or({:error, _}, default, _f), do: default

  @spec and_then(t(), (any() -> any())) :: any()
  def and_then(result, f)
  def and_then({:ok, t}, f), do: f.(t)
  def and_then({:error, e}, _f), do: {:error, e}

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
  @spec err_if_nil(any(), any()) :: t()
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
  @spec tap_ok(t(), (any() -> any())) :: t()
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
  @spec tap_err(t(), (any() -> any())) :: t()
  def tap_err(result, f)
  def tap_err({:ok, t}, _f), do: {:ok, t}

  def tap_err({:error, e}, f) do
    f.(e)
    {:error, e}
  end
end

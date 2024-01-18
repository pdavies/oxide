defmodule Oxide do
  @moduledoc false
end

defmodule Oxide.Result do
  @moduledoc """
  Helpers for working with result tuples, `{:ok, value}` and `{:error, reason}`.

  Unless otherwise stated, functions raise `FunctionClauseError` when given an unexpected
  non-result.
  """

  @doc ~S"""
  ## Examples

      iex> Result.is_ok?({:ok, 3})
      true
      iex> Result.is_ok?({:error, 3})
      false
      iex> Result.is_ok?(3)
      ** (FunctionClauseError) no function clause matching in Oxide.Result.is_ok?/1

  """
  def is_ok?(result)
  def is_ok?({:ok, _}), do: true
  def is_ok?({:error, _}), do: false

  @doc ~S"""
  Wrap a value in an ok result.
  """
  def ok(t), do: {:ok, t}

  @doc ~S"""
  ## Examples

      iex> Result.is_error?({:ok, 3})
      false
      iex> Result.is_error?({:error, 3})
      true
      iex> Result.is_error?(3)
      ** (FunctionClauseError) no function clause matching in Oxide.Result.is_error?/1

  """
  def is_error?(result)
  def is_error?({:ok, _}), do: false
  def is_error?({:error, _}), do: true

  @doc ~S"""
  Wrap a value in an error result.
  """
  def error(e), do: {:error, e}

  def unwrap!(result)
  def unwrap!({:ok, t}), do: t
  def unwrap!({:error, e}), do: raise(e)

  def unwrap_or(result, default)
  def unwrap_or({:ok, t}, _default), do: t
  def unwrap_or({:error, _}, default), do: default

  def unwrap_or_else(result, f)
  def unwrap_or_else({:ok, t}, _f), do: t
  def unwrap_or_else({:error, _}, f), do: f.()

  def unwrap_err!(result)
  def unwrap_err!({:ok, _}), do: raise("called `Result.unwrap_err()` on an `:ok` value")
  def unwrap_err!({:error, e}), do: e

  # def expect_err

  def map(result, f)
  def map({:ok, t}, f), do: {:ok, f.(t)}
  def map({:error, e}, _f), do: {:error, e}

  def map_or(result, default, f)
  def map_or({:ok, t}, _default, f), do: f.(t)
  def map_or({:error, _}, default, _f), do: default

  def map_err(result, f)
  def map_err({:ok, t}, _f), do: {:ok, t}
  def map_err({:error, e}, f), do: {:error, f.(e)}

  def and_then(result, f)
  def and_then({:ok, t}, f), do: f.(t)
  def and_then({:error, e}, _f), do: {:error, e}

  @doc ~S"""
  Result pipe operator.

  The result pipe operator `~>` is a result-aware analogue to the pipe operator `|>`.
  It allows chaining functions that return results, piping the inner value of `:ok` results
  and short-circuiting the pipeline if any of the functions return an error. For example

      with {:ok, x1} <- f1(x),
           {:ok, x2} <- f2(x1) do
        f3(x2)
      end

  can be written as

      x |> f1() ~> f2() ~> f3()

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

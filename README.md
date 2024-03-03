# Oxide

Oxide is a library of helpers for working ergonomically with result tuples `{:ok, value}` and
`{:error, reason}`. Most of its functions are direct equivalents to those in the Rust standard library,
and it also introduces  `~>` - a result-aware variant of the pipe operator
`|>` - as an Elixir analogue to Rust's unary `?` operator.

> #### Warning {: .warning}
>
> Oxide expects results to be `{:ok, any()} | {:error, any()}`. In particular, `:ok`, `{:ok}` and
> `{:ok, :foo, :bar}` are not results - instead use `{:ok, nil}`, `{:ok, nil}` and `{:ok, {:foo, :bar}}`
> respectively. This is an intentional choice to encourage code to adopt a consistent approach
> to typing with as little ambiguity or surprising behaviour as possible.

## Examples

### Pipelines of results

```elixir
# Before
with {:ok, x1} <- f1(x),
    {:ok, x2} <- f2(x1) do
  f3(x2)
end

# After
x |> f1() ~> f2() ~> f3()
```

### Acting on :ok values

```elixir
# Act on the success value or leave errors unchanged.
# Maps {:ok, n} -> {:ok, n + 1} and leaves {:error, reason} alone
returns_result() |> Result.map(fn val -> val + 1 end)
```

## Doesn't `~>` duplicate `with`?

The developer ergonomics of `with` are a two-phase construct with a context initalization phase
(`with <...>`) followed by an inner execution phase (`do <...> end`). It's extremely natural
when there are a collection of independent preparatory steps followed by a distinct action or set of actions, as in this [great example](https://hexdocs.pm/elixir/1.16.1/Kernel.SpecialForms.html#with/1)
from the Elixir docs:

```elixir
def area(opts) do
  with {:ok, width} <- Map.fetch(opts, :width),
       {:ok, height} <- Map.fetch(opts, :height) do
    {:ok, width * height}
  end
end
```

However, [this other example](https://hexdocs.pm/elixir/1.16.1/docs-tests-and-with.html#with:~:text=Thankfully%2C%20Elixir%20v1.2%20introduced%20the%20with%20construct%2C) is less elegant:

```elixir
with {:ok, data} <- read_line(socket),
     {:ok, command} <- KVServer.Command.parse(data) do
  KVServer.Command.run(command)
end
```

Notice that above, we have a linear chain of steps which are "almost" the following pipeline:

```elixir
read_line(socket)
|> KVServer.Command.parse()
|> KVServer.Command.run()
```

We can't do that because we need to unwrap the results before passing them along the pipeline, and we want to bail early on error results.

In comparison with the pipeline, the `with` syntax is somewhat unnatural:

* the `run` call lives in a different context to the preceding two
* we have to start reading from right to left to follow the control flow
* we must explicitly pass around arguments that would be elided in a pipeline
* we've added a layer of nesting to our code

The point of `~>` is to recover the natural pipeline expression:

```elixir
read_line(socket)
~> KVServer.Command.parse()
~> KVServer.Command.run()
```

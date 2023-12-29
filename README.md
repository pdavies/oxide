# Oxide

Oxide is a library of utilities for working with result tuples `{:ok, value}` and
`{:error, reason}`, based on those available in the Rust standard library.

Its most useful contribution is `~>`, a result-aware variant of the Elixir pipe operator
`|>` inspired by Rust's `?` operator.

It is usually an antipattern to approach a new language by stubbornly bringing
along old ways of doing things from other languages, instead of
adapting to the conventions of the new language. Nevertheless, that is more or less what
I have done here as it seems justified: result tuples are a ubiquitous Elixir convention,
but since they are not first-class citizens of the language, little assistance is
provided in using them safely and ergonomically.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `oxide` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:oxide, "~> 0.1.0"}
  ]
end
```

Docs can be found at [https://hexdocs.pm/oxide](https://hexdocs.pm/oxide).


## The problem with `with`

Why is `~>` not redundant given the existence of `with`? I'll write some notes on that
if I can get around to it.

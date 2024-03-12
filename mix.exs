defmodule Oxide.MixProject do
  use Mix.Project

  @version "0.3.0"
  @source_url "https://github.com/pdavies/oxide"

  def project do
    [
      app: :oxide,
      description: "Helpers for working with result tuples, inspired by Rust.",
      version: @version,
      source_url: @source_url,
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.30.9", only: :dev, runtime: false}
      # {:earmark, "~> 1.4", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      maintainers: ["Philip Davies"],
      links: %{
        "GitHub" => @source_url
      }
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme",
      source_ref: @version
    ]
  end
end

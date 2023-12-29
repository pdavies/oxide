defmodule Oxide.MixProject do
  use Mix.Project

  def project do
    [
      app: :oxide,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
end

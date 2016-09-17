defmodule Flow.Mixfile do
  use Mix.Project

  def project do
    [app: :flow,
     version: "0.0.1",
     elixir: "~> 1.3-dev",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:logger, :tirexs]]
  end

  defp deps do
    [
      {:tirexs, "~> 0.8"},
      {:httpoison, "~> 0.8"},
      {:poison, "~> 2.1"},
      {:socket, [github: "meh/elixir-socket"]}
    ]
  end
end

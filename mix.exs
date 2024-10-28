defmodule Envctl.MixProject do
  use Mix.Project

  def project do
    [
      app: :envctl,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: Envctl.CLI]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
        {:jason, "~> 1.3"}
    ]
  end
end

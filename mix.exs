defmodule Sky.Mixfile do
  use Mix.Project

  def project do
    [app: :sky,
     version: "0.2.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     package: package,
     description: description,
     deps: deps()]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:ex_doc, "~> 0.14", only: :dev}]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Edgar Cabrera"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/aleandros/sky",
               "Docs" => "http://hexdocs.pm/sky/"}
    ]
  end

  defp description do
    """
    Set of functions for manipulating other functions in elixir.
    """
  end
end

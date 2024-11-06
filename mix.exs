defmodule AbsintheErrorMessage.MixProject do
  use Mix.Project

  def project do
    [
      app: :absinthe_error_message,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Standardize absinthe error message handling in your application",
      docs: docs(),
      package: package(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        dialyzer: :test,
        coveralls: :test,
        "coveralls.lcov": :test,
        "coveralls.json": :test,
        "coveralls.html": :test,
        "coveralls.detail": :test,
        "coveralls.post": :test
      ],
      dialyzer: [
        plt_add_apps: [:ex_unit, :mix],
        list_unused_filters: true,
        plt_local_path: "dialyzer",
        plt_core_path: "dialyzer",
        flags: [:unmatched_returns]
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [extra_applications: [:logger]]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.1", runtime: false},
      {:excoveralls, "~> 0.14.0", runtime: false},
      {:dialyxir, "~> 1.0", runtime: false},
      {:credo, "~> 1.0", runtime: false},
      {:absinthe, "~> 1.0"},

      {:error_message_shorts, path: "../error_message_shorts"},
      {:ecto, "~> 3.0", optional: true},
      {:error_message, "~> 0.3.2", optional: true}
      # {:error_message_shorts, git: "https://github.com/cylkdev/error_message_shorts.git", branch: "main"},
    ]
  end

  defp package do
    [
      maintainers: ["Kurt Hogarth"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/cylkdev/absinthe_error_message"},
      files: ~w(mix.exs README.md CHANGELOG.md lib)
    ]
  end

  defp docs do
    [
      main: "AbsintheErrorMessage",
      source_url: "https://github.com/cylkdev/absinthe_error_message"
    ]
  end
end

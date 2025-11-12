defmodule PostgrexPubsubMultiTenant.MixProject do
  use Mix.Project

  def project do
    [
      app: :postgrex_pubsub_multi_tenant,
      name: "Postgrex PubSub Multitenant",
      description: "A helper for creating and listening to pubsub events from postgres",
      version: "0.2.8",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url:   "https://github.com/augustwenty/postgrex_pubsub_multi_tenant",
      homepage_url: "https://github.com/augustwenty/postgrex_pubsub_multi_tenant",

      package: [
        maintainers: ["DJ Daugherty"],
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/augustwenty/postgrex_pubsub_multi_tenant"}
      ],
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:jason, "~> 1.2"},
      {:postgrex, "~> 0.21"},
      {:ecto_sql, "~> 3.1"}
    ]
  end
end

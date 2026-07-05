defmodule CapTable.Factory do
  @moduledoc """
  Factory functions for generating test data.
  """

  alias CapTable.{Stakeholder, StockClass, SecurityIssuance, Transaction, Repo}

  def insert(factory_name, attrs \\ %{}) do
    factory_name
    |> build(attrs)
    |> Repo.insert!()
  end

  def build(:stakeholder, attrs) do
    %Stakeholder{
      name: Map.get(attrs, :name, "Test Stakeholder"),
      stakeholder_type: Map.get(attrs, :stakeholder_type, "individual"),
      email: Map.get(attrs, :email, "test@example.com"),
      tax_id: Map.get(attrs, :tax_id, "123-45-6789")
    }
  end

  def build(:stock_class, attrs) do
    %StockClass{
      class_type: Map.get(attrs, :class_type, "common"),
      name: Map.get(attrs, :name, "Common Stock"),
      shares_authorized: Map.get(attrs, :shares_authorized, 10_000_000),
      par_value: Map.get(attrs, :par_value, Decimal.new("0.01")),
      price_per_share: Map.get(attrs, :price_per_share, Decimal.new("1.00"))
    }
  end

  def build(:security, attrs) do
    stakeholder =
      Map.get_lazy(attrs, :stakeholder, fn ->
        insert(:stakeholder)
      end)

    stock_class =
      Map.get_lazy(attrs, :stock_class, fn ->
        insert(:stock_class)
      end)

    %SecurityIssuance{
      stakeholder_id: stakeholder.id,
      stock_class_id: stock_class.id,
      shares: Map.get(attrs, :shares, 1_000_000),
      issue_date: Map.get(attrs, :issue_date, Date.utc_today()),
      price_per_share: Map.get(attrs, :price_per_share, Decimal.new("1.00")),
      certificate_id:
        Map.get(attrs, :certificate_id, "CERT-#{System.unique_integer([:positive])}")
    }
  end

  def build(:transaction, attrs) do
    stakeholder =
      Map.get_lazy(attrs, :stakeholder, fn ->
        insert(:stakeholder)
      end)

    security =
      Map.get_lazy(attrs, :security, fn ->
        insert(:security, stakeholder: stakeholder)
      end)

    %Transaction{
      stakeholder_id: stakeholder.id,
      security_id: security.id,
      transaction_type: Map.get(attrs, :transaction_type, "issuance"),
      transaction_date: Map.get(attrs, :transaction_date, Date.utc_today()),
      quantity: Map.get(attrs, :quantity, 1_000_000),
      price_per_share: Map.get(attrs, :price_per_share, Decimal.new("1.00")),
      notes: Map.get(attrs, :notes)
    }
  end
end

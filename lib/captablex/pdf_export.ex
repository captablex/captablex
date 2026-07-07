defmodule Captablex.PdfExport do
  @moduledoc """
  The PdfExport context handles PDF generation for cap table and waterfall reports.
  """

  alias Captablex.{CapTable, Waterfall}

  @doc """
  Generates a PDF export of the current cap table.

  Returns `{:ok, pdf_path}` on success or `{:error, reason}` on failure.
  """
  def generate_cap_table_pdf do
    # Load cap table data
    ownership = CapTable.ownership_breakdown()
    transactions = CapTable.recent_transactions(limit: 20)
    stats = CapTable.stats()

    # Generate HTML for PDF
    html = cap_table_html(ownership, transactions, stats)

    # Generate PDF
    case PdfGenerator.generate(html, page_size: "A4") do
      {:ok, pdf_path} ->
        {:ok, pdf_path}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Generates a PDF export of a waterfall analysis.

  Returns `{:ok, pdf_path}` on success or `{:error, reason}` on failure.
  """
  def generate_waterfall_pdf(exit_value) when is_number(exit_value) do
    # Calculate waterfall
    result = Waterfall.calculate_waterfall(exit_value)

    # Generate HTML for PDF
    html = waterfall_html(result)

    # Generate PDF
    case PdfGenerator.generate(html, page_size: "A4") do
      {:ok, pdf_path} ->
        {:ok, pdf_path}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Private functions for HTML generation

  defp cap_table_html(ownership, transactions, stats) do
    """
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="UTF-8">
        <title>Cap Table Report</title>
        <style>
          #{pdf_styles()}
        </style>
      </head>
      <body>
        <div class="header">
          <h1>Cap Table Report</h1>
          <p class="date">Generated on #{Calendar.strftime(DateTime.utc_now(), "%B %d, %Y at %I:%M %p UTC")}</p>
        </div>

        <div class="section">
          <h2>Company Overview</h2>
          <div class="stats-grid">
            <div class="stat-card">
              <div class="stat-label">Total Stakeholders</div>
              <div class="stat-value">#{stats.total_stakeholders}</div>
            </div>
            <div class="stat-card">
              <div class="stat-label">Stock Classes</div>
              <div class="stat-value">#{stats.total_stock_classes}</div>
            </div>
            <div class="stat-card">
              <div class="stat-label">Total Shares</div>
              <div class="stat-value">#{Number.Delimit.number_to_delimited(stats.total_shares)}</div>
            </div>
            <div class="stat-card">
              <div class="stat-label">Transactions</div>
              <div class="stat-value">#{stats.total_transactions}</div>
            </div>
          </div>
        </div>

        <div class="section">
          <h2>Ownership Breakdown</h2>
          <table>
            <thead>
              <tr>
                <th>Stakeholder</th>
                <th>Shares</th>
                <th>Percentage</th>
              </tr>
            </thead>
            <tbody>
              #{ownership_rows(ownership)}
            </tbody>
          </table>
        </div>

        <div class="section">
          <h2>Recent Transactions</h2>
          <table>
            <thead>
              <tr>
                <th>Date</th>
                <th>Stakeholder</th>
                <th>Type</th>
                <th>Shares</th>
                <th>Price/Share</th>
              </tr>
            </thead>
            <tbody>
              #{transaction_rows(transactions)}
            </tbody>
          </table>
        </div>

        <div class="footer">
          <p>Confidential - Cap Table Report</p>
        </div>
      </body>
    </html>
    """
  end

  defp waterfall_html(result) do
    """
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="UTF-8">
        <title>Waterfall Analysis Report</title>
        <style>
          #{pdf_styles()}
        </style>
      </head>
      <body>
        <div class="header">
          <h1>Liquidation Waterfall Analysis</h1>
          <p class="date">Generated on #{Calendar.strftime(DateTime.utc_now(), "%B %d, %Y at %I:%M %p UTC")}</p>
        </div>

        <div class="section">
          <h2>Exit Scenario Summary</h2>
          <div class="stats-grid">
            <div class="stat-card">
              <div class="stat-label">Total Exit Value</div>
              <div class="stat-value">#{format_currency(result.total_exit_value)}</div>
            </div>
            <div class="stat-card">
              <div class="stat-label">Total Distributed</div>
              <div class="stat-value">#{format_currency(result.total_distributed)}</div>
            </div>
            <div class="stat-card">
              <div class="stat-label">Remaining Proceeds</div>
              <div class="stat-value">#{format_currency(result.remaining_proceeds)}</div>
            </div>
          </div>
        </div>

        <div class="section">
          <h2>Distribution by Stakeholder</h2>
          <table>
            <thead>
              <tr>
                <th>Stakeholder</th>
                <th>Total Amount</th>
                <th>% of Exit</th>
              </tr>
            </thead>
            <tbody>
              #{distribution_rows(result.distributions, result.total_exit_value)}
            </tbody>
          </table>
        </div>

        <div class="section">
          <h2>Detailed Breakdown</h2>
          #{detailed_breakdown_html(result.distributions)}
        </div>

        <div class="section">
          <h2>Waterfall Steps</h2>
          #{waterfall_steps_html(result.waterfall_steps)}
        </div>

        <div class="footer">
          <p>Confidential - Waterfall Analysis Report</p>
        </div>
      </body>
    </html>
    """
  end

  defp pdf_styles do
    """
    body {
      font-family: 'Helvetica', 'Arial', sans-serif;
      margin: 40px;
      color: #1e293b;
    }
    .header {
      text-align: center;
      margin-bottom: 40px;
      border-bottom: 2px solid #0ea5e9;
      padding-bottom: 20px;
    }
    .header h1 {
      margin: 0;
      font-size: 28px;
      color: #0ea5e9;
    }
    .date {
      color: #64748b;
      font-size: 12px;
      margin-top: 10px;
    }
    .section {
      margin-bottom: 40px;
    }
    .section h2 {
      font-size: 18px;
      color: #0f172a;
      margin-bottom: 15px;
      border-bottom: 1px solid #e2e8f0;
      padding-bottom: 8px;
    }
    .stats-grid {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 15px;
      margin-bottom: 20px;
    }
    .stat-card {
      background: #f8fafc;
      border: 1px solid #e2e8f0;
      border-radius: 8px;
      padding: 15px;
      text-align: center;
    }
    .stat-label {
      font-size: 11px;
      color: #64748b;
      text-transform: uppercase;
      margin-bottom: 8px;
    }
    .stat-value {
      font-size: 20px;
      font-weight: bold;
      color: #0f172a;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      font-size: 12px;
    }
    thead tr {
      background: #f1f5f9;
      border-bottom: 2px solid #cbd5e1;
    }
    th {
      text-align: left;
      padding: 12px;
      font-weight: 600;
      color: #475569;
      text-transform: uppercase;
      font-size: 10px;
    }
    td {
      padding: 10px 12px;
      border-bottom: 1px solid #e2e8f0;
    }
    tbody tr:hover {
      background: #f8fafc;
    }
    .breakdown-item {
      margin-bottom: 20px;
      padding: 15px;
      background: #f8fafc;
      border-left: 4px solid #0ea5e9;
      border-radius: 4px;
    }
    .breakdown-item h3 {
      margin: 0 0 10px 0;
      font-size: 14px;
      color: #0f172a;
    }
    .breakdown-detail {
      display: flex;
      justify-content: space-between;
      padding: 8px 0;
      border-bottom: 1px solid #e2e8f0;
      font-size: 11px;
    }
    .breakdown-detail:last-child {
      border-bottom: none;
      font-weight: bold;
      padding-top: 12px;
      margin-top: 8px;
      border-top: 2px solid #cbd5e1;
    }
    .step-item {
      margin-bottom: 15px;
      padding: 12px;
      background: #fefce8;
      border: 1px solid #fde047;
      border-radius: 4px;
      font-size: 11px;
    }
    .step-header {
      font-weight: bold;
      margin-bottom: 8px;
      color: #854d0e;
    }
    .footer {
      margin-top: 60px;
      text-align: center;
      font-size: 10px;
      color: #94a3b8;
      border-top: 1px solid #e2e8f0;
      padding-top: 20px;
    }
    """
  end

  defp ownership_rows(ownership) do
    ownership
    |> Enum.map(fn owner ->
      """
      <tr>
        <td>#{owner.name}</td>
        <td>#{Number.Delimit.number_to_delimited(owner.shares)}</td>
        <td>#{Float.round(owner.percentage, 2)}%</td>
      </tr>
      """
    end)
    |> Enum.join("\n")
  end

  defp transaction_rows(transactions) do
    transactions
    |> Enum.map(fn tx ->
      """
      <tr>
        <td>#{Calendar.strftime(tx.transaction_date, "%Y-%m-%d")}</td>
        <td>#{tx.stakeholder_name}</td>
        <td>#{String.capitalize(tx.transaction_type)}</td>
        <td>#{Number.Delimit.number_to_delimited(tx.quantity)}</td>
        <td>$#{tx.price_per_share}</td>
      </tr>
      """
    end)
    |> Enum.join("\n")
  end

  defp distribution_rows(distributions, total_exit_value) do
    distributions
    |> Enum.map(fn dist ->
      percentage =
        if total_exit_value > 0, do: dist.total_amount / total_exit_value * 100, else: 0

      """
      <tr>
        <td>#{dist.stakeholder_name}</td>
        <td>#{format_currency(dist.total_amount)}</td>
        <td>#{:erlang.float_to_binary(percentage, decimals: 2)}%</td>
      </tr>
      """
    end)
    |> Enum.join("\n")
  end

  defp detailed_breakdown_html(distributions) do
    distributions
    |> Enum.map(fn dist ->
      """
      <div class="breakdown-item">
        <h3>#{dist.stakeholder_name}</h3>
        #{breakdown_details(dist.breakdown)}
        <div class="breakdown-detail">
          <span>Total</span>
          <span>#{format_currency(dist.total_amount)}</span>
        </div>
      </div>
      """
    end)
    |> Enum.join("\n")
  end

  defp breakdown_details(breakdown) do
    breakdown
    |> Enum.map(fn item ->
      type_label = distribution_type_label(item.type)

      """
      <div class="breakdown-detail">
        <span>#{type_label} (#{item.stock_class})</span>
        <span>#{format_currency(item.amount)}</span>
      </div>
      """
    end)
    |> Enum.join("\n")
  end

  defp waterfall_steps_html(steps) do
    steps
    |> Enum.map(fn step ->
      """
      <div class="step-item">
        <div class="step-header">Seniority Rank #{step.seniority_rank}</div>
        <div>Proceeds In: #{format_currency(step.proceeds_in)}</div>
        <div>Total Preference: #{format_currency(step.total_preference)}</div>
        <div>Proceeds Out: #{format_currency(step.proceeds_out)}</div>
      </div>
      """
    end)
    |> Enum.join("\n")
  end

  defp format_currency(amount) when is_number(amount) do
    Number.Currency.number_to_currency(amount, precision: 2)
  end

  defp format_currency(_), do: "$0.00"

  defp distribution_type_label(type) do
    case type do
      :liquidation_preference -> "Liquidation Preference"
      :liquidation_preference_prorated -> "Liquidation Preference (Prorated)"
      :participation -> "Participation"
      _ -> to_string(type)
    end
  end
end

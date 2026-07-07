defmodule CaptablexWeb.WaterfallLive do
  use CaptablexWeb, :live_view

  alias Captablex.Waterfall

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:exit_value_input, "10000000")
      |> assign(:waterfall_result, nil)
      |> assign(:show_details, false)

    {:ok, socket}
  end

  @impl true
  def handle_event("calculate_waterfall", %{"exit_value" => exit_value_str}, socket) do
    case parse_exit_value(exit_value_str) do
      {:ok, exit_value} ->
        result = Waterfall.calculate_waterfall(exit_value)

        {:noreply,
         socket
         |> assign(:waterfall_result, result)
         |> assign(:exit_value_input, exit_value_str)
         |> assign(:show_details, false)}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Please enter a valid exit value")
         |> assign(:waterfall_result, nil)}
    end
  end

  @impl true
  def handle_event("toggle_details", _params, socket) do
    {:noreply, assign(socket, :show_details, !socket.assigns.show_details)}
  end

  @impl true
  def handle_event("clear", _params, socket) do
    {:noreply,
     socket
     |> assign(:exit_value_input, "")
     |> assign(:waterfall_result, nil)
     |> assign(:show_details, false)}
  end

  @impl true
  def handle_event("export_pdf", _params, socket) do
    exit_value = socket.assigns.waterfall_result.total_exit_value

    case Captablex.PdfExport.generate_waterfall_pdf(exit_value) do
      {:ok, pdf_path} ->
        # Send file download to client
        {:noreply,
         socket
         |> push_event("download", %{
           url: "/downloads/#{Path.basename(pdf_path)}",
           filename: "waterfall_#{Date.utc_today()}.pdf"
         })}

      {:error, reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to generate PDF: #{inspect(reason)}")}
    end
  end

  defp parse_exit_value(str) do
    # Remove commas and whitespace
    cleaned = String.replace(str, ~r/[,\s]/, "")

    case Float.parse(cleaned) do
      {value, ""} when value > 0 -> {:ok, value}
      {value, ""} -> {:error, :invalid}
      _ -> {:error, :invalid}
    end
  end

  defp format_currency(amount) when is_number(amount) do
    formatted = Number.Currency.number_to_currency(amount, precision: 2)
    formatted
  end

  defp format_currency(_), do: "$0.00"

  defp format_percentage(amount, total)
       when is_number(amount) and is_number(total) and total > 0 do
    percentage = amount / total * 100
    "#{:erlang.float_to_binary(percentage, decimals: 2)}%"
  end

  defp format_percentage(_, _), do: "0.00%"

  defp distribution_type_label(type) do
    case type do
      :liquidation_preference -> "Liquidation Preference"
      :liquidation_preference_prorated -> "Liquidation Preference (Prorated)"
      :participation -> "Participation"
      _ -> to_string(type)
    end
  end

  defp seniority_label(rank) do
    case rank do
      0 -> "Common (Rank 0)"
      1 -> "Preferred Series 1 (Rank 1)"
      2 -> "Preferred Series 2 (Rank 2)"
      3 -> "Preferred Series 3 (Rank 3)"
      n when n > 3 -> "Preferred Series #{n} (Rank #{n})"
      _ -> "Rank #{rank}"
    end
  end
end

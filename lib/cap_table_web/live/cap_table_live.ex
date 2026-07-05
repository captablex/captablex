defmodule CapTableWeb.CapTableLive do
  use CapTableWeb, :live_view

  alias CapTable

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(CapTable.PubSub, "cap_table:updates")
    end

    socket =
      socket
      |> assign(:stakeholders, CapTable.list_stakeholders())
      |> assign(:stock_classes, CapTable.list_stock_classes())
      |> assign(:securities, CapTable.list_securities())
      |> assign(:ownership_breakdown, CapTable.calculate_ownership_breakdown())
      |> assign(:total_shares_outstanding, CapTable.get_total_shares_outstanding())
      |> assign(:total_shares_authorized, CapTable.get_total_shares_authorized())
      |> stream(:transactions, CapTable.list_transactions())

    {:ok, socket}
  end

  def handle_info({:stakeholder_created, _stakeholder}, socket) do
    {:noreply,
     socket
     |> assign(:stakeholders, CapTable.list_stakeholders())
     |> assign(:ownership_breakdown, CapTable.calculate_ownership_breakdown())}
  end

  def handle_info({:stock_class_created, _stock_class}, socket) do
    {:noreply,
     socket
     |> assign(:stock_classes, CapTable.list_stock_classes())
     |> assign(:total_shares_authorized, CapTable.get_total_shares_authorized())}
  end

  def handle_info({:security_issued, security}, socket) do
    {:noreply,
     socket
     |> assign(:securities, CapTable.list_securities())
     |> assign(:ownership_breakdown, CapTable.calculate_ownership_breakdown())
     |> assign(:total_shares_outstanding, CapTable.get_total_shares_outstanding())}
  end

  def handle_info({:transaction_created, transaction}, socket) do
    {:noreply, stream_insert(socket, :transactions, transaction, at: 0)}
  end

  def handle_event("add_stakeholder", %{"stakeholder" => stakeholder_params}, socket) do
    case CapTable.create_stakeholder(stakeholder_params) do
      {:ok, _stakeholder} ->
        {:noreply, put_flash(socket, :info, "Stakeholder added successfully")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to add stakeholder")}
    end
  end

  def handle_event("add_stock_class", %{"stock_class" => stock_class_params}, socket) do
    case CapTable.create_stock_class(stock_class_params) do
      {:ok, _stock_class} ->
        {:noreply, put_flash(socket, :info, "Stock class created successfully")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to create stock class")}
    end
  end

  def handle_event("issue_shares", %{"security" => security_params}, socket) do
    case CapTable.issue_security(security_params) do
      {:ok, _security} ->
        {:noreply, put_flash(socket, :info, "Shares issued successfully")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to issue shares")}
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="min-h-screen bg-gradient-to-br from-slate-950 via-slate-900 to-slate-950 px-6 py-8">
        <!-- Header -->
        <div class="mx-auto max-w-7xl">
          <div class="mb-8 flex items-center justify-between">
            <div>
              <h1 class="text-3xl font-bold text-white">Cap Table Dashboard</h1>
              <p class="mt-1 text-slate-400">Manage your company's equity ownership</p>
            </div>
            <div class="flex space-x-3">
              <button class="rounded-lg bg-slate-800 px-4 py-2 text-sm font-medium text-slate-300 transition hover:bg-slate-700">
                Export OCF
              </button>
              <button class="rounded-lg bg-gradient-to-r from-cyan-500 to-blue-600 px-4 py-2 text-sm font-semibold text-white shadow-lg shadow-cyan-500/20 transition hover:shadow-cyan-500/40">
                Issue Shares
              </button>
            </div>
          </div>
          
    <!-- Stats Grid -->
          <div class="mb-8 grid grid-cols-1 gap-6 md:grid-cols-4">
            <!-- Total Authorized -->
            <div class="rounded-xl border border-slate-800 bg-slate-900/50 p-6 backdrop-blur-sm">
              <p class="text-sm font-medium text-slate-400">Total Authorized</p>
              <p class="mt-2 text-3xl font-bold text-white">
                {Number.Delimit.number_to_delimited(@total_shares_authorized)}
              </p>
            </div>
            
    <!-- Outstanding -->
            <div class="rounded-xl border border-slate-800 bg-slate-900/50 p-6 backdrop-blur-sm">
              <p class="text-sm font-medium text-slate-400">Outstanding</p>
              <p class="mt-2 text-3xl font-bold text-white">
                {Number.Delimit.number_to_delimited(@total_shares_outstanding)}
              </p>
            </div>
            
    <!-- Stakeholders -->
            <div class="rounded-xl border border-slate-800 bg-slate-900/50 p-6 backdrop-blur-sm">
              <p class="text-sm font-medium text-slate-400">Stakeholders</p>
              <p class="mt-2 text-3xl font-bold text-white">{length(@stakeholders)}</p>
            </div>
            
    <!-- Stock Classes -->
            <div class="rounded-xl border border-slate-800 bg-slate-900/50 p-6 backdrop-blur-sm">
              <p class="text-sm font-medium text-slate-400">Stock Classes</p>
              <p class="mt-2 text-3xl font-bold text-white">{length(@stock_classes)}</p>
            </div>
          </div>
          
    <!-- Ownership Table -->
          <div class="rounded-xl border border-slate-800 bg-slate-900/50 p-6 backdrop-blur-sm">
            <h2 class="mb-6 text-lg font-semibold text-white">Ownership Breakdown</h2>
            <div class="overflow-hidden rounded-lg border border-slate-800">
              <table class="w-full">
                <thead>
                  <tr class="border-b border-slate-800 bg-slate-950/50">
                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">
                      Stakeholder
                    </th>
                    <th class="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wider text-slate-400">
                      Shares
                    </th>
                    <th class="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wider text-slate-400">
                      Ownership %
                    </th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-slate-800">
                  <%= for {_id, data} <- @ownership_breakdown do %>
                    <tr class="hover:bg-slate-800/30">
                      <td class="px-4 py-4">
                        <div class="flex items-center space-x-3">
                          <div class="flex h-10 w-10 items-center justify-center rounded-full bg-cyan-500/20 text-sm font-semibold text-cyan-400">
                            {String.first(data.stakeholder.name)}
                          </div>
                          <div>
                            <p class="text-sm font-medium text-white">{data.stakeholder.name}</p>
                            <p class="text-xs text-slate-400">
                              {String.capitalize(data.stakeholder.stakeholder_type)}
                            </p>
                          </div>
                        </div>
                      </td>
                      <td class="px-4 py-4 text-right text-sm text-slate-300">
                        {Number.Delimit.number_to_delimited(data.shares)}
                      </td>
                      <td class="px-4 py-4 text-right">
                        <span class="text-sm font-semibold text-white">{data.percentage}%</span>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end

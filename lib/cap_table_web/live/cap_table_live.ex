defmodule CapTableWeb.CapTableLive do
  use CapTableWeb, :live_view

  alias CapTable

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:stakeholders, CapTable.list_stakeholders())
      |> assign(:stock_classes, CapTable.list_stock_classes())
      |> assign(:securities, CapTable.list_securities())
      |> assign(:ownership_breakdown, CapTable.calculate_ownership_breakdown())
      |> assign(:total_shares_outstanding, CapTable.get_total_shares_outstanding())
      |> assign(:total_shares_authorized, CapTable.get_total_shares_authorized())
      |> assign(:show_stakeholder_modal, false)
      |> assign(:show_issue_shares_modal, false)
      |> assign(:stakeholder_form, to_form(%{}))
      |> assign(:issue_shares_form, to_form(%{}))

    if connected?(socket) do
      Phoenix.PubSub.subscribe(CapTable.PubSub, "cap_table:updates")

      {:ok, stream(socket, :transactions, CapTable.list_transactions())}
    else
      {:ok, stream(socket, :transactions, [])}
    end
  end

  defp format_number(number) when is_integer(number) do
    number
    |> Integer.to_string()
    |> String.to_charlist()
    |> Enum.reverse()
    |> Enum.chunk_every(3)
    |> Enum.join(",")
    |> String.reverse()
  end

  defp format_number(number), do: to_string(number)

  defp format_date(date) do
    Calendar.strftime(date, "%b %d, %Y")
  end

  defp transaction_icon(type) do
    case type do
      "issuance" -> "hero-plus-circle"
      "transfer" -> "hero-arrow-path"
      "cancellation" -> "hero-x-circle"
      "exercise" -> "hero-check-circle"
      _ -> "hero-document"
    end
  end

  defp transaction_color(type) do
    case type do
      "issuance" -> "emerald"
      "transfer" -> "blue"
      "cancellation" -> "red"
      "exercise" -> "purple"
      _ -> "slate"
    end
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

  def handle_info({:security_issued, _security}, socket) do
    {:noreply,
     socket
     |> assign(:securities, CapTable.list_securities())
     |> assign(:ownership_breakdown, CapTable.calculate_ownership_breakdown())
     |> assign(:total_shares_outstanding, CapTable.get_total_shares_outstanding())}
  end

  def handle_info({:transaction_created, transaction}, socket) do
    {:noreply, stream_insert(socket, :transactions, transaction, at: 0)}
  end

  def handle_event("open_stakeholder_modal", _params, socket) do
    {:noreply, assign(socket, :show_stakeholder_modal, true)}
  end

  def handle_event("close_stakeholder_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_stakeholder_modal, false)
     |> assign(:stakeholder_form, to_form(%{}))}
  end

  def handle_event("open_issue_shares_modal", _params, socket) do
    {:noreply, assign(socket, :show_issue_shares_modal, true)}
  end

  def handle_event("close_issue_shares_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_issue_shares_modal, false)
     |> assign(:issue_shares_form, to_form(%{}))}
  end

  def handle_event("validate_stakeholder", %{"stakeholder" => params}, socket) do
    {:noreply, assign(socket, :stakeholder_form, to_form(params, as: :stakeholder))}
  end

  def handle_event("validate_issue_shares", %{"issue_shares" => params}, socket) do
    {:noreply, assign(socket, :issue_shares_form, to_form(params, as: :issue_shares))}
  end

  def handle_event("add_stakeholder", %{"stakeholder" => stakeholder_params}, socket) do
    case CapTable.create_stakeholder(stakeholder_params) do
      {:ok, _stakeholder} ->
        {:noreply,
         socket
         |> assign(:show_stakeholder_modal, false)
         |> assign(:stakeholder_form, to_form(%{}))
         |> put_flash(:info, "Stakeholder added successfully")}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:stakeholder_form, to_form(changeset))
         |> put_flash(:error, "Failed to add stakeholder")}
    end
  end

  def handle_event("issue_shares", %{"issue_shares" => params}, socket) do
    security_params = %{
      stakeholder_id: params["stakeholder_id"],
      stock_class_id: params["stock_class_id"],
      shares: params["shares"],
      issue_date: params["issue_date"] || Date.utc_today(),
      certificate_id: params["certificate_id"]
    }

    transaction_params = %{
      transaction_type: "issuance",
      transaction_date: params["issue_date"] || Date.utc_today(),
      quantity: params["shares"],
      price_per_share: params["price_per_share"],
      stakeholder_id: params["stakeholder_id"]
    }

    with {:ok, security} <- CapTable.issue_security(security_params),
         {:ok, _transaction} <-
           CapTable.create_transaction(Map.put(transaction_params, :security_id, security.id)) do
      {:noreply,
       socket
       |> assign(:show_issue_shares_modal, false)
       |> assign(:issue_shares_form, to_form(%{}))
       |> put_flash(:info, "Shares issued successfully")}
    else
      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:issue_shares_form, to_form(changeset))
         |> put_flash(:error, "Failed to issue shares")}
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
              <button
                phx-click="open_stakeholder_modal"
                class="rounded-lg bg-slate-800 px-4 py-2 text-sm font-medium text-slate-300 transition hover:bg-slate-700"
              >
                Add Stakeholder
              </button>
              <button
                phx-click="open_issue_shares_modal"
                class="rounded-lg bg-gradient-to-r from-cyan-500 to-blue-600 px-4 py-2 text-sm font-semibold text-white shadow-lg shadow-cyan-500/20 transition hover:shadow-cyan-500/40"
              >
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
                {format_number(@total_shares_authorized)}
              </p>
            </div>
            
    <!-- Outstanding -->
            <div class="rounded-xl border border-slate-800 bg-slate-900/50 p-6 backdrop-blur-sm">
              <p class="text-sm font-medium text-slate-400">Outstanding</p>
              <p class="mt-2 text-3xl font-bold text-white">
                {format_number(@total_shares_outstanding)}
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
          
    <!-- Main Grid -->
          <div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
            <!-- Ownership Table (2 cols) -->
            <div class="lg:col-span-2">
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
                            {format_number(data.shares)}
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
            
    <!-- Transaction History (1 col) -->
            <div class="lg:col-span-1">
              <div class="rounded-xl border border-slate-800 bg-slate-900/50 p-6 backdrop-blur-sm">
                <div class="mb-6 flex items-center justify-between">
                  <h2 class="text-lg font-semibold text-white">Recent Activity</h2>
                  <button class="text-sm text-cyan-400 hover:text-cyan-300">View All</button>
                </div>
                <div id="transactions" phx-update="stream" class="space-y-3">
                  <div
                    :for={{id, transaction} <- @streams.transactions}
                    id={id}
                    class="flex items-start space-x-3 rounded-lg border border-slate-800 bg-slate-950/50 p-3 transition hover:border-slate-700"
                  >
                    <div class={"flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-#{transaction_color(transaction.transaction_type)}-500/10"}>
                      <.icon
                        name={transaction_icon(transaction.transaction_type)}
                        class={"h-5 w-5 text-#{transaction_color(transaction.transaction_type)}-400"}
                      />
                    </div>
                    <div class="min-w-0 flex-1">
                      <p class="text-sm font-medium text-white">
                        {String.capitalize(transaction.transaction_type)}
                      </p>
                      <p class="text-xs text-slate-400">{transaction.stakeholder.name}</p>
                      <div class="mt-1 flex items-center justify-between">
                        <p class="text-xs font-semibold text-slate-300">
                          {format_number(transaction.quantity)} shares
                        </p>
                        <p class="text-xs text-slate-500">
                          {format_date(transaction.transaction_date)}
                        </p>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Add Stakeholder Modal -->
      <%= if @show_stakeholder_modal do %>
        <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
          <div class="w-full max-w-md rounded-xl border border-slate-800 bg-slate-900 p-6 shadow-2xl">
            <div class="mb-6 flex items-center justify-between">
              <h3 class="text-xl font-bold text-white">Add Stakeholder</h3>
              <button
                phx-click="close_stakeholder_modal"
                class="rounded-lg p-2 text-slate-400 transition hover:bg-slate-800 hover:text-white"
              >
                <.icon name="hero-x-mark" class="h-5 w-5" />
              </button>
            </div>

            <.form
              for={@stakeholder_form}
              id="stakeholder-form"
              phx-change="validate_stakeholder"
              phx-submit="add_stakeholder"
            >
              <div class="space-y-4">
                <div>
                  <label class="mb-2 block text-sm font-medium text-slate-300">Name</label>
                  <input
                    type="text"
                    name="stakeholder[name]"
                    value={@stakeholder_form[:name].value}
                    required
                    class="w-full rounded-lg border border-slate-700 bg-slate-800 px-4 py-2 text-white placeholder-slate-500 focus:border-cyan-500 focus:outline-none focus:ring-2 focus:ring-cyan-500/20"
                    placeholder="Enter stakeholder name"
                  />
                </div>

                <div>
                  <label class="mb-2 block text-sm font-medium text-slate-300">Type</label>
                  <select
                    name="stakeholder[stakeholder_type]"
                    required
                    class="w-full rounded-lg border border-slate-700 bg-slate-800 px-4 py-2 text-white focus:border-cyan-500 focus:outline-none focus:ring-2 focus:ring-cyan-500/20"
                  >
                    <option value="">Select type</option>
                    <option value="individual">Individual</option>
                    <option value="institution">Institution</option>
                  </select>
                </div>

                <div>
                  <label class="mb-2 block text-sm font-medium text-slate-300">Email</label>
                  <input
                    type="email"
                    name="stakeholder[email]"
                    value={@stakeholder_form[:email].value}
                    class="w-full rounded-lg border border-slate-700 bg-slate-800 px-4 py-2 text-white placeholder-slate-500 focus:border-cyan-500 focus:outline-none focus:ring-2 focus:ring-cyan-500/20"
                    placeholder="email@example.com"
                  />
                </div>

                <div>
                  <label class="mb-2 block text-sm font-medium text-slate-300">Tax ID</label>
                  <input
                    type="text"
                    name="stakeholder[tax_id]"
                    value={@stakeholder_form[:tax_id].value}
                    class="w-full rounded-lg border border-slate-700 bg-slate-800 px-4 py-2 text-white placeholder-slate-500 focus:border-cyan-500 focus:outline-none focus:ring-2 focus:ring-cyan-500/20"
                    placeholder="123-45-6789"
                  />
                </div>
              </div>

              <div class="mt-6 flex justify-end space-x-3">
                <button
                  type="button"
                  phx-click="close_stakeholder_modal"
                  class="rounded-lg bg-slate-800 px-4 py-2 text-sm font-medium text-slate-300 transition hover:bg-slate-700"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  class="rounded-lg bg-gradient-to-r from-cyan-500 to-blue-600 px-4 py-2 text-sm font-semibold text-white shadow-lg shadow-cyan-500/20 transition hover:shadow-cyan-500/40"
                >
                  Add Stakeholder
                </button>
              </div>
            </.form>
          </div>
        </div>
      <% end %>
      
    <!-- Issue Shares Modal -->
      <%= if @show_issue_shares_modal do %>
        <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
          <div class="w-full max-w-md rounded-xl border border-slate-800 bg-slate-900 p-6 shadow-2xl">
            <div class="mb-6 flex items-center justify-between">
              <h3 class="text-xl font-bold text-white">Issue Shares</h3>
              <button
                phx-click="close_issue_shares_modal"
                class="rounded-lg p-2 text-slate-400 transition hover:bg-slate-800 hover:text-white"
              >
                <.icon name="hero-x-mark" class="h-5 w-5" />
              </button>
            </div>

            <.form
              for={@issue_shares_form}
              id="issue-shares-form"
              phx-change="validate_issue_shares"
              phx-submit="issue_shares"
            >
              <div class="space-y-4">
                <div>
                  <label class="mb-2 block text-sm font-medium text-slate-300">Stakeholder</label>
                  <select
                    name="issue_shares[stakeholder_id]"
                    required
                    class="w-full rounded-lg border border-slate-700 bg-slate-800 px-4 py-2 text-white focus:border-cyan-500 focus:outline-none focus:ring-2 focus:ring-cyan-500/20"
                  >
                    <option value="">Select stakeholder</option>
                    <%= for stakeholder <- @stakeholders do %>
                      <option value={stakeholder.id}>{stakeholder.name}</option>
                    <% end %>
                  </select>
                </div>

                <div>
                  <label class="mb-2 block text-sm font-medium text-slate-300">Stock Class</label>
                  <select
                    name="issue_shares[stock_class_id]"
                    required
                    class="w-full rounded-lg border border-slate-700 bg-slate-800 px-4 py-2 text-white focus:border-cyan-500 focus:outline-none focus:ring-2 focus:ring-cyan-500/20"
                  >
                    <option value="">Select stock class</option>
                    <%= for stock_class <- @stock_classes do %>
                      <option value={stock_class.id}>{stock_class.name}</option>
                    <% end %>
                  </select>
                </div>

                <div>
                  <label class="mb-2 block text-sm font-medium text-slate-300">
                    Number of Shares
                  </label>
                  <input
                    type="number"
                    name="issue_shares[shares]"
                    value={@issue_shares_form[:shares].value}
                    required
                    min="1"
                    class="w-full rounded-lg border border-slate-700 bg-slate-800 px-4 py-2 text-white placeholder-slate-500 focus:border-cyan-500 focus:outline-none focus:ring-2 focus:ring-cyan-500/20"
                    placeholder="1000000"
                  />
                </div>

                <div>
                  <label class="mb-2 block text-sm font-medium text-slate-300">
                    Price Per Share
                  </label>
                  <input
                    type="number"
                    name="issue_shares[price_per_share]"
                    value={@issue_shares_form[:price_per_share].value}
                    required
                    min="0"
                    step="0.01"
                    class="w-full rounded-lg border border-slate-700 bg-slate-800 px-4 py-2 text-white placeholder-slate-500 focus:border-cyan-500 focus:outline-none focus:ring-2 focus:ring-cyan-500/20"
                    placeholder="0.01"
                  />
                </div>

                <div>
                  <label class="mb-2 block text-sm font-medium text-slate-300">Issue Date</label>
                  <input
                    type="date"
                    name="issue_shares[issue_date]"
                    value={@issue_shares_form[:issue_date].value || Date.utc_today()}
                    required
                    class="w-full rounded-lg border border-slate-700 bg-slate-800 px-4 py-2 text-white focus:border-cyan-500 focus:outline-none focus:ring-2 focus:ring-cyan-500/20"
                  />
                </div>

                <div>
                  <label class="mb-2 block text-sm font-medium text-slate-300">
                    Certificate ID
                  </label>
                  <input
                    type="text"
                    name="issue_shares[certificate_id]"
                    value={@issue_shares_form[:certificate_id].value}
                    class="w-full rounded-lg border border-slate-700 bg-slate-800 px-4 py-2 text-white placeholder-slate-500 focus:border-cyan-500 focus:outline-none focus:ring-2 focus:ring-cyan-500/20"
                    placeholder="CS-001"
                  />
                </div>
              </div>

              <div class="mt-6 flex justify-end space-x-3">
                <button
                  type="button"
                  phx-click="close_issue_shares_modal"
                  class="rounded-lg bg-slate-800 px-4 py-2 text-sm font-medium text-slate-300 transition hover:bg-slate-700"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  class="rounded-lg bg-gradient-to-r from-cyan-500 to-blue-600 px-4 py-2 text-sm font-semibold text-white shadow-lg shadow-cyan-500/20 transition hover:shadow-cyan-500/40"
                >
                  Issue Shares
                </button>
              </div>
            </.form>
          </div>
        </div>
      <% end %>
    </Layouts.app>
    """
  end
end

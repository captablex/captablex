defmodule CaptablexWeb.CaptablexLive do
  use CaptablexWeb, :live_view

  alias Captablex
  alias Captablex.CapTable.StockClass

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:stakeholders, Captablex.list_stakeholders())
      |> assign(:stock_classes, Captablex.list_stock_classes())
      |> assign(:securities, Captablex.list_securities())
      |> assign(:ownership_breakdown, Captablex.calculate_ownership_breakdown())
      |> assign(:total_shares_outstanding, Captablex.get_total_shares_outstanding())
      |> assign(:total_shares_authorized, Captablex.get_total_shares_authorized())
      |> assign(:show_stakeholder_modal?, false)
      |> assign(:show_issue_shares_modal?, false)
      |> stream(:transactions, Captablex.list_transactions())

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Captablex.PubSub, "captablex:updates")
    end

    {:ok, socket}
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

  def handle_info({:stakeholder_created, _stakeholder}, socket) do
    {:noreply,
     socket
     |> assign(:stakeholders, Captablex.list_stakeholders())
     |> assign(:ownership_breakdown, Captablex.calculate_ownership_breakdown())}
  end

  def handle_info({:stock_class_created, _stock_class}, socket) do
    {:noreply,
     socket
     |> assign(:stock_classes, Captablex.list_stock_classes())
     |> assign(:total_shares_authorized, Captablex.get_total_shares_authorized())}
  end

  def handle_info({:security_issued, _security}, socket) do
    {:noreply,
     socket
     |> assign(:securities, Captablex.list_securities())
     |> assign(:ownership_breakdown, Captablex.calculate_ownership_breakdown())
     |> assign(:total_shares_outstanding, Captablex.get_total_shares_outstanding())}
  end

  def handle_info({:transaction_created, transaction}, socket) do
    {:noreply, stream_insert(socket, :transactions, transaction, at: 0)}
  end

  def handle_event("open_stakeholder_modal", _params, socket) do
    {:noreply, assign(socket, :show_stakeholder_modal?, true)}
  end

  def handle_event("close_stakeholder_modal", _params, socket) do
    {:noreply, assign(socket, :show_stakeholder_modal?, false)}
  end

  def handle_event("open_issue_shares_modal", _params, socket) do
    {:noreply, assign(socket, :show_issue_shares_modal?, true)}
  end

  def handle_event("close_issue_shares_modal", _params, socket) do
    {:noreply, assign(socket, :show_issue_shares_modal?, false)}
  end

  def handle_event("add_stakeholder", %{"stakeholder" => stakeholder_params}, socket) do
    case Captablex.create_stakeholder(stakeholder_params) do
      {:ok, _stakeholder} ->
        {:noreply,
         socket
         |> assign(:show_stakeholder_modal?, false)
         |> put_flash(:info, "Stakeholder added successfully")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to add stakeholder")}
    end
  end

  def handle_event("add_stock_class", %{"stock_class" => stock_class_params}, socket) do
    case Captablex.create_stock_class(stock_class_params) do
      {:ok, _stock_class} ->
        {:noreply, put_flash(socket, :info, "Stock class created successfully")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to create stock class")}
    end
  end

  def handle_event("issue_shares", %{"security" => security_params}, socket) do
    case Captablex.issue_security(security_params) do
      {:ok, _security} ->
        {:noreply,
         socket
         |> assign(:show_issue_shares_modal?, false)
         |> put_flash(:info, "Shares issued successfully")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to issue shares")}
    end
  end

  def handle_event("export_ocf", _params, socket) do
    ocf_data = build_ocf_export(socket.assigns)
    json = Jason.encode!(ocf_data, pretty: true)

    {:noreply,
     socket
     |> push_event("download", %{
       filename: "captablex_ocf_#{Date.utc_today()}.json",
       content: json,
       mime_type: "application/json"
     })}
  end

  defp build_ocf_export(assigns) do
    %{
      "ocf_version" => "1.0.0",
      "file_type" => "OCF_MANIFEST_FILE",
      "generated_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "issuer" => %{
        "id" => "issuer-1",
        "legal_name" => "Company Inc.",
        "formation_date" => Date.utc_today() |> Date.to_iso8601()
      },
      "stakeholders" =>
        Enum.map(assigns.stakeholders, fn stakeholder ->
          %{
            "id" => "stakeholder-#{stakeholder.id}",
            "name" => %{"legal_name" => stakeholder.name},
            "stakeholder_type" => String.upcase(stakeholder.stakeholder_type),
            "contact_info" => %{"email" => stakeholder.email || ""}
          }
        end),
      "stock_classes" =>
        Enum.map(assigns.stock_classes, fn stock_class ->
          %{
            "id" => "stock-class-#{stock_class.id}",
            "name" => StockClass.display_name(stock_class),
            "class_type" => String.upcase(stock_class.security_type),
            "shares_authorized" => stock_class.shares_authorized,
            "par_value" => Decimal.to_string(stock_class.par_value || Decimal.new("0"))
          }
        end),
      "securities" =>
        Enum.map(assigns.securities, fn security ->
          %{
            "id" => "security-#{security.id}",
            "stakeholder_id" => "stakeholder-#{security.stakeholder_id}",
            "stock_class_id" => "stock-class-#{security.stock_class_id}",
            "quantity" => security.shares,
            "issue_date" => Date.to_iso8601(security.issue_date),
            "certificate_id" => security.certificate_id
          }
        end),
      "summary" => %{
        "total_authorized_shares" => assigns.total_shares_authorized,
        "total_outstanding_shares" => assigns.total_shares_outstanding,
        "total_stakeholders" => length(assigns.stakeholders),
        "total_stock_classes" => length(assigns.stock_classes)
      }
    }
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div
        phx-hook="Download"
        id="download-hook"
        class="min-h-screen bg-gradient-to-br from-slate-950 via-slate-900 to-slate-950 px-6 py-8"
      >
        <!-- Header -->
        <div class="mx-auto max-w-7xl">
          <div class="mb-8 flex items-center justify-between">
            <div>
              <h1 class="text-3xl font-bold text-white">Cap Table Dashboard</h1>
              <p class="mt-1 text-slate-400">Manage your company's equity ownership</p>
            </div>
            <div class="flex space-x-3">
              <button
                phx-click="export_ocf"
                class="rounded-lg bg-slate-800 px-4 py-2 text-sm font-medium text-slate-300 transition hover:bg-slate-700"
              >
                Export OCF
              </button>
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
          <!-- Main Content Grid -->
          <div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
            <!-- Ownership Table (2 columns) -->
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
            <!-- Transaction History (1 column) -->
            <div class="lg:col-span-1">
              <div class="rounded-xl border border-slate-800 bg-slate-900/50 p-6 backdrop-blur-sm">
                <div class="mb-4 flex items-center justify-between">
                  <h2 class="text-lg font-semibold text-white">Recent Activity</h2>
                  <button class="text-xs font-medium text-cyan-400 hover:text-cyan-300">
                    View All
                  </button>
                </div>
                <div id="transactions" phx-update="stream" class="space-y-3">
                  <%= for {dom_id, transaction} <- @streams.transactions do %>
                    <div
                      id={dom_id}
                      class="flex items-start space-x-3 rounded-lg border border-slate-800 bg-slate-950/50 p-3 transition hover:border-slate-700"
                    >
                      <div class={
                        case transaction.transaction_type do
                          "issuance" ->
                            "flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-emerald-500/10"

                          "transfer" ->
                            "flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-blue-500/10"

                          "cancellation" ->
                            "flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-red-500/10"

                          "exercise" ->
                            "flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-purple-500/10"

                          _ ->
                            "flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-slate-500/10"
                        end
                      }>
                        <.icon
                          name={
                            case transaction.transaction_type do
                              "issuance" -> "hero-plus-circle"
                              "transfer" -> "hero-arrow-path"
                              "cancellation" -> "hero-x-circle"
                              "exercise" -> "hero-check-circle"
                              _ -> "hero-document"
                            end
                          }
                          class={
                            case transaction.transaction_type do
                              "issuance" -> "h-5 w-5 text-emerald-400"
                              "transfer" -> "h-5 w-5 text-blue-400"
                              "cancellation" -> "h-5 w-5 text-red-400"
                              "exercise" -> "h-5 w-5 text-purple-400"
                              _ -> "h-5 w-5 text-slate-400"
                            end
                          }
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
                            {Calendar.strftime(transaction.transaction_date, "%b %d, %Y")}
                          </p>
                        </div>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <!-- Add Stakeholder Modal (DaisyUI) -->
      <input
        type="checkbox"
        id="stakeholder-modal"
        class="modal-toggle"
        checked={@show_stakeholder_modal?}
      />
      <div class="modal" role="dialog">
        <div class="modal-box bg-slate-900 border border-slate-800">
          <div class="mb-4 flex items-center justify-between">
            <h3 class="text-lg font-semibold text-white">Add Stakeholder</h3>
            <button
              phx-click="close_stakeholder_modal"
              class="text-slate-400 hover:text-white"
            >
              <.icon name="hero-x-mark" class="h-5 w-5" />
            </button>
          </div>
          <form id="stakeholder-form" phx-submit="add_stakeholder" class="space-y-4">
            <div>
              <label class="mb-1 block text-sm font-medium text-slate-300">Name</label>
              <input
                type="text"
                name="stakeholder[name]"
                required
                class="w-full rounded-lg border border-slate-700 bg-slate-800 px-4 py-2 text-white placeholder-slate-500 focus:border-cyan-500 focus:outline-none focus:ring-2 focus:ring-cyan-500/20"
                placeholder="Enter stakeholder name"
              />
            </div>
            <div>
              <label class="mb-1 block text-sm font-medium text-slate-300">Type</label>
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
              <label class="mb-1 block text-sm font-medium text-slate-300">Email</label>
              <input
                type="email"
                name="stakeholder[email]"
                class="w-full rounded-lg border border-slate-700 bg-slate-800 px-4 py-2 text-white placeholder-slate-500 focus:border-cyan-500 focus:outline-none focus:ring-2 focus:ring-cyan-500/20"
                placeholder="email@example.com"
              />
            </div>
            <div>
              <label class="mb-1 block text-sm font-medium text-slate-300">Tax ID</label>
              <input
                type="text"
                name="stakeholder[tax_id]"
                class="w-full rounded-lg border border-slate-700 bg-slate-800 px-4 py-2 text-white placeholder-slate-500 focus:border-cyan-500 focus:outline-none focus:ring-2 focus:ring-cyan-500/20"
                placeholder="XXX-XX-XXXX"
              />
            </div>
            <div class="modal-action">
              <button
                type="button"
                phx-click="close_stakeholder_modal"
                class="btn btn-ghost text-slate-300"
              >
                Cancel
              </button>
              <button
                type="submit"
                class="btn bg-gradient-to-r from-cyan-500 to-blue-600 border-0 text-white hover:shadow-lg hover:shadow-cyan-500/40"
              >
                Add Stakeholder
              </button>
            </div>
          </form>
        </div>
        <label class="modal-backdrop" phx-click="close_stakeholder_modal">Close</label>
      </div>
      <!-- Issue Shares Modal (DaisyUI) -->
      <input
        type="checkbox"
        id="issue-shares-modal"
        class="modal-toggle"
        checked={@show_issue_shares_modal?}
      />
      <div class="modal" role="dialog">
        <div class="modal-box bg-slate-900 border border-slate-800">
          <div class="mb-4 flex items-center justify-between">
            <h3 class="text-lg font-semibold text-white">Issue Shares</h3>
            <button
              phx-click="close_issue_shares_modal"
              class="text-slate-400 hover:text-white"
            >
              <.icon name="hero-x-mark" class="h-5 w-5" />
            </button>
          </div>
          <form id="issue-shares-form" phx-submit="issue_shares" class="space-y-4">
            <div>
              <label class="mb-1 block text-sm font-medium text-slate-300">Stakeholder</label>
              <select
                name="security[stakeholder_id]"
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
              <label class="mb-1 block text-sm font-medium text-slate-300">Stock Class</label>
              <select
                name="security[stock_class_id]"
                required
                class="w-full rounded-lg border border-slate-700 bg-slate-800 px-4 py-2 text-white focus:border-cyan-500 focus:outline-none focus:ring-2 focus:ring-cyan-500/20"
              >
                <option value="">Select stock class</option>
                <%= for stock_class <- @stock_classes do %>
                  <option value={stock_class.id}>
                    {StockClass.display_name(stock_class)}
                  </option>
                <% end %>
              </select>
            </div>
            <div>
              <label class="mb-1 block text-sm font-medium text-slate-300">
                Number of Shares
              </label>
              <input
                type="number"
                name="security[shares]"
                min="1"
                required
                class="w-full rounded-lg border border-slate-700 bg-slate-800 px-4 py-2 text-white placeholder-slate-500 focus:border-cyan-500 focus:outline-none focus:ring-2 focus:ring-cyan-500/20"
                placeholder="1000"
              />
            </div>
            <div>
              <label class="mb-1 block text-sm font-medium text-slate-300">
                Price Per Share
              </label>
              <input
                type="number"
                step="0.01"
                name="security[price_per_share]"
                min="0"
                required
                class="w-full rounded-lg border border-slate-700 bg-slate-800 px-4 py-2 text-white placeholder-slate-500 focus:border-cyan-500 focus:outline-none focus:ring-2 focus:ring-cyan-500/20"
                placeholder="1.00"
              />
            </div>
            <div>
              <label class="mb-1 block text-sm font-medium text-slate-300">Issue Date</label>
              <input
                type="date"
                name="security[issue_date]"
                value={Date.utc_today() |> Date.to_iso8601()}
                required
                class="w-full rounded-lg border border-slate-700 bg-slate-800 px-4 py-2 text-white focus:border-cyan-500 focus:outline-none focus:ring-2 focus:ring-cyan-500/20"
              />
            </div>
            <div>
              <label class="mb-1 block text-sm font-medium text-slate-300">
                Certificate ID
              </label>
              <input
                type="text"
                name="security[certificate_id]"
                class="w-full rounded-lg border border-slate-700 bg-slate-800 px-4 py-2 text-white placeholder-slate-500 focus:border-cyan-500 focus:outline-none focus:ring-2 focus:ring-cyan-500/20"
                placeholder="CERT-001"
              />
            </div>
            <div class="modal-action">
              <button
                type="button"
                phx-click="close_issue_shares_modal"
                class="btn btn-ghost text-slate-300"
              >
                Cancel
              </button>
              <button
                type="submit"
                class="btn bg-gradient-to-r from-cyan-500 to-blue-600 border-0 text-white hover:shadow-lg hover:shadow-cyan-500/40"
              >
                Issue Shares
              </button>
            </div>
          </form>
        </div>
        <label class="modal-backdrop" phx-click="close_issue_shares_modal">Close</label>
      </div>
    </Layouts.app>
    """
  end
end

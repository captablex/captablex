defmodule CaptablexWeb.SettingsLive do
  use CaptablexWeb, :live_view

  alias Captablex.Settings
  alias Captablex.CapTable
  alias Captablex.CapTable.StockClass
  alias Captablex.Settings.ConfigurationOption
  alias Captablex.Accounts
  alias Captablex.Accounts.Stakeholder

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Captablex.PubSub, "captablex:updates")
    end

    socket =
      socket
      |> assign(:active_tab, "security_types")
      |> assign(:show_stock_class_modal, false)
      |> assign(:editing_stock_class, nil)
      |> assign(:show_option_modal, false)
      |> assign(:show_stakeholder_modal, false)
      |> assign(:editing_option, nil)
      |> assign(:editing_stakeholder, nil)
      |> load_all_data()

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    tab = params["tab"] || "stock_classes"
    {:noreply, assign(socket, :active_tab, tab)}
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, push_patch(socket, to: ~p"/settings?tab=#{tab}")}
  end

  @impl true
  def handle_event("open_option_modal", %{"type" => option_type}, socket) do
    changeset = Settings.change_option(%ConfigurationOption{option_type: option_type})

    {:noreply,
     socket
     |> assign(:show_option_modal, true)
     |> assign(:editing_option, nil)
     |> assign(:option_form, to_form(changeset))}
  end

  @impl true
  def handle_event("edit_option", %{"id" => id}, socket) do
    option = Settings.get_option!(id)
    changeset = Settings.change_option(option)

    {:noreply,
     socket
     |> assign(:show_option_modal, true)
     |> assign(:editing_option, option)
     |> assign(:option_form, to_form(changeset))}
  end

  @impl true
  def handle_event("delete_option", %{"id" => id}, socket) do
    option = Settings.get_option!(id)

    case Settings.delete_option(option) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Option deleted successfully")
         |> load_all_data()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to delete option")}
    end
  end

  @impl true
  def handle_event("save_option", %{"configuration_option" => option_params}, socket) do
    save_option_fn =
      if socket.assigns.editing_option do
        &Settings.update_option(socket.assigns.editing_option, &1)
      else
        &Settings.create_option(&1)
      end

    case save_option_fn.(option_params) do
      {:ok, _option} ->
        {:noreply,
         socket
         |> put_flash(:info, "Option saved successfully")
         |> assign(:show_option_modal, false)
         |> load_all_data()}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :option_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("close_option_modal", _params, socket) do
    {:noreply, assign(socket, :show_option_modal, false)}
  end

  @impl true
  @impl true
  def handle_event("open_stock_class_modal", _params, socket) do
    changeset = CapTable.change_stock_class(%StockClass{})

    {:noreply,
     socket
     |> assign(:show_stock_class_modal, true)
     |> assign(:editing_stock_class, nil)
     |> assign(:stock_class_form, to_form(changeset))}
  end

  @impl true
  def handle_event("edit_stock_class", %{"id" => id}, socket) do
    stock_class = CapTable.get_stock_class!(id)
    changeset = CapTable.change_stock_class(stock_class)

    {:noreply,
     socket
     |> assign(:show_stock_class_modal, true)
     |> assign(:editing_stock_class, stock_class)
     |> assign(:stock_class_form, to_form(changeset))}
  end

  @impl true
  def handle_event("delete_stock_class", %{"id" => id}, socket) do
    stock_class = CapTable.get_stock_class!(id)

    case CapTable.delete_stock_class(stock_class) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Stock class deleted successfully")
         |> load_all_data()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to delete stock class")}
    end
  end

  @impl true
  def handle_event("save_stock_class", %{"stock_class" => stock_class_params}, socket) do
    save_stock_class_fn =
      if socket.assigns.editing_stock_class do
        &CapTable.update_stock_class(socket.assigns.editing_stock_class, &1)
      else
        &CapTable.create_stock_class(&1)
      end

    case save_stock_class_fn.(stock_class_params) do
      {:ok, _stock_class} ->
        {:noreply,
         socket
         |> put_flash(:info, "Stock class saved successfully")
         |> assign(:show_stock_class_modal, false)
         |> load_all_data()}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :stock_class_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("close_stock_class_modal", _params, socket) do
    {:noreply, assign(socket, :show_stock_class_modal, false)}
  end

  def handle_event("open_stakeholder_modal", _params, socket) do
    changeset = Accounts.change_stakeholder(%Stakeholder{})

    {:noreply,
     socket
     |> assign(:show_stakeholder_modal, true)
     |> assign(:editing_stakeholder, nil)
     |> assign(:stakeholder_form, to_form(changeset))}
  end

  @impl true
  def handle_event("edit_stakeholder", %{"id" => id}, socket) do
    stakeholder = Accounts.get_stakeholder!(id)
    changeset = Accounts.change_stakeholder(stakeholder)

    {:noreply,
     socket
     |> assign(:show_stakeholder_modal, true)
     |> assign(:editing_stakeholder, stakeholder)
     |> assign(:stakeholder_form, to_form(changeset))}
  end

  @impl true
  def handle_event("delete_stakeholder", %{"id" => id}, socket) do
    stakeholder = Accounts.get_stakeholder!(id)

    case Accounts.delete_stakeholder(stakeholder) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Stakeholder deleted successfully")
         |> load_all_data()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to delete stakeholder")}
    end
  end

  @impl true
  def handle_event("save_stakeholder", %{"stakeholder" => stakeholder_params}, socket) do
    save_stakeholder_fn =
      if socket.assigns.editing_stakeholder do
        &Accounts.update_stakeholder(socket.assigns.editing_stakeholder, &1)
      else
        &Accounts.create_stakeholder(&1)
      end

    case save_stakeholder_fn.(stakeholder_params) do
      {:ok, _stakeholder} ->
        {:noreply,
         socket
         |> put_flash(:info, "Stakeholder saved successfully")
         |> assign(:show_stakeholder_modal, false)
         |> load_all_data()}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :stakeholder_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("close_stakeholder_modal", _params, socket) do
    {:noreply, assign(socket, :show_stakeholder_modal, false)}
  end

  @impl true
  def handle_event("noop", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:option_created, _option}, socket) do
    {:noreply, load_all_data(socket)}
  end

  @impl true
  def handle_info({:option_updated, _option}, socket) do
    {:noreply, load_all_data(socket)}
  end

  @impl true
  def handle_info({:option_deleted, _option}, socket) do
    {:noreply, load_all_data(socket)}
  end

  @impl true
  @impl true
  def handle_info({:stock_class_created, _stock_class}, socket) do
    {:noreply, load_all_data(socket)}
  end

  @impl true
  def handle_info({:stock_class_updated, _stock_class}, socket) do
    {:noreply, load_all_data(socket)}
  end

  @impl true
  def handle_info({:stock_class_deleted, _stock_class}, socket) do
    {:noreply, load_all_data(socket)}
  end

  def handle_info({:stakeholder_created, _stakeholder}, socket) do
    {:noreply, load_all_data(socket)}
  end

  @impl true
  def handle_info({:stakeholder_updated, _stakeholder}, socket) do
    {:noreply, load_all_data(socket)}
  end

  @impl true
  def handle_info({:stakeholder_deleted, _stakeholder}, socket) do
    {:noreply, load_all_data(socket)}
  end

  defp load_all_data(socket) do
    all_options = Settings.list_all_options()

    socket
    |> assign(:security_types, Map.get(all_options, "security_type", []))
    |> assign(:stakeholder_types, Map.get(all_options, "stakeholder_type", []))
    |> assign(:series, Map.get(all_options, "series", []))
    |> assign(:stakeholders, Accounts.list_stakeholders())
    |> assign(:stock_classes, CapTable.list_stock_classes())
  end

  defp tab_class(active_tab, tab) do
    base = "px-6 py-3 font-medium text-sm transition-all duration-200 border-b-2"

    if active_tab == tab do
      "#{base} border-cyan-500 text-cyan-400"
    else
      "#{base} border-transparent text-slate-400 hover:text-slate-200 hover:border-slate-600"
    end
  end

  defp option_type_label(type) do
    case type do
      "security_type" -> "Security Type"
      "stakeholder_type" -> "Stakeholder Type"
      "series" -> "Series"
      _ -> type
    end
  end
end

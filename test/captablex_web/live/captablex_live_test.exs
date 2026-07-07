defmodule CaptablexWeb.CaptablexLiveTest do
  use CaptablexWeb.ConnCase

  import Phoenix.LiveViewTest
  import Captablex.Factory

  alias Captablex.Repo

  describe "Cap Table Dashboard" do
    test "displays dashboard with stats", %{conn: conn} do
      # Create test data
      stakeholder1 = insert(:stakeholder, name: "Alice Johnson", stakeholder_type: "individual")
      stakeholder2 = insert(:stakeholder, name: "Bob Smith", stakeholder_type: "individual")
      stock_class = insert(:stock_class, security_type: "Common", series: "Seed", shares_authorized: 10_000_000, par_value: 0.0001)

      insert(:security_issuance,
        stakeholder: stakeholder1,
        stock_class: stock_class,
        shares: 6_000_000
      )

      insert(:security_issuance,
        stakeholder: stakeholder2,
        stock_class: stock_class,
        shares: 4_000_000
      )

      {:ok, view, html} = live(conn, "/")

      # Verify stats are displayed
      assert html =~ "Cap Table Dashboard"
      assert html =~ "10,000,000"
      assert html =~ "Total Authorized"
      assert html =~ "Outstanding"

      # Verify stakeholders count
      assert has_element?(view, "p", "2")
      assert html =~ "Stakeholders"
    end

    test "displays ownership breakdown table", %{conn: conn} do
      stakeholder = insert(:stakeholder, name: "Charlie Brown", stakeholder_type: "individual")
      stock_class = insert(:stock_class, series: "Seed", shares_authorized: 1_000_000)
      insert(:security_issuance, stakeholder: stakeholder, stock_class: stock_class, shares: 500_000)

      {:ok, _view, html} = live(conn, "/")

      assert html =~ "Ownership Breakdown"
      assert html =~ "Charlie Brown"
      assert html =~ "500,000"
      assert html =~ "100.0%"
    end

    test "displays transaction history", %{conn: conn} do
      stakeholder = insert(:stakeholder, name: "Diana Prince")
      stock_class = insert(:stock_class)
      security_issuance = insert(:security_issuance, stakeholder: stakeholder, stock_class: stock_class)

      insert(:transaction,
        stakeholder: stakeholder,
        security_issuance: security_issuance,
        transaction_type: "issuance",
        quantity: 1_000_000
      )

      {:ok, view, html} = live(conn, "/")

      assert html =~ "Recent Activity"
      assert html =~ "Diana Prince"
      assert html =~ "1,000,000 shares"
      assert has_element?(view, "#transactions")
    end
  end

  describe "Add Stakeholder Form" do
    test "opens stakeholder modal when button clicked", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Click the "Add Stakeholder" button with phx-click attribute
      view |> element("button[phx-click=\"open_stakeholder_modal\"]") |> render_click()

      # Verify modal is visible by checking for the checkbox being checked
      assert has_element?(view, "#stakeholder-modal[checked]")
      assert has_element?(view, "#stakeholder-form")
    end

    test "creates stakeholder successfully", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Open the modal
      view |> element("button[phx-click=\"open_stakeholder_modal\"]") |> render_click()

      # Fill and submit the form
      assert view
             |> form("#stakeholder-form",
               stakeholder: %{
                 name: "Eve Torres",
                 stakeholder_type: "individual",
                 email: "eve@example.com",
                 tax_id: "123-45-6789"
               }
             )
             |> render_submit()

      # Verify stakeholder was created
      assert Repo.get_by(Captablex.Stakeholder, name: "Eve Torres")

      # Verify flash message
      assert render(view) =~ "Stakeholder added successfully"

      # Verify stakeholder count increased
      assert render(view) =~ "1"
    end

    test "closes modal after successful creation", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Open modal and submit form
      view |> element("button[phx-click=\"open_stakeholder_modal\"]") |> render_click()

      view
      |> form("#stakeholder-form",
        stakeholder: %{
          name: "Frank Castle",
          stakeholder_type: "institution"
        }
      )
      |> render_submit()

      # Verify modal is closed (checkbox unchecked)
      refute has_element?(view, "#stakeholder-modal[checked]")
    end

    test "shows error for invalid stakeholder data", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view |> element("button[phx-click=\"open_stakeholder_modal\"]") |> render_click()

      # Submit form with missing required field
      view
      |> form("#stakeholder-form", stakeholder: %{stakeholder_type: "individual"})
      |> render_submit()

      # Verify error message appears
      assert render(view) =~ "Failed to add stakeholder"
    end
  end

  describe "Issue Shares Form" do
    setup do
      stakeholder = insert(:stakeholder, name: "Grace Hopper")
      stock_class = insert(:stock_class, series: "Seed", security_type: "Preferred Stock")
      %{stakeholder: stakeholder, stock_class: stock_class}
    end

    test "opens issue shares modal when button clicked", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view |> element("button[phx-click=\"open_issue_shares_modal\"]") |> render_click()

      assert has_element?(view, "#issue-shares-modal[checked]")
      assert has_element?(view, "#issue-shares-form")
    end

    test "issues shares successfully", %{
      conn: conn,
      stakeholder: stakeholder,
      stock_class: stock_class
    } do
      {:ok, view, _html} = live(conn, "/")

      view |> element("button[phx-click=\"open_issue_shares_modal\"]") |> render_click()

      assert view
             |> form("#issue-shares-form",
               security: %{
                 stakeholder_id: stakeholder.id,
                 stock_class_id: stock_class.id,
                 shares: "500000",
                 price_per_share: "1.50",
                 issue_date: "2024-01-15",
                 certificate_id: "CERT-001"
               }
             )
             |> render_submit()

      # Verify security issuance was created
      security = Repo.get_by(Captablex.SecurityIssuance, certificate_id: "CERT-001")
      assert security
      assert security.shares == 500_000

      # Verify transaction was created
      assert Repo.get_by(Captablex.Transaction, security_id: security.id)

      # Verify flash message
      assert render(view) =~ "Shares issued successfully"
    end

    test "closes modal after successful share issuance", %{
      conn: conn,
      stakeholder: stakeholder,
      stock_class: stock_class
    } do
      {:ok, view, _html} = live(conn, "/")

      view |> element("button[phx-click=\"open_issue_shares_modal\"]") |> render_click()

      view
      |> form("#issue-shares-form",
        security: %{
          stakeholder_id: stakeholder.id,
          stock_class_id: stock_class.id,
          shares: "100000",
          price_per_share: "2.00",
          issue_date: "2024-02-01"
        }
      )
      |> render_submit()

      refute has_element?(view, "#issue-shares-modal[checked]")
    end

    test "shows error for invalid share data", %{conn: conn, stakeholder: stakeholder} do
      {:ok, view, _html} = live(conn, "/")

      view |> element("button[phx-click=\"open_issue_shares_modal\"]") |> render_click()

      # Submit with missing required fields
      view
      |> form("#issue-shares-form",
        security: %{
          stakeholder_id: stakeholder.id,
          shares: "100"
        }
      )
      |> render_submit()

      assert render(view) =~ "Failed to issue shares"
    end
  end
end

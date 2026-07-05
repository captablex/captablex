# Cap Table Management App - OCF Implementation Plan

## Project Overview
Building a professional cap table management application based on the Open Cap Format (OCF) standard.
Design: Sleek & modern fintech aesthetic with clean data visualizations.

## Progress Tracker

- [x] Generate Phoenix LiveView project `cap_table`
- [x] Create detailed plan.md with OCF spec requirements
- [ ] Start the server to follow along
- [ ] Replace default home page with static fintech design mockup
- [ ] Implement core OCF Ecto schemas and migrations:
  - Stakeholder schema (id, name, type, contact_info, tax_id)
  - StockClass schema (id, class_type, name, shares_authorized, par_value, price_per_share)
  - SecurityIssuance schema (id, stakeholder_id, stock_class_id, shares, issue_date, certificate_id)
  - Transaction schema (id, type, date, stakeholder_id, security_id, quantity, price)
- [ ] Create single migration file for all OCF tables
- [ ] Implement CapTable context module:
  - list_stakeholders/0
  - create_stakeholder/1
  - list_stock_classes/0
  - create_stock_class/1
  - list_securities/0
  - issue_security/1
  - calculate_ownership_breakdown/0 - returns %{stakeholder_id => {shares, percentage}}
  - list_transactions/0
  - create_transaction/1
- [ ] Create CapTableLive dashboard at lib/cap_table_web/live/cap_table_live.ex:
  - Mount: load stakeholders, stock classes, securities, ownership breakdown
  - Real-time updates via PubSub when cap table changes
  - Handle events:
    - "issue_shares" - create new security issuance
    - "add_stakeholder" - create new stakeholder
    - "add_stock_class" - create new stock class
  - Display current cap table with ownership percentages
  - Show total shares outstanding
  - Interactive ownership visualization (we'll use canvas for pie chart)
- [ ] Create cap_table_live.html.heex template:
  - Wrap content in <Layouts.app flash={@flash}>
  - Header with company overview stats
  - Stakeholders table with ownership breakdown
  - Stock classes summary
  - Recent transactions feed
  - Forms for adding stakeholders, stock classes, issuing securities
  - Canvas-based ownership pie chart with JS hook
- [ ] Create app.js hook for ownership chart visualization
  - mounted() - draw pie chart based on ownership data
  - updated() - redraw when data changes
- [ ] Update assets/css/app.css with sleek fintech theme:
  - Professional dark theme with accent colors
  - Data-focused color palette (blues, teals, grays)
  - Custom daisyUI theme config
- [ ] Update root.html.heex layout:
  - Force theme to "dark" for fintech aesthetic
  - Professional favicon/branding
- [ ] Update <Layouts.app> in layouts.ex:
  - Remove default Phoenix header
  - Add professional nav with company branding
  - Financial dashboard styling
- [ ] Seed database with sample cap table data in priv/repo/seeds.exs:
  - Founder stakeholders
  - Common and Preferred stock classes
  - Initial issuances
  - Sample transactions
- [ ] Update router.ex:
  - Remove placeholder `get "/"` route
  - Add `live "/"` pointing to CapTableLive dashboard
- [ ] Visit running app to verify functionality
- [ ] Reserve 2 steps for debugging

## OCF Core Entities
Based on Open Cap Format specification:
- **Stakeholders**: Individuals/entities holding securities
- **Stock Classes**: Common, Preferred, etc with terms
- **Securities**: Actual share issuances to stakeholders
- **Transactions**: Stock grants, transfers, exercises, conversions

## Technical Notes
- Use LiveView streams for transactions list (append mode)
- PubSub topic: "cap_table:updates" for real-time collaboration
- Calculate ownership on-the-fly from securities table
- Export to OCF JSON format (future enhancement)

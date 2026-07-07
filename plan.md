# Cap Table Management App - OCF Implementation Plan

## Project Overview
Building a professional cap table management application based on the Open Cap Format (OCF) standard.
Design: Sleek & modern fintech aesthetic with clean data visualizations.

## Progress Tracker

- [x] Generate Phoenix LiveView project `captablex`
- [x] Create detailed plan.md with OCF spec requirements
- [x] Start the server to follow along
- [x] Replace default home page with static fintech design mockup
- [x] Implement core OCF Ecto schemas and migrations
- [x] Create single migration file for all OCF tables
- [x] Implement CapTable context module
- [x] Create CaptablexLive dashboard
- [x] Create captablex_live.html.heex template
- [x] Create app.js hook for ownership chart visualization
- [x] Update assets/css/app.css with sleek fintech theme
- [x] Update root.html.heex layout
- [x] Update <Layouts.app> in layouts.ex
- [x] Seed database with sample cap table data
- [x] Update router.ex
- [x] Migrate to PostgreSQL from SQLite
- [x] Add Settings Page with 5-tab interface
- [x] Add dynamic stock class configuration
- [x] Add liquidation preference fields to stock classes
- [x] Create Waterfall context for liquidation calculations
- [x] Create WaterfallLive UI for exit scenario modeling
- [x] Add waterfall route and navigation
- [x] Add global navigation bar to all views
- [x] Update plan.md and README with waterfall documentation
- [x] Fix SecurityIssuance alias in Waterfall module
- [x] Add smart defaults and validation for seniority rank
- [x] Add PDF export functionality for dashboard and waterfall

## PDF Export Feature - Complete

### Completed:
- [x] Added `pdf_generator` dependency to mix.exs
- [x] Created `Captablex.PdfExport` context module with:
  - `generate_dashboard_pdf/0` - Generates cap table snapshot PDF
  - `generate_waterfall_pdf/1` - Generates waterfall analysis PDF
  - HTML-to-PDF conversion using wkhtmltopdf
- [x] Created JavaScript Download hook in `assets/js/download_hook.js`
- [x] Integrated Download hook into app.js
- [x] Added PDF export handlers to Dashboard LiveView
- [x] Added PDF export handlers to Waterfall LiveView
- [x] Added "Export PDF" buttons to Dashboard UI
- [x] Added "Export PDF" button to Waterfall UI (conditional on results)
- [x] Attached Download hooks to both templates for client-side downloads

### PDF Features:
- **Dashboard PDF** includes:
  - Company cap table snapshot
  - Ownership breakdown by stakeholder
  - Recent transactions
  - Generated timestamp

- **Waterfall PDF** includes:
  - Exit scenario summary
  - Distribution by stakeholder with percentages
  - Detailed breakdown by distribution type
  - Waterfall steps showing seniority flow
  - Generated timestamp

## Waterfall Feature - Complete

### Completed:
- [x] Added liquidation preference fields to stock_classes table:
  - liquidation_preference_multiple (e.g., 1.0 for 1x, 2.0 for 2x)
  - participation_type ("participating" or "non-participating")
  - seniority_rank (higher rank = paid first in waterfall)
- [x] Updated StockClass schema with new fields and validations
- [x] Updated Settings UI to configure liquidation preferences
  - Added clear warning that rank 0 = Common stock
  - Added helpful placeholder text for ranking
  - Improved helper text explaining ranking system
- [x] Created Waterfall context module with calculation engine
- [x] Created WaterfallLive UI at /waterfall with:
  - Exit value input
  - Distribution breakdown by stakeholder
  - Detailed breakdown view (collapsible)
  - Waterfall steps visualization
  - PDF export button
- [x] Added waterfall route to router
- [x] Added global navigation bar with Dashboard, Settings, Waterfall links
- [x] Updated README with comprehensive waterfall documentation
- [x] Fixed runtime error with SecurityIssuance alias

## Technical Notes
- PostgreSQL database on localhost:5432
- Liquidation waterfall follows seniority-based distribution:
  1. Pay liquidation preferences by seniority rank (highest first)
  2. If proceeds remain, participating preferred gets pro-rata share
  3. Common stock gets remaining proceeds
- Real-time updates via PubSub across all views
- Number formatting with commas for better readability
- Global navigation ensures consistent UX across all pages
- Seniority rank 0 = Common stock, 1+ = Preferred (higher = more senior)
- PDF export uses `pdf_generator` with wkhtmltopdf backend
- PDFs saved to `priv/static/downloads/` directory


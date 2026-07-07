# CapTablex

A modern cap table management system built with Phoenix LiveView, implementing the Open Cap Format (OCF) standard with advanced liquidation waterfall modeling and PDF export capabilities.


## Features

### Core Cap Table Management
- **Real-time Dashboard** - Live ownership breakdown and transaction history
- **Stakeholder Management** - Track investors, founders, employees, and advisors
- **Security Issuance** - Issue and manage equity securities
- **Transaction Tracking** - Record and monitor all equity transactions
- **OCF Compliance** - Built on Open Cap Format standard

### Advanced Analytics
- **Liquidation Waterfall Calculator** - Model exit scenarios with detailed distribution analysis
  - Seniority-based distribution logic
  - Liquidation preference calculations (1x, 2x, 3x, etc.)
  - Participation rights (participating vs non-participating preferred)
  - Pro-rata distribution calculations
  - Step-by-step waterfall visualization

### Settings & Configuration
- **5-Tab Settings Interface**:
  1. **Security Types** - Configure security classifications (Common Stock, Preferred Stock, etc.)
  2. **Stakeholder Types** - Define stakeholder categories (Individual, Institution, etc.)
  3. **Series** - Manage funding rounds (Seed, Series A, B, C, etc.)
  4. **Stock Classes** - Create stock classes from Security Type + Series combinations
  5. **Stakeholders** - Full CRUD management for all stakeholders

### PDF Export
- **Dashboard PDF Export** - Generate comprehensive cap table reports including:
  - Current ownership breakdown
  - Transaction history
  - Stakeholder details
  - Timestamp and metadata

- **Waterfall PDF Export** - Export exit scenario analysis with:
  - Distribution summary by stakeholder
  - Detailed breakdown by distribution type (liquidation preference, participation, etc.)
  - Step-by-step waterfall calculations
  - Percentages and amounts

## Technology Stack

- **Phoenix 1.8** - Modern web framework
- **LiveView** - Real-time interactive UI without JavaScript complexity
- **PostgreSQL** - Production database
- **Tailwind CSS v4** - Utility-first styling
- **daisyUI** - Pre-configured component themes
- **PubSub** - Real-time updates across sessions
- **Number** - Currency and number formatting
- **PDF Generator** - HTML-to-PDF conversion with wkhtmltopdf
[![Elixir CI](https://github.com/captablex/captablex/actions/workflows/elixir.yml/badge.svg)](https://github.com/captablex/captablex/actions/workflows/elixir.yml)

A modern cap table management system built with Phoenix LiveView for tracking equity ownership, stock classes, and transactions in real-time. Initially vibe coded via [Phoenix.new](https://phoenix.new/) and based on [Open Cap Format (OCF)](https://github.com/Open-Cap-Table-Coalition/Open-Cap-Format-OCF). YMMV.

## 🚀 Features

### Core Functionality
- **Real-time Dashboard** - Live updates across all connected browsers via Phoenix PubSub
- **Stakeholder Management** - Track individuals and institutions holding equity
- **Dynamic Stock Class Configuration** - Configure stock classes via Security Type + Series combinations
- **Settings Management** - Centralized configuration for dropdown options and stock classes
- **Share Issuance** - Issue shares with full transaction tracking
- **Ownership Breakdown** - Real-time calculation of ownership percentages
- **Transaction History** - Complete audit trail of all equity events
- **OCF Export** - Export cap table data in Open Cap Table Format (OCF 1.0.0)
- **Liquidation Waterfall Calculator** - Model exit scenarios and distribution outcomes

### Settings Page
Manage all configuration options in one place:
- **Security Types** - Define security types (e.g., "Common Stock", "Preferred Stock")
- **Stakeholder Types** - Configure stakeholder categories
- **Series** - Manage series (e.g., "Seed", "Series A", "Series B")
- **Stock Classes** - Create stock classes from Security Type + Series combinations
  - Configure liquidation preferences (1x, 2x, etc.)
  - Set participation type (participating vs. non-participating)
  - Define seniority rank for waterfall ordering
- **Stakeholders** - Full CRUD management for all stakeholders

### Waterfall Calculator (NEW!)
Model liquidation scenarios and see detailed distribution outcomes:
- **Exit Scenario Modeling** - Input total exit value to see distribution
- **Seniority-Based Distribution** - Higher seniority ranks paid first
- **Liquidation Preferences** - Automatic calculation of preference payouts
- **Participation Rights** - Participating preferred gets preference + pro-rata share
- **Step-by-Step Breakdown** - Detailed waterfall calculation steps
- **Stakeholder Summary** - See total distribution per stakeholder
- **Visual Analytics** - Clear breakdown of distribution types

#### How Liquidation Waterfall Works

The waterfall follows standard venture capital distribution logic:

1. **Liquidation Preferences (by Seniority)**
   - Stock classes are processed in descending seniority rank order
   - Higher seniority rank = paid first
   - Each class receives: `shares × price_per_share × liquidation_preference_multiple`
   - Example: 1,000,000 shares × $1.00 × 2.0x = $2,000,000 preference

2. **Participation (if applicable)**
   - After preferences are paid, participating preferred gets additional pro-rata share
   - Non-participating preferred does NOT participate further
   - Common stock always participates pro-rata in remaining proceeds

## Installation

### Prerequisites
- Elixir 1.14+ and Erlang/OTP 25+
- PostgreSQL 14+
- wkhtmltopdf (for PDF generation)
- Node.js 18+ (for asset compilation)

### Setup

1. Clone the repository and install dependencies:
```bash
git clone <repo-url>
cd captablex
mix deps.get
```

2. Configure your database in `config/dev.exs`:
```elixir
config :captablex, Captablex.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "captablex_dev",
  port: 5432
```

3. Create and migrate the database:
```bash
mix ecto.setup
```

4. Seed the database with sample data (optional):
```bash
mix run priv/repo/seeds.exs
```

5. Install wkhtmltopdf for PDF export:
```bash
# macOS
brew install wkhtmltopdf

# Ubuntu/Debian
sudo apt-get install wkhtmltopdf

# Other platforms: https://wkhtmltopdf.org/downloads.html
```

6. Start the Phoenix server:
```bash
mix phx.server
```

Now visit [`localhost:4000`](http://localhost:4000) in your browser.

## Usage

### Dashboard (`/`)
- View real-time cap table with ownership percentages
- See recent transactions
- Add new stakeholders with the "Add Stakeholder" button
- Issue shares with the "Issue Shares" button
- Export cap table to PDF with the "Export PDF" button
- Export OCF-compliant JSON with the "Export OCF" button

### Settings (`/settings`)
Configure your cap table structure across 5 tabs:

1. **Security Types Tab**
   - Add/edit/delete security classifications
   - Examples: Common Stock, Preferred Stock, Options, Warrants

2. **Stakeholder Types Tab**
   - Add/edit/delete stakeholder categories
   - Examples: Individual, Institution, Employee, Advisor

3. **Series Tab**
   - Add/edit/delete funding rounds
   - Examples: Seed, Series A, Series B, Series C

4. **Stock Classes Tab**
   - Create stock classes by combining Security Type + Series
   - Configure liquidation preferences:
     - **Liquidation Preference Multiple**: 1.0 for 1x, 2.0 for 2x, etc.
     - **Participation Type**: Participating or Non-Participating
     - **Seniority Rank**: 0 for Common, 1+ for Preferred (higher = more senior)
   - Examples: "Common Stock - Seed", "Preferred Stock - Series A"

5. **Stakeholders Tab**
   - Full CRUD management for stakeholders
   - Add name, type, email, tax ID

### Waterfall Calculator (`/waterfall`)
Model exit scenarios and see how proceeds are distributed:

1. Enter a total exit value (e.g., $10,000,000)
2. Click "Calculate" to run the waterfall
3. View distribution summary cards showing:
   - Total Exit Value
   - Total Distributed
   - Remaining Proceeds
4. See distribution by stakeholder with percentages
5. Toggle detailed breakdown to see:
   - Liquidation preferences
   - Participation amounts
   - Stock class details
6. Review waterfall steps showing seniority-based flow
7. Export the analysis to PDF with the "Export PDF" button

## Liquidation Waterfall Logic

The waterfall calculator distributes exit proceeds based on the following rules:

1. **Sort by Seniority Rank** (highest first)
   - Rank 3 = Most senior preferred
   - Rank 2 = Mid-tier preferred
   - Rank 1 = Junior preferred
   - Rank 0 = Common stock

2. **Pay Liquidation Preferences** (by rank)
   - Each tier receives its preference = shares × price × multiple
   - If insufficient proceeds, prorate within the tier
   - Move to next tier only after current tier is fully paid

3. **Participating Preferred** (if applicable)
   - After preferences are paid, participating preferred gets additional pro-rata share
   - Pro-rata based on total shares outstanding

4. **Common Stock**
   - Receives remaining proceeds pro-rata based on shares

### Example Scenario

**Setup:**
- Common Stock (rank 0): 1,000,000 shares @ $0.01 = $10,000 invested
- Preferred Series A (rank 1): 500,000 shares @ $2.00 = $1,000,000 invested
  - 1x liquidation preference, non-participating
- Preferred Series B (rank 2): 250,000 shares @ $4.00 = $1,000,000 invested
  - 2x liquidation preference, participating

**Exit Value: $5,000,000**

**Distribution:**
1. Series B gets 2x preference = $2,000,000 (rank 2)
2. Series A gets 1x preference = $1,000,000 (rank 1)
3. Remaining = $2,000,000
4. Series B participates pro-rata = ~$285,714 (250k/1.75M shares × $2M)
5. Common gets pro-rata = ~$1,142,857 (1M/1.75M shares × $2M)
6. Series A gets remaining = ~$571,429 (500k/1.75M shares × $2M)

**Final amounts:**
- Series B: $2,285,714 (45.7%)
- Series A: $1,571,429 (31.4%)
- Common: $1,142,857 (22.9%)

## PDF Export

PDFs are generated using `pdf_generator` with wkhtmltopdf backend.

### Dashboard PDF
- Includes current cap table snapshot
- Ownership breakdown by stakeholder
- Recent transaction history
- Timestamp and generation metadata

### Waterfall PDF
- Exit scenario summary
- Distribution table with percentages
- Detailed breakdown by distribution type
- Waterfall steps visualization
- Timestamp and generation metadata

### PDF Storage
- PDFs are temporarily saved to `priv/static/downloads/`
- Files are named with timestamps: `cap_table_2025-01-07.pdf`, `waterfall_2025-01-07.pdf`
- Downloads are triggered via client-side JavaScript hook

## Database Schema

### Core Tables
- `stakeholders` - Investors, founders, employees
- `stock_classes` - Security type + series combinations with liquidation preferences
- `securities` - Individual security issuances
- `transactions` - All equity transactions
- `configuration_options` - Dynamic configuration for security types, stakeholder types, series

### Stock Classes Schema
```elixir
field :security_type, :string          # "Common Stock", "Preferred Stock"
field :series, :string                 # "Seed", "Series A", "Series B"
field :shares_authorized, :integer     # Total shares authorized
field :par_value, :decimal             # Par value per share
field :price_per_share, :decimal       # Issue price per share
field :liquidation_preference_multiple, :decimal  # 1.0, 2.0, 3.0, etc.
field :participation_type, :string     # "participating" or "non-participating"
field :seniority_rank, :integer        # 0 = Common, 1+ = Preferred (higher = more senior)
```

### Unique Constraints
- Stock classes: `[:security_type, :series]` must be unique
- Example: Only one "Preferred Stock - Series A" allowed

## Configuration

### Database (PostgreSQL)
Edit `config/dev.exs` for development settings:
```elixir
config :captablex, Captablex.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "captablex_dev",
  port: 5432
```

### PDF Generation
Requires wkhtmltopdf to be installed and available in PATH.

Test installation:
```bash
wkhtmltopdf --version
```

## Development

### Run Tests
```bash
mix test
```

### Format Code
```bash
mix format
```

### Interactive Shell
```bash
iex -S mix phx.server
```

## Production Deployment

1. Set environment variables:
```bash
export DATABASE_URL=postgresql://user:pass@localhost/captablex_prod
export SECRET_KEY_BASE=$(mix phx.gen.secret)
```

2. Build release:
```bash
MIX_ENV=prod mix release
```

3. Run migrations:
```bash
_build/prod/rel/captablex/bin/captablex eval "Captablex.Release.migrate"
```

4. Start server:
```bash
_build/prod/rel/captablex/bin/captablex start
```

## Architecture Notes

### Real-time Updates
- All changes broadcast via Phoenix.PubSub
- Updates appear instantly across all connected sessions
- No page refresh required

### Number Formatting
- Uses `Number` library for currency and delimiter formatting
- Displays: `10,000,000` instead of `10000000`
- Currency: `$1,234,567.89`

### Styling
- Tailwind CSS v4 with `@import` syntax
- daisyUI for component theming
- Forced light theme in `root.html.heex`: `<html data-theme="light">`
- Custom gradient backgrounds for modern fintech aesthetic

### Global Navigation
- Persistent navigation bar across all views
- Links: Dashboard, Settings, Waterfall
- Sticky header with clean styling

## Version History

### Version 0.3.0 (Current)
- Added PDF export for dashboard and waterfall
- Integrated pdf_generator with wkhtmltopdf
- Created download hook for client-side PDF downloads
- Added export buttons to UI

### Version 0.2.0
- Added liquidation waterfall calculator
- Implemented seniority-based distribution logic
- Added liquidation preference configuration
- Improved Settings UI with smart defaults
- Fixed SecurityIssuance alias issue

### Version 0.1.0
- Initial OCF-compliant cap table
- Settings page with 5-tab interface
- Dynamic stock class configuration
- PostgreSQL migration from SQLite
- Real-time PubSub updates

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and formatting
5. Submit a pull request

## License

Copyright © 2025

## Support

For issues and feature requests, please open an issue on GitHub.


# Captablex

A modern cap table management system built with Phoenix LiveView for tracking equity ownership, stock classes, and transactions in real-time. Initially vibe coded via [Phoenix.new](https://phoenix.new/) and based on https://github.com/Open-Cap-Table-Coalition/Open-Cap-Format-OCF

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

3. **Distribution Types**
   - **Non-Participating Preferred**: Gets preference OR pro-rata share (whichever is higher)
   - **Participating Preferred**: Gets preference AND pro-rata share
   - **Common Stock**: Gets pro-rata share of remaining proceeds

**Example Scenario:**
- Exit Value: $10,000,000
- Series A Preferred: 2,000,000 shares, $1.00/share, 1.5x preference, participating, rank 2
- Common Stock: 8,000,000 shares, $0.10/share, rank 0

**Distribution:**
1. Series A gets $3,000,000 liquidation preference (2M × $1 × 1.5x)
2. $7,000,000 remains for participation
3. Series A gets additional pro-rata share: $1,400,000 (2M / 10M × $7M)
4. Common gets remaining: $5,600,000

**Total:** Series A = $4,400,000 (44%), Common = $5,600,000 (56%)

### Real-time Features
All changes broadcast instantly to connected users:
- New stakeholders created
- Stock classes added/modified
- Shares issued
- Transactions recorded
- Configuration options updated

### Transaction Types Supported
- **Issuance** - Initial share grants
- **Transfer** - Share transfers between stakeholders
- **Cancellation** - Share cancellations/buybacks
- **Exercise** - Option exercises

## 🎨 Design

Modern fintech-inspired dark theme with:
- Gradient slate backgrounds (950→900→950)
- Cyan/blue accent colors with glow effects
- Glass-morphism effects with backdrop blur
- Fully responsive layout
- Accessible modal dialogs (DaisyUI)
- Smooth transitions and hover states
- Professional tabbed interface for Settings

## 🛠️ Tech Stack

- **Phoenix Framework** 1.8+ (LiveView)
- **Elixir** 1.15+
- **PostgreSQL** - Production database
- **Tailwind CSS v4** - Styling
- **DaisyUI** - Component library
- **Phoenix PubSub** - Real-time updates
- **Ecto** - Database ORM
- **Number** - Number formatting library

## 📋 Prerequisites

- Elixir 1.15 or later
- Erlang/OTP 26 or later
- PostgreSQL 14+ (running locally or via Docker)
- Node.js (for asset compilation)

## 🚀 Getting Started

### Installation

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd captablex
   ```

2. **Install dependencies**
   ```bash
   mix deps.get
   ```

3. **Set up PostgreSQL**
   
   Make sure PostgreSQL is running locally on port 5432.
   
   Update `config/dev.exs` with your PostgreSQL credentials if needed:
   ```elixir
   config :captablex, Captablex.Repo,
     username: "postgres",
     password: "postgres",
     hostname: "localhost",
     database: "captablex_dev"
   ```

4. **Set up the database**
   ```bash
   mix ecto.setup
   ```
   
   This will:
   - Create the `captablex_dev` database
   - Run all migrations
   - Seed configuration options (security types, stakeholder types, series)
   - Seed stock classes (4 pre-configured classes)
   - Seed sample data (3 stakeholders, 3 securities, 3 transactions)

5. **Install Node.js dependencies**
   ```bash
   cd assets && npm install && cd ..
   ```

6. **Start the Phoenix server**
   ```bash
   mix phx.server
   ```

7. **Visit the app**
   
   Open [http://localhost:4000](http://localhost:4000) in your browser

## 📖 Usage

### Managing Configuration (Settings Page)

Visit [http://localhost:4000/settings](http://localhost:4000/settings) to configure:

#### Security Types
Define the types of securities your company issues:
- Common Stock
- Preferred Stock
- Options
- Warrants
- etc.

#### Series
Define funding rounds or series:
- Seed
- Series A
- Series B
- Series C
- etc.

#### Stock Classes
Create stock classes by combining Security Type + Series:
- "Common Stock - Seed"
- "Preferred Stock - Series A"
- "Common Stock - Series B"

Each stock class has:
- Shares Authorized
- Par Value (optional)
- Price Per Share (optional)
- **Liquidation Preference Multiple** (e.g., 1.0 for 1x, 2.0 for 2x)
- **Participation Type** (participating or non-participating)
- **Seniority Rank** (0 = common, higher = more senior)

#### Stakeholder Types
Configure stakeholder categories:
- Individual
- Institution
- Trust
- etc.

### Adding Stakeholders

**Option 1: From Dashboard**
1. Click **"Add Stakeholder"** button in the header
2. Fill in the form and click **"Add Stakeholder"**

**Option 2: From Settings**
1. Visit [http://localhost:4000/settings](http://localhost:4000/settings)
2. Click the **"Stakeholders"** tab
3. Click **"+ Add Stakeholder"**
4. Fill in the form:
   - **Name** (required) - Legal name of individual or entity
   - **Type** (required) - Select from configured stakeholder types
   - **Email** (optional) - Contact email
   - **Tax ID** (optional) - SSN, EIN, or other tax identifier
5. Click **"Save"**

### Creating Stock Classes

1. Visit [http://localhost:4000/settings](http://localhost:4000/settings)
2. Click the **"Stock Classes"** tab
3. Click **"+ Add Stock Class"**
4. Select Security Type and Series from dropdowns
5. Enter shares authorized, par value, and price per share
6. **Configure Liquidation Preferences:**
   - **Liquidation Preference Multiple** - Enter 1.0 for 1x, 2.0 for 2x, etc.
   - **Participation Type** - Select "Participating" or "Non-Participating"
   - **Seniority Rank** - Enter rank (0 = common, 1+ = preferred, higher = more senior)
7. Click **"Save"**

Stock classes will be displayed as: "Security Type - Series" (e.g., "Preferred Stock - Series A")

### Issuing Shares

1. Click **"Issue Shares"** button in the header (or from dashboard)
2. Fill in the form:
   - **Stakeholder** (required) - Select from existing stakeholders
   - **Stock Class** (required) - Select from configured stock classes
   - **Number of Shares** (required) - Quantity to issue
   - **Price Per Share** (required) - Price in dollars
   - **Issue Date** (required) - Date of issuance
   - **Certificate ID** (optional) - Certificate number
3. Click **"Issue Shares"**

The system automatically:
- Creates a security issuance record
- Records a transaction
- Updates ownership percentages
- Broadcasts changes to all connected users

### Running Waterfall Scenarios

1. Visit [http://localhost:4000/waterfall](http://localhost:4000/waterfall)
2. Enter the **Total Exit Value** (e.g., 10000000 for $10M exit)
3. Click **"Calculate"**
4. View results:
   - **Summary Cards** - Total exit value, total distributed, remaining proceeds
   - **Distribution Table** - Amount each stakeholder receives
   - **Detailed Breakdown** - Click "Show Breakdown" to see distribution types
   - **Waterfall Steps** - Step-by-step calculation logic

The calculator shows:
- How much each stakeholder receives
- What percentage of exit value they get
- Breakdown by distribution type (liquidation preference, participation, etc.)
- Seniority-based waterfall flow

### Exporting to OCF Format

Click **"Export OCF"** to download a JSON file containing:
- Issuer information
- All stakeholders
- All stock classes (with security_type and series)
- All securities
- Transaction summary
- Ownership summary

The export is OCF 1.0.0 compliant and can be imported into other cap table tools.

## 🧪 Testing

Run the full test suite:

```bash
mix test
```

The test suite includes:
- **Dashboard tests** - Verify stats and data display
- **Form interaction tests** - Modal opening, form submission, validation
- **Real-time update tests** - PubSub broadcasting
- **Factory pattern** - Clean test data generation

All 16 tests passing ✅

## 📁 Project Structure

```
captablex/
├── assets/              # Frontend assets
│   ├── css/            # Tailwind CSS
│   └── js/             # JavaScript (including LiveView hooks)
├── config/             # Application configuration
├── lib/
│   ├── captablex/      # Business logic and contexts
│   │   ├── accounts/   # Stakeholder management
│   │   ├── cap_table/  # Stock class management
│   │   ├── settings/   # Configuration options
│   │   ├── waterfall/  # Liquidation waterfall calculations
│   │   ├── application.ex
│   │   ├── repo.ex
│   │   └── mailer.ex
│   ├── captablex.ex    # Main context with schemas
│   └── captablex_web/  # Web interface
│       ├── components/ # Reusable components
│       ├── controllers/
│       ├── live/       # LiveView modules
│       │   ├── captablex_live.ex    # Dashboard
│       │   ├── settings_live.ex     # Settings page
│       │   └── waterfall_live.ex    # Waterfall calculator
│       ├── endpoint.ex
│       ├── router.ex
│       └── telemetry.ex
├── priv/
│   └── repo/
│       ├── migrations/          # Database migrations
│       ├── seeds.exs           # Main seed file
│       ├── seeds_config.exs    # Configuration options seed
│       └── seeds_stock_classes.exs  # Stock classes seed
└── test/               # Test suite
    ├── support/
    │   └── factory.ex  # Test data factories
    └── captablex_web/
        └── live/
            └── captablex_live_test.exs
```

## 🗄️ Database Schema

### Stakeholders
- `name` - Legal name
- `stakeholder_type` - Configured stakeholder type (e.g., "Individual", "Institution")
- `email` - Contact email
- `tax_id` - Tax identifier

### Stock Classes
- `security_type` - Security type (e.g., "Common Stock", "Preferred Stock")
- `series` - Series (e.g., "Seed", "Series A")
- `shares_authorized` - Total authorized shares
- `par_value` - Par value per share (optional)
- `price_per_share` - Current price (optional)
- `liquidation_preference_multiple` - Liquidation preference multiplier (e.g., 1.0, 2.0)
- `participation_type` - "participating" or "non-participating"
- `seniority_rank` - Waterfall priority (higher = paid first)
- **Unique constraint**: `[:security_type, :series]`

### Configuration Options
- `option_type` - Type of option ("security_type", "stakeholder_type", "series")
- `value` - Option value (e.g., "Common Stock", "Series A")
- `display_order` - Sorting order for dropdowns

### Securities (Share Issuances)
- `stakeholder_id` - Foreign key to stakeholder
- `stock_class_id` - Foreign key to stock class
- `shares` - Number of shares
- `issue_date` - Date issued
- `certificate_id` - Certificate number

### Transactions
- `stakeholder_id` - Foreign key to stakeholder
- `security_id` - Foreign key to security
- `transaction_type` - "issuance", "transfer", "cancellation", "exercise"
- `transaction_date` - Date of transaction
- `quantity` - Number of shares
- `price_per_share` - Price per share

## 🔧 Configuration

### Database (PostgreSQL)

The app uses PostgreSQL as the production database.

**Development Configuration** (`config/dev.exs`):
```elixir
config :captablex, Captablex.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "captablex_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
```

**Test Configuration** (`config/test.exs`):
```elixir
config :captablex, Captablex.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "captablex_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2
```

### Environment Variables

Set these in your `.env` file:

```bash
DATABASE_URL=ecto://postgres:postgres@localhost/captablex_dev
SECRET_KEY_BASE=<your-secret-key>
PHX_HOST=localhost
PORT=4000
```

## 🚢 Deployment

### Fly.io (Recommended)

1. **Install Fly CLI**
   ```bash
   curl -L https://fly.io/install.sh | sh
   ```

2. **Login to Fly**
   ```bash
   fly auth login
   ```

3. **Launch the app**
   ```bash
   fly launch
   ```

4. **Deploy**
   ```bash
   fly deploy
   ```

The app is configured to work seamlessly with Fly.io deployment, including PostgreSQL database provisioning.

**Note**: Deployment to platforms other than Fly.io is not currently supported.

## 🆕 Recent Changes

### Version 0.3.0 (Latest)
- ✅ **Added Liquidation Waterfall Calculator** - Model exit scenarios with detailed distribution breakdown
- ✅ **Liquidation Preferences** - Configure preference multiples, participation rights, and seniority
- ✅ **Waterfall UI** - Interactive calculator at /waterfall with step-by-step breakdown
- ✅ **Seniority-Based Distribution** - Automatic calculation following standard VC waterfall logic
- ✅ **Visual Analytics** - Clear breakdown of distribution types and stakeholder payouts

### Version 0.2.0
- ✅ **Migrated to PostgreSQL** from SQLite for production reliability
- ✅ **Added Settings Page** with 5-tab interface for configuration management
- ✅ **Dynamic Stock Classes** - Create stock classes from Security Type + Series combinations
- ✅ **Configuration Options** - Manage security types, stakeholder types, and series
- ✅ **Number Formatting** - Added `:number` library for comma-separated number display
- ✅ **Improved Schema** - Unique constraints on stock class combinations
- ✅ **Real-time Updates** - PubSub broadcasts for all configuration changes

### Migration Notes
If upgrading from SQLite:
1. Export data using OCF export feature
2. Set up PostgreSQL database
3. Run migrations: `mix ecto.migrate`
4. Run seeds: `mix run priv/repo/seeds_config.exs && mix run priv/repo/seeds_stock_classes.exs`
5. Import data via Settings page or manual insertion

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass (`mix test`)
6. Submit a pull request

## 📝 License

This project is licensed under the MIT License.

## 🙏 Acknowledgments

- Built with [Phoenix Framework](https://phoenixframework.org/)
- UI components from [DaisyUI](https://daisyui.com/)
- Icons from [Heroicons](https://heroicons.com/)
- OCF standard from [Open Cap Table Coalition](https://opencaptablecoalition.com/)
- Number formatting via [Number](https://github.com/danielberkompas/number)

## 📧 Support

For issues and questions:
- Open an issue on GitHub
- Check the [Phoenix Framework documentation](https://hexdocs.pm/phoenix/)
- Visit the [Elixir Forum](https://elixirforum.com/)


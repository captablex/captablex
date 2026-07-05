# Captablex

A modern cap table management system built with Phoenix LiveView for tracking equity ownership, stock classes, and transactions in real-time.

## 🚀 Features

### Core Functionality
- **Real-time Dashboard** - Live updates across all connected browsers via Phoenix PubSub
- **Stakeholder Management** - Track individuals and institutions holding equity
- **Stock Class Management** - Manage common stock, preferred stock, and custom classes
- **Share Issuance** - Issue shares with full transaction tracking
- **Ownership Breakdown** - Real-time calculation of ownership percentages
- **Transaction History** - Complete audit trail of all equity events
- **OCF Export** - Export cap table data in Open Cap Table Format (OCF 1.0.0)

### Real-time Features
All changes broadcast instantly to connected users:
- New stakeholders created
- Stock classes added
- Shares issued
- Transactions recorded

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

## 🛠️ Tech Stack

- **Phoenix Framework** 1.8+ (LiveView)
- **Elixir** 1.15+
- **SQLite** - Database (easily swappable for PostgreSQL)
- **Tailwind CSS v4** - Styling
- **DaisyUI** - Component library
- **Phoenix PubSub** - Real-time updates
- **Ecto** - Database ORM

## 📋 Prerequisites

- Elixir 1.15 or later
- Erlang/OTP 26 or later
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

3. **Set up the database**
   ```bash
   mix ecto.setup
   ```
   
   This will:
   - Create the database
   - Run migrations
   - Seed sample data (3 stakeholders, 2 stock classes, 3 securities)

4. **Install Node.js dependencies**
   ```bash
   cd assets && npm install && cd ..
   ```

5. **Start the Phoenix server**
   ```bash
   mix phx.server
   ```

6. **Visit the app**
   
   Open [http://localhost:4000](http://localhost:4000) in your browser

## 📖 Usage

### Adding Stakeholders

1. Click **"Add Stakeholder"** button in the header
2. Fill in the form:
   - **Name** (required) - Legal name of individual or entity
   - **Type** (required) - Individual or Institution
   - **Email** (optional) - Contact email
   - **Tax ID** (optional) - SSN, EIN, or other tax identifier
3. Click **"Add Stakeholder"**

### Issuing Shares

1. Click **"Issue Shares"** button in the header
2. Fill in the form:
   - **Stakeholder** (required) - Select from existing stakeholders
   - **Stock Class** (required) - Select stock class
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

### Exporting to OCF Format

Click **"Export OCF"** to download a JSON file containing:
- Issuer information
- All stakeholders
- All stock classes
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
│   ├── captablex/      # Business logic and schemas
│   │   ├── application.ex
│   │   ├── repo.ex
│   │   └── mailer.ex
│   ├── captablex.ex    # Context module with all schemas
│   └── captablex_web/  # Web interface
│       ├── components/ # Reusable components
│       ├── controllers/
│       ├── live/       # LiveView modules
│       │   └── captablex_live.ex
│       ├── endpoint.ex
│       ├── router.ex
│       └── telemetry.ex
├── priv/
│   └── repo/
│       ├── migrations/ # Database migrations
│       └── seeds.exs   # Seed data
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
- `stakeholder_type` - "individual" or "institution"
- `email` - Contact email
- `tax_id` - Tax identifier

### Stock Classes
- `name` - Class name (e.g., "Common Stock")
- `class_type` - "common" or "preferred"
- `shares_authorized` - Total authorized shares
- `par_value` - Par value per share
- `price_per_share` - Current price

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

### Database

By default, the app uses SQLite. To switch to PostgreSQL:

1. Update `mix.exs`:
   ```elixir
   {:ecto_sql, "~> 3.10"},
   {:postgrex, ">= 0.0.0"},
   ```

2. Update `config/dev.exs` and `config/test.exs` with PostgreSQL settings

3. Run migrations:
   ```bash
   mix ecto.create
   mix ecto.migrate
   ```

### Environment Variables

Set these in your `.env` file:

```bash
DATABASE_PATH=captablex.db  # For SQLite
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

The app is configured to work seamlessly with Fly.io deployment.

**Note**: Deployment to platforms other than Fly.io is not currently supported.

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

## 📧 Support

For issues and questions:
- Open an issue on GitHub
- Check the [Phoenix Framework documentation](https://hexdocs.pm/phoenix/)
- Visit the [Elixir Forum](https://elixirforum.com/)

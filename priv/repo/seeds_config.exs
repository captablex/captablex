# Seeds for configuration options
alias Captablex.Settings

# Security Types
Settings.create_option(%{option_type: "security_type", value: "Common Stock", display_order: 1})
Settings.create_option(%{option_type: "security_type", value: "Preferred Stock", display_order: 2})
Settings.create_option(%{option_type: "security_type", value: "Stock Options", display_order: 3})
Settings.create_option(%{option_type: "security_type", value: "Warrants", display_order: 4})

# Stakeholder Types
Settings.create_option(%{option_type: "stakeholder_type", value: "Individual", display_order: 1})
Settings.create_option(%{option_type: "stakeholder_type", value: "Institution", display_order: 2})
Settings.create_option(%{option_type: "stakeholder_type", value: "Employee", display_order: 3})
Settings.create_option(%{option_type: "stakeholder_type", value: "Advisor", display_order: 4})

# Series
Settings.create_option(%{option_type: "series", value: "Seed", display_order: 1})
Settings.create_option(%{option_type: "series", value: "Series A", display_order: 2})
Settings.create_option(%{option_type: "series", value: "Series B", display_order: 3})
Settings.create_option(%{option_type: "series", value: "Series C", display_order: 4})

IO.puts("✓ Configuration options seeded successfully!")

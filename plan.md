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

## Waterfall Feature - Complete

### Completed:
- [x] Added liquidation preference fields to stock_classes table:
  - liquidation_preference_multiple (e.g., 1.0 for 1x, 2.0 for 2x)
  - participation_type ("participating" or "non-participating")
  - seniority_rank (higher rank = paid first in waterfall)
- [x] Updated StockClass schema with new fields and validations
- [x] Updated Settings UI to configure liquidation preferences
- [x] Created Waterfall context module with calculation engine
- [x] Created WaterfallLive UI at /waterfall with:
  - Exit value input
  - Distribution breakdown by stakeholder
  - Detailed breakdown view (collapsible)
  - Waterfall steps visualization
- [x] Added waterfall route to router
- [x] Added global navigation bar with Dashboard, Settings, Waterfall links
- [x] Updated README with comprehensive waterfall documentation

## Technical Notes
- PostgreSQL database on localhost:5432
- Liquidation waterfall follows seniority-based distribution:
  1. Pay liquidation preferences by seniority rank (highest first)
  2. If proceeds remain, participating preferred gets pro-rata share
  3. Common stock gets remaining proceeds
- Real-time updates via PubSub across all views
- Number formatting with commas for better readability
- Global navigation ensures consistent UX across all pages


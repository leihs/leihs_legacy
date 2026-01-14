# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

leihs legacy is a Rails 7.2 application for equipment lending management. It uses a hybrid architecture with Rails backend, React 16 frontend components, and a separate database Rails app for schema management.

## Essential Commands

### Testing
- `bin/rspec` - Run RSpec tests (ALWAYS use `bin/rspec`, never `rspec`)
- `bin/cucumber` - Run Cucumber tests (ALWAYS use `bin/cucumber`, never `cucumber`)
- Before running tests, ALWAYS restart backend with `~/.claude/scripts/reload-backend-test.sh`

### Development Server
- `./bin/rails server` - Start Rails server
- `./bin/webpack-dev-server` - Start webpack dev server (run BEFORE rails server for faster JS compilation)

### Assets
- `./bin/precompile-and-amend-assets && git push -f` - Quick CI fix for asset changes
- `./bin/recompile-assets` - Recompile assets locally

### Database
- `RAILS_ENV=test source ./database/bin/db-set-env` - Set database environment variables
- Database is in separate `/database/` Rails app with own migrations

## Architecture

### Two-App Structure
- **Main app** (`/app/`) - Rails controllers, models, views, React components
- **Database app** (`/database/`) - Separate Rails app with migrations, schema, database-layer specs
- Main Gemfile eval's `database/Gemfile` to combine dependencies

### Frontend Integration
- **Hybrid approach**: Rails HAML views + React 16 components via `react-rails` gem
- Controllers set `@props` hash, views render via `react_component('ComponentName', @props)`
- React components in `/app/assets/javascripts/components/` (JSX files)
- Webpacker 5.0 for JS bundling
- CoffeeScript for legacy JavaScript in `/app/assets/javascripts/`

### Models & Controllers
- **ApplicationRecord** base class for all models
- **Concerns** pattern heavily used (10 model concerns in `/app/models/concerns/`)
- **Presenter pattern** via `Presentoir` gem for JSON/HTML dual responses
- **Namespaced controllers**: `Manage::*` (inventory pool management), `Admin::*` (legacy admin)
- **Filter2 pattern**: Custom filtering system `Model.filter2(params)` for complex queries

### Testing Architecture
- **RSpec** for unit/integration tests (models, features)
- **Cucumber** for acceptance tests with Selenium WebDriver + Firefox
- **Database cleaner** with truncation strategy
- **factory_bot** for test fixtures
- Database layer has separate specs in `/database/spec/`

### Key Domain Models
- **Contract** - Rental agreements (open/closed states)
- **Reservation** - Individual item bookings within contracts
- **Item** - Physical inventory items
- **Model** - Item templates/types
- **InventoryPool** - Location/department managing equipment
- **User** - Users with delegations and role-based access
- **Visit** - Hand-over/take-back events
- **Option** - Non-inventory items (consumables, accessories)

### Authentication & Authorization
- Token-based via `UserSession` model (cookies: `LEIHS_USER_SESSION`)
- Delegation support (users acting on behalf of others)
- Roles: `:inventory_manager`, `:lending_manager`, `:group_manager`
- Concerns: `UserSessionController`, `AntiCsrf`

### Localization
- GetText via `gettext_i18n_rails` gem
- 6 locales: de-CH, en-US, en-GB, fr-CH, gsw-CH, es
- I18n formats in `/app/assets/javascripts/i18n/formats/`

## Common Workflows

### Running Single Test
```bash
bin/rspec spec/models/contract_spec.rb:5  # Single example at line 5
bin/cucumber features/manage/order/contract.feature:42  # Single scenario at line 42
```

### Adding React Component
1. Create component in `/app/assets/javascripts/components/`
2. Set `@props` in controller action
3. Render in HAML view: `= react_component('YourComponent', @props)`

### Database Changes
1. Create migration in `/database/db/migrate/`
2. Run `cd database && ./bin/rails db:migrate`
3. Commit both migration and `db/structure.sql`

## Code Patterns

### Presenter Usage
```ruby
# Controller
def show
  respond_with_presenter(UserPresenter.new(@user))
end
```

### Filter2 Pattern
```ruby
# Model
scope :filter2, -> (params) do
  # Complex filtering logic
end

# Controller
@items = Item.filter2(params).paginate(page: params[:page])
```

### React-Rails Integration
```ruby
# Controller
@props = {
  inventory_pool_id: current_inventory_pool.id,
  user_id: current_user.id,
  items: items.map(&:to_json)
}

# View (HAML)
= react_component('ItemsIndex', @props)
```

## Important Notes

- **NEVER commit automatically** - always ask first
- When working on assets, may need to run precompile script for CI
- Database is PostgreSQL (default port 5415)
- Firefox + geckodriver managed via asdf for Cucumber tests
- Main branch is `master` (not `main`)

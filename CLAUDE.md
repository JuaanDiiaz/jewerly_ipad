# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Development Commands

```bash
flutter run                    # Run on connected device/simulator
flutter build ios              # Build for iOS (iPad primary target)
flutter build apk              # Build for Android
flutter analyze                # Static analysis
flutter pub get                # Install dependencies
flutter test                   # Run tests (`flutter test test/widget_test.dart` for a single file)
```

Package name is `p_a_jewerly` — use it for all internal imports (e.g. `package:p_a_jewerly/...`).

## Architecture Overview

**Platform:** Flutter app for iPad (iOS primary), tablet-oriented layout

**Backend:** Custom REST API (repo: [jewerly_backend](https://github.com/JuaanDiiaz/jewerly_backend)), ASP.NET Core + EF Core + MySQL. Responses serialized with `ReferenceHandler.Preserve` may arrive wrapped as `{"$id":"...","$values":[...]}` — `ApiService._handleResponse` unwraps `$values` automatically, so providers receive a plain list/map.

**Pattern:** Provider state management (`provider` package) + layered architecture. No named routes — `HomeScreen` swaps `_currentWidget` via `setState`.

**Structure:**
- `lib/main.dart` - Entry point; dotenv load + `MultiProvider` registering every provider
- `lib/config/environment.dart` - Static `Environment` class resolving the base URL
- `lib/models/` - Data models (`fromJson`/`toJson`) matching backend C# entities
- `lib/providers/` - One provider per resource, all extending `ChangeNotifier`
- `lib/infraestructure/services/api_service.dart` - `ApiService` singleton (note the "infraestructure" spelling) with custom exceptions
- `lib/screens/<Feature>/` - One directory per feature (Sales, Inventory, Products, Customers, Purchases, Prices, Payments, Suppliers, Admin screens…)
- `lib/widgets/base_screen.dart` - `BaseScreen`, `EmptyState`, `ItemCard`, `FormDialog`, `confirmDelete` — the standard building blocks for CRUD screens
- `lib/theme/app_theme.dart` - Gold/purple/cream "luxury" palette; use its token constants, not ad-hoc colors
- `lib/components/` - Sidebar, bottom bar

## Navigation

`HomeScreen` builds a `ModernSidebar` (`lib/widgets/modern_sidebar.dart`, custom widget — not the `collapsible_sidebar` package, though that dep is still in pubspec) with nested `MenuItem`s pointing to screens. The sidebar only renders when screen width > 800; clicking a `MenuItem` swaps the content pane.

## API Configuration

Base URL resolves through `Environment.baseUrl` (lib/config/environment.dart):
1. `shared_preferences` key `api_base_url` (settable at runtime from the Settings screen via `ApiConfigProvider`)
2. Fallback default: `http://localhost:3000/api/v1`

`.env` (bundled, loaded by dotenv at startup) defines `API_BASE_URL` and `ENVIRONMENT` but `Environment` no longer reads `API_BASE_URL` from it — the SharedPreferences value wins. Keep both `.env` and `.env.example` in sync if defaults change.

## Available Endpoints

| Resource | Endpoint | Methods |
|----------|----------|---------|
| Products | `/api/Product` | GET, POST, PUT/{id}, DELETE/{id} |
| Customers | `/api/Customer` | GET, POST, PUT/{id}, DELETE/{id} |
| Inventory | `/api/Inventory` | GET, POST, PUT/{id}, DELETE/{id} |
| Inventory Movements | `/api/InventoryMovement` | GET |
| Sales Orders | `/api/SalesOrderHeader` | GET (with `from_date`/`to_date` params), POST, PUT/{id}, DELETE/{id} |
| Sales Details | `/api/SalesOrderDetail` | GET, POST, PUT/{id}, DELETE/{id} |
| Purchase Orders | `/api/PurchaseOrderHeader` | GET, POST, PUT/{id}, DELETE/{id} |
| Purchase Details | `/api/PurchaseOrderDetail` | GET, POST, PUT/{id}, DELETE/{id} |
| Price Lists | `/api/PriceList` | GET |
| Price List Details | `/api/PriceListDetail` | GET, POST, PUT/{id}, DELETE/{id} |
| Categories | `/api/Category` | GET, POST, PUT/{id}, DELETE/{id} |
| Warehouses | `/api/Warehouse` | GET, POST, PUT/{id}, DELETE/{id} |
| Customer Payments | `/api/CustomerPayment` | GET, POST, DELETE/{id} |
| Suppliers | `/api/Supplier` | GET, POST, PUT/{id}, DELETE/{id} |
| Supplier Products | `/api/SupplierProduct` | GET, POST, PUT/{id}, DELETE/{id} |
| Product Categories | `/api/ProductCategory` | GET |
| Product Images | `/api/ProductImage` | GET, POST, DELETE/{id} |
| Payment Methods | `/api/PaymentMethod` | GET, POST, PUT/{id}, DELETE/{id} |
| Sales Tax | `/api/SalesTaxDetail` | GET, POST, PUT/{id}, DELETE/{id} |

**Action endpoints:** `/api/SalesOrderHeader/CompleteSale` (checkout, creates header + details in one call, see `SalesProvider.checkout`) and `/api/PurchaseOrderHeader/{orderId}/Complete` (see `PurchaseOrderProvider`).

## Checkout Flow

Creating a sale is a **single POST** to `/api/SalesOrderHeader/CompleteSale` with `{customerId, paymentMethodId, salespersonName, warehouseId, saleDate (yyyy-MM-dd), items: [{productId, quantity, unitPrice}]}`. The legacy two-step (POST header, then POST each detail to `/api/SalesOrderDetail`) is no longer used by checkout.

## Provider Conventions

- CRUD methods return `bool` for success/failure; fetch methods set `errorCode` state
- All expose `isLoading` (and often `isSaving`), `error`, data lists
- Consumed via `Consumer<T>` / `context.watch<T>()`
- Query params use snake_case (`warehouse_id`, `item_id`, `from_date`, `to_date`)
- Field mapping between app names and backend names lives in providers (backend POST `/Product` expects `{description, picture}`)

## Product Images

Product images go to **Cloudinary** (unsigned upload preset hardcoded in `product_provider.dart`) and the resulting URL is stored in `Product.picture` / `/ProductImage` records. Local paths that don't start with `http` are uploaded first in `createProduct`/`updateProduct`.

## Error Handling & UI Patterns

- `BaseScreen` handles loading spinner / full-screen error with retry / content in one scaffold; use `EmptyState` for no-data and `ItemCard` + `confirmDelete` + `FormDialog` for list CRUD
- `errorSnackBar(message)` / `successSnackBar(message)` for feedback
- Custom exceptions from `ApiService`: `ApiException`, `UnauthorizedException`, `ForbiddenException`, `NotFoundException`, `ServerException`

## Notes

- The repo name is misspelled ("jewerly") and the directory is `lib/infraestructure/` — keep both as-is when writing imports
- Only test: `test/widget_test.dart` (default smoke test); no existing test conventions to follow
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Development Commands

```bash
flutter run                    # Run on connected device/simulator
flutter build ios              # Build for iOS
flutter build apk              # Build for Android
flutter analyze                # Static analysis
flutter pub get                # Install dependencies
```

## Architecture Overview

**Platform:** Flutter app for iPad (iOS primary target)

**Backend:** ASP.NET Core API (.NET 8/9) with Entity Framework Core + MySQL
**Architecture Pattern:** Provider-based state management with layered architecture

**Structure:**
- `lib/main.dart` - App entry point, initializes dotenv and providers
- `lib/config/` - Environment configuration (`Environment` class with dotenv)
- `lib/screens/` - Feature screens (Sales, Inventory, Products, Customers, Purchases, Prices, Settings)
- `lib/models/` - Data models matching backend C# entities
- `lib/providers/` - State management (ProductProvider, CustomerProvider, InventoryProvider, SalesProvider, LoadingProvider)
- `lib/infraestructure/services/` - API layer (`ApiService` singleton with custom exceptions)
- `lib/widgets/` - Reusable UI components (LoadingOverlay, AppErrorWidget, snackBars)
- `lib/components/` - App-specific components (sidebar, bottom bar)

**Navigation:** Collapsible sidebar pattern (`collapsible_sidebar` package) with nested sub-items

## API Integration

**Base URL:** Loaded from `.env` file (e.g., `http://localhost:5000/api/`)
**CORS:** Enabled on backend for all origins

### Available Endpoints

| Resource | Endpoint | Methods |
|----------|----------|---------|
| Products | `/api/Product` | GET, POST, PUT/{id}, DELETE/{id} |
| Customers | `/api/Customer` | GET, POST, PUT/{id}, DELETE/{id} |
| Inventory | `/api/Inventory` | GET, POST, PUT/{id}, DELETE/{id} |
| Sales Orders | `/api/SalesOrderHeader` | GET, POST, PUT/{id}, DELETE/{id} |
| Sales Details | `/api/SalesOrderDetail` | GET, POST, PUT/{id}, DELETE/{id} |
| Purchase Orders | `/api/PurchaseOrderHeader` | GET, POST, PUT/{id}, DELETE/{id} |
| Price Lists | `/api/PriceList` | GET, POST, PUT/{id}, DELETE/{id} |
| Categories | `/api/Category` | GET, POST, PUT/{id}, DELETE/{id} |
| Warehouses | `/api/Warehouse` | GET, POST, PUT/{id}, DELETE/{id} |
| Inventory Movements | `/api/InventoryMovement` | GET, POST, PUT/{id}, DELETE/{id} |
| Customer Payments | `/api/CustomerPayment` | GET, POST, PUT/{id}, DELETE/{id} |

### Backend Model Fields

**Product:** `id`, `description`
**Customer:** `id`, `name`, `email`, `phone`, `address`, `city`, `postalCode`, `country`
**SalesOrderHeader:** `id`, `saleDate`, `customerId`, `total`, `paymentMethodId`, `notes`
**SalesOrderDetail:** `id`, `salesOrderId`, `productId`, `quantity`, `unitPrice`, `total`
**Inventory:** `id`, `warehouseId`, `productId`, `location`, `weight`
**Warehouse:** `id`, `name`
**Category:** `id`, `idParentCategory`, `categoryNumber`, `description`, `extraInformation`

### Checkout Flow

Creating a sale requires two steps:
1. POST to `/api/SalesOrderHeader` with customer, payment, total
2. POST to `/api/SalesOrderDetail` for each item with `salesOrderId`, `productId`, `quantity`, `unitPrice`

## State Management

- Providers extend `ChangeNotifier` and are consumed via `Consumer<T>` or `context.watch<T>()`
- All providers expose: `isLoading`, `error`, and data lists
- CRUD operations return `bool` for success/failure

## Error Handling

- Use `AppErrorWidget` for full-screen errors with retry
- Use `errorSnackBar(message)` and `successSnackBar(message)` for feedback
- Custom exceptions: `ApiException`, `UnauthorizedException`, `ForbiddenException`, `NotFoundException`, `ServerException`

## Environment Configuration

- `.env` file (not committed) contains `API_BASE_URL` and `ENVIRONMENT`
- `.env.example` is committed as template
- Access via `Environment.baseUrl`, `Environment.isDevelopment`, etc.

## Form Validation

- Customer form: name (min 2 chars), email (regex), phone (8-15 digits)
- Product form: name/description validation
- All forms use `GlobalKey<FormState>` with validator functions

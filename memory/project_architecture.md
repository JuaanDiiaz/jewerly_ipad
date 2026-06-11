---
name: project_jewelry_ipad
description: Jewelry inventory management iPad app with Flutter frontend and .NET backend
type: project
---

**App**: Flutter iPad app for jewelry inventory management
**Backend**: ASP.NET Core API + MySQL (local at http://localhost:5000/api/)

**Key Features Implemented**:
- Sales with multi-payment support, inventory movements (OUT type)
- Purchases with inventory movements (IN type) on completion
- Product images via Cloudinary
- Physical inventory count
- Warehouse-based inventory filtering
- Sales history with payment tracking

**Optimization Done (2026-04-07)**:
- Created `lib/widgets/base_screen.dart` with reusable components:
  - `BaseScreen` - scaffold with loading/error/empty state handling
  - `EmptyState` - reusable empty placeholder with icon, title, subtitle
  - `FormDialog` - generic single-field CRUD dialog
  - `confirmDelete()` - reusable confirmation dialog function
- Refactored screens to use new base components:
  - WarehousesScreen, CategoriesScreen, PaymentMethodsScreen, SuppliersScreen

**Pending Refactoring** (lower priority, similar pattern):
- PricesMainScreen, SalesTaxScreen, SupplierProductsScreen, SettingsScreen
- invetory_main_screen.dart, customers_main_screen.dart, products_main_screen.dart
- purchases_main_screen.dart, sales_list_screen.dart, sale_screen.dart
- customer_payments_screen.dart, inventory_movements_screen.dart
- home_screen.dart

**Branch**: feature/complete-api-integration

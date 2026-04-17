# J&A Jewelry Inventory Management

A Flutter iPad application for managing jewelry inventory, sales, purchases, and customer relationships.

## Features

- **Products Management** - Catalog and manage jewelry products with images
- **Sales** - Create sales orders with cart functionality, customer selection, and payment methods
- **Purchases** - Manage purchase orders and track inventory restocking
- **Inventory** - Real-time inventory tracking across multiple warehouses with physical count support
- **Customers** - Customer management with payment tracking
- **Categories** - Organize products by categories
- **Warehouses** - Multi-warehouse inventory management
- **Price Lists** - Flexible pricing management

## Requirements

- Flutter SDK 3.x or later
- iOS 12.0 or later (iPad optimized)
- Android 5.0+ (tablet recommended)

## Setup

1. **Install dependencies**
   ```bash
   flutter pub get
   ```

2. **Configure API endpoint**

   Create a `.env` file in the root directory:
   ```
   API_BASE_URL=http://localhost:5000/api
   ENVIRONMENT=development
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## Architecture

- **State Management**: Provider pattern
- **API Layer**: Custom ApiService with error handling
- **Navigation**: Collapsible sidebar with nested menu items

## Project Structure

```
lib/
├── config/              # Environment configuration
├── components/          # App-specific components (sidebar, bottom bar)
├── infraestructure/     # API services
├── models/              # Data models
├── providers/           # State management
├── screens/             # Feature screens
├── widgets/             # Reusable UI components
└── main.dart            # App entry point
```

## Backend

This app requires the J&A Jewelry Backend API. See [jewerly_backend](https://github.com/JuaanDiiaz/jewerly_backend) for more details.

## License

Private - J&A Jewelry

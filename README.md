# Vishnu Enterprises - Inventory & Invoice Management System

A Flutter application for Enterprise Inventory Management, Stock Transfer, and Invoicing integrated with Supabase backend.

---

## 🌟 Key Features

- **Role-Based Workflows**:
  - **Admin Access**: Manage warehouses, products, customers, stock transfers across locations, and general system settings.
  - **Billing Staff Access**: Quickly handle stock-in operations, dynamic barcode scanning via camera, customer directory, and generate invoices.
- **Dynamic Barcode Scanning**:
  - Scan product barcodes directly using mobile camera or enter SKUs manually.
  - Query backend database for stock verification.
- **Stock Management & Transfers**:
  - Real-time stock level monitoring per warehouse.
  - Inter-warehouse stock transfers.
- **Haptic Interactions**:
  - Tactile feedback across navigation, button taps, and stock updates.
- **Supabase Integration**:
  - Persistent cloud storage for profiles, products, stock entries, customers, invoices, and warehouses.

---

## 🚀 Getting Started

### 1. Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.24.0 or higher recommended)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- A Supabase account and project

### 2. Environment Setup

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```
2. Open `.env` and fill in your Supabase credentials:
   ```env
   SUPABASE_URL=https://your-supabase-id.supabase.co
   SUPABASE_ANON_KEY=your-actual-supabase-anon-key
   ```

### 3. Database Migration

Run your SQL migrations in your Supabase SQL Editor to set up tables:
- `profiles`
- `warehouses`
- `products`
- `warehouse_stock`
- `stock_entries`
- `stock_entry_items`
- `customers`
- `invoices`
- `invoice_items`

### 4. Installation & Running

```bash
# Get dependencies
flutter pub get

# Run on connected device or emulator
flutter run
```

---

## 🔒 Security & Version Control

> **Important**: Never commit `.env` or sensitive credentials to version control. The `.gitignore` file is configured to exclude sensitive environment variables and build artifacts.

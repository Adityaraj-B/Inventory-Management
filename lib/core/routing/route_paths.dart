class RoutePaths {
  static const String login = '/login';
  static const String home = '/home';
  static const String stock = '/stock';
  static const String addStock = '/stock/add';
  static const String editStock = '/stock/edit';
  static const String stockHistory = '/stock/history';
  static const String receiveStock = '/stock/receive';
  static const String customers = '/customers';
  static const String customerDetail = '/customers/detail';
  static const String customerTransactions = '/customers/transactions';
  static const String customerPayments = '/customers/payments';
  static const String customerLedger = '/customers/ledger';
  static const String managePayment = '/customers/manage-payment';
  static const String warehouses = '/warehouses';
  static const String warehouseDetail = '/warehouses/detail';
  static const String accessDenied = '/access-denied';

  // Billing Staff Routes
  static const String billingStaffHome = '/billing-staff/home';
  static const String billingScan = '/billing-staff/home/billing/scan';
  static const String billingManualSelect =
      '/billing-staff/home/billing/manual-select';
  static const String billingReview = '/billing-staff/home/billing/review';
  static const String billingGenerated =
      '/billing-staff/home/billing/generated';
  static const String billingSupplierInvoices =
      '/billing-staff/supplier-invoices';
  static const String billingStockTransfer = '/billing-staff/stock-transfer';
  static const String selectSupplier = '/billing-staff/select-supplier';
  static const String createSupplierInvoice =
      '/billing-staff/create-supplier-invoice';
}

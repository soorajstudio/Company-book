# Company Book 🏢

A Flutter financial management application and corporate ledger designed specifically for companies, businesses, and sole proprietors. Built upon the architecture of Home Book, but tailored for corporate financial management with **strict single-member exclusive book entry**.

---

## 🔒 Key Principle: Single-Member Exclusive Entry
Unlike multi-user or family-shared applications where multiple users can join with an invite code:
- **Strict 1-Member Capacity**: Each Company Book is private and bound exclusively to **one authorized member** (the Founder / Sole Proprietor / Financial Director).
- **No Multi-User Joining**: Additional members cannot enter or register into an existing company book. Attempting to enter with a book code rejects any auxiliary user.
- **Audited Ledger Entries**: Every company entry (revenue or expense) is stamped and attributed to the sole authorized controller.

---

## 🌟 Key Features

### 1. Executive Dashboard & P&L Overview
- **Real-Time Cashflow**: Net operating profit, monthly revenue, and expenditure calculations.
- **Visual Analytics**: Interactive 6-month comparative cashflow bar charts powered by `fl_chart`.
- **Category Allocation**: Live visual progress indicators showing expenditure distribution by corporate department.
- **Month-by-Month Browsing**: Switch months with a single tap to audit historical performance.

### 2. Company Ledger & Entry Recording
- **Corporate Categories**: Pre-seeded with professional business categories:
  - **Revenue**: Client Invoices & Fees, Product & Sales, Consulting & Services, Recurring Retainers, Investment & Interest, Other Revenue.
  - **Expenses**: Payroll & Salaries, Office Rent & Facilities, SaaS & Cloud Services, Marketing & Advertising, Equipment & Hardware, Travel & Hospitality, Legal & Taxes, Utilities, Office Supplies, Operating Expenses.
- **Search & Filters**: Instant search by invoice number, vendor, client, or category, with filters for Revenue, Expenses, or All.
- **Entry Management**: Add, view, edit, and delete company entries with invoice/reference notes.

### 3. Financial Statements & PDF Export
- **PDF Generation**: Generates company financial reports using `pdf` and `printing`.
- **Itemized Ledger**: Includes date, category, description, invoice reference, and amount.
- **Flexible Ranges**: Pre-configured periods (This Month, Last Month, Year-to-Date) or custom date pickers.
- **Export & Print**: Direct printing or saving to PDF for accountants, investors, or tax reporting.

### 4. Company & Single-Member Security
- Displays company profile, registration code, and sole controller credentials.
- Security indicator confirming: **"Capacity: 1 / 1 Member Active (LOCKED - Single Member Exclusive)"**.

### 5. Administrative Console
- Dedicated administrator overview for managing company book categories, monitoring access sessions, and reviewing device activity.

---

## 🛠️ Tech Stack & Dependencies
- **Flutter**: 3.41+
- **Supabase**: `supabase_flutter: ^2.5.6` (Cloud database, authentication & session management)
- **Charts**: `fl_chart: ^0.69.0`
- **PDF Generation & Printing**: `pdf: ^3.10.8`, `printing: ^5.13.1`
- **Formatting**: `intl: ^0.19.0`
- **Device Information**: `device_info_plus: ^10.1.0`

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK installed (`flutter --version`)
- Connected device, emulator, or Windows desktop target

### Installation & Run
```bash
# Get dependencies
flutter pub get

# Run tests
flutter test

# Run application
flutter run
```

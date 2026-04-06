# FinEase 💸

**FinEase** is a modern, intuitive, and privacy-first personal finance tracking application built natively for iOS. Easily manage your daily transactions, monitor your savings goals, and gain valuable insights into your spending habits—all powered seamlessly on-device using SwiftUI and SwiftData.

## ✨ Features

*   **📱 Smart Dashboard**: Get a quick, high-level overview of your current balance, monthly cash flow, and recent activities.
*   **💳 Transaction Management**: Add, edit, or delete income and expense records with ease. Support for full-screen entry forms to capture details cleanly.
*   **🏷️ Custom Categories**: Organize your spending your way. Use built-in categories or create fully custom ones with unique names and icons.
*   **🎯 Savings Goals**: Set financial targets (like a vacation or an emergency fund) and track your progress through beautiful visual rings.
*   **📊 Insights & Analytics**: Understand where your money goes. View monthly spending trends and category breakdowns to make informed financial decisions.
*   **🔔 Daily Reminders**: Never forget to log your daily expenses with customizable local notifications (defaults to 8 PM).
*   **📤 Data Portability**: Export all your transaction data instantly to a CSV file for external use, backup, or accountant review.
*   **🔒 Privacy First**: 100% offline. All your financial data is stored securely on your device utilizing SwiftData.

## 🛠 Tech Stack

*   **Framework**: [SwiftUI](https://developer.apple.com/xcode/swiftui/) for a declarative, reactive user interface.
*   **Database**: [SwiftData](https://developer.apple.com/documentation/swiftdata) for fast, safe, and entirely local data persistence.
*   **Architecture**: Feature-based modular structure separating Views, Models, and reusable Components.
*   **Platform**: iOS 17.0+ 

## 📂 Project Structure

```text
FinEase/
├── Models/           # Core SwiftData models (TransactionRecord, SavingsGoalRecord, FinanceCategory, etc.)
├── Features/         # Grouped by main app tabs and flows
│   ├── Dashboard/    # Home screen overview
│   ├── Transactions/ # Transaction lists, filters, and forms
│   ├── Goals/        # Goal creation and progress tracking
│   ├── Insights/     # Spending analytics and charts
│   └── Profile/      # Settings, CSV Export, and Notification management
├── Components/       # Reusable UI elements (Buttons, MetricCards, HeroCards, Rows)
├── Extensions/       # Swift standard library extensions (Formatting, Dates)
└── Assets/           # App icons, custom colors, and images

```

## Getting Started
Requirements
macOS 14+ (Sonoma or later)
Xcode 15.0 or later
iOS 17.0+ Simulator or physical device

## Installation
1.Clone the repository:
git clone https://github.com/iPraveenShrivastav/FinEase    
2.Open FinEase.xcodeproj in Xcode.  
3.Wait for Xcode to resolve any Swift Package Manager dependencies.  
4.Select your target simulator or physically connected iOS device.  
5.Hit Cmd + R or click the Run button to build and launch the app.  


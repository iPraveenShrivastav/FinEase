import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query(sort: \TransactionRecord.date, order: .reverse) private var transactions: [TransactionRecord]
    @AppStorage("finEaseDarkModeEnabled") private var isDarkModeEnabled = false
    @State private var notificationManager = NotificationManager.shared

    var body: some View {
        ZStack {
            FinanceScreenBackground()

            List {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundStyle(FinanceTheme.accent)
                            .background(Circle().fill(.background))
                            .overlay(Circle().stroke(FinanceTheme.accent.opacity(0.3), lineWidth: 2))
                            .shadow(color: FinanceTheme.accent.opacity(0.2), radius: 10, y: 4)

                        VStack(spacing: 4) {
                            Text("Guest User")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.primary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .listRowBackground(Color.clear)
                }

                Section("Preferences") {
                    Toggle(isOn: $isDarkModeEnabled) {
                        Label("Dark Mode", systemImage: "moon.fill")
                            .foregroundStyle(.primary)
                    }
                    .tint(FinanceTheme.accent)

                    Toggle(isOn: Bindable(notificationManager).isDailyReminderEnabled) {
                        Label("Daily Reminder (8 PM)", systemImage: "bell.badge.fill")
                            .foregroundStyle(.primary)
                    }
                    .onChange(of: notificationManager.isDailyReminderEnabled) { _, newValue in
                        Task {
                            await notificationManager.toggleDailyReminder(enable: newValue)
                        }
                    }
                    .tint(FinanceTheme.accent)
                }

                Section("Data & Export") {
                    ShareLink(item: csvExportURL, subject: Text("FinEase Data Export"), message: Text("Here is my transaction data from FinEase.")) {
                        Label("Export Data to CSV", systemImage: "arrow.up.doc.fill")
                            .foregroundStyle(FinanceTheme.accent)
                    }
                }

                Section("About") {
                    HStack {
                        Label("Version", systemImage: "info.circle.fill")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Profile")
    }

    private var csvExportURL: URL {
        var csvString = "Timestamp,Category,Amount,Currency\n"
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        for transaction in transactions {
            let dateString = formatter.string(from: transaction.date)
            let category = transaction.displayCategoryName
            let sign = transaction.type == .expense ? "-" : "+"
            let amountStr = String(format: "%@%.2f", sign, transaction.amount)
            let currency = "INR"
            
            let row = "\"\(dateString)\",\"\(category)\",\"\(amountStr)\",\"\(currency)\"\n"
            csvString.append(row)
        }
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("FinEase_Export.csv")
        try? csvString.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}

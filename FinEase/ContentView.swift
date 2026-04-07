import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("finEaseDarkModeEnabled") private var isDarkModeEnabled = false

    var body: some View {
        TabView {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }

            NavigationStack {
                TransactionsView()
            }
            .tabItem {
                Label("Transactions", systemImage: "list.bullet.rectangle.portrait")
            }

            NavigationStack {
                GoalView()
            }
            .tabItem {
                Label("Goal", systemImage: "target")
            }

            NavigationStack {
                InsightsView()
            }
            .tabItem {
                Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
            }
            
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle.fill")
            }
        }
        .tint(FinanceTheme.accent)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(.background, for: .tabBar)
        .preferredColorScheme(isDarkModeEnabled ? .dark : .light)
        .onAppear {
            Task {
                await NotificationManager.shared.checkAuthorizationStatus()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [TransactionRecord.self, SavingsGoalRecord.self, CustomCategoryRecord.self], inMemory: true)
}

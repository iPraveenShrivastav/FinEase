import SwiftUI
import SwiftData

struct ContentView: View {
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
        .toolbarBackground(Color.white.opacity(0.98), for: .tabBar)
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

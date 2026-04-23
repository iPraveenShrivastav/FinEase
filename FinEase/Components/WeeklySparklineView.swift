import SwiftUI
import Charts

struct WeeklySparklineView: View {
    let data: [DailyExpensePoint]
    @State private var animateChart = false

    private var maxAmount: Double {
        data.map(\.amount).max() ?? 1
    }

    private var totalWeek: Double {
        data.reduce(0) { $0 + $1.amount }
    }

    private var trend: Double {
        guard data.count >= 2 else { return 0 }
        let mid = data.count / 2
        let firstHalf = data.prefix(mid).reduce(0) { $0 + $1.amount }
        let secondHalf = data.suffix(mid).reduce(0) { $0 + $1.amount }
        guard firstHalf > 0 else { return 0 }
        return ((secondHalf - firstHalf) / firstHalf) * 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("7-Day Spending")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))

                    Text(totalWeek.asCurrency())
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                }

                Spacer()

                if data.count >= 2 {
                    HStack(spacing: 3) {
                        Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption2.weight(.black))
                        Text("\(abs(trend), specifier: "%.0f")%")
                            .font(.caption.weight(.bold))
                    }
                    .foregroundStyle(trend >= 0 ? Color.red.opacity(0.9) : Color.green.opacity(0.9))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
                    .environment(\.colorScheme, .dark)
                }
            }

            if data.isEmpty {
                Text("Log expenses to see your trend")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
            } else {
                Chart(data) { point in
                    AreaMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Amount", animateChart ? point.amount : 0)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .white.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Amount", animateChart ? point.amount : 0)
                    )
                    .foregroundStyle(.white.opacity(0.85))
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .interpolationMethod(.catmullRom)
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 50)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                        animateChart = true
                    }
                }
            }

            // Day labels
            if !data.isEmpty {
                HStack {
                    ForEach(data) { point in
                        Text(point.date.formatted(.dateTime.weekday(.narrow)))
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Weekly spending sparkline")
        .accessibilityValue("Total \(totalWeek.asCurrency()) over 7 days, trend \(trend >= 0 ? "up" : "down") \(abs(trend), specifier: "%.0f") percent")
    }
}

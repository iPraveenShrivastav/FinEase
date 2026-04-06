import SwiftUI
import SwiftData

struct CategorySelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedFinanceCategory: FinanceCategory?
    @Binding var selectedCustomCategory: CustomCategoryRecord?
    
    @Query(sort: \CustomCategoryRecord.name) private var customCategories: [CustomCategoryRecord]
    
    @State private var searchText = ""
    private var allDefaultCategories: [FinanceCategory] = FinanceCategory.allCases

    init(selectedFinanceCategory: Binding<FinanceCategory?>, selectedCustomCategory: Binding<CustomCategoryRecord?>) {
        self._selectedFinanceCategory = selectedFinanceCategory
        self._selectedCustomCategory = selectedCustomCategory
    }

    private var filteredCustom: [CustomCategoryRecord] {
        if searchText.isEmpty { return customCategories }
        return customCategories.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    private var filteredDefault: [FinanceCategory] {
        if searchText.isEmpty { return allDefaultCategories }
        return allDefaultCategories.filter { $0.rawValue.localizedCaseInsensitiveContains(searchText) }
    }
    
    private var isExactMatchFound: Bool {
        let cleanText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanText.isEmpty { return true }
        let exactCustom = customCategories.contains { $0.name.localizedCaseInsensitiveCompare(cleanText) == .orderedSame }
        let exactDefault = allDefaultCategories.contains { $0.rawValue.localizedCaseInsensitiveCompare(cleanText) == .orderedSame }
        return exactCustom || exactDefault
    }

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            HStack {
                Button(action: {}) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                        .padding(10)
                        .background(Color(.systemGray6), in: Circle())
                }
                
                Spacer()
                
                Text("Pick a Category")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: {}) {
                        Image(systemName: "ellipsis")
                            .font(.body.weight(.bold))
                            .foregroundStyle(.primary)
                    }
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.body.weight(.bold))
                            .foregroundStyle(.primary)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(.systemGray6), in: Capsule())
            }
            .padding()
            
            // Content
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    
                    if !searchText.isEmpty && !isExactMatchFound {
                        Button {
                            createAndSelectCategory(name: searchText)
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "circle.dashed")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                                Text("Create new:\n\(searchText)")
                                    .font(.system(.body, design: .rounded).weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)
                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                    
                    ForEach(filteredDefault) { category in
                        CategoryPill(
                            name: category.rawValue,
                            icon: category.icon,
                            isSelected: selectedFinanceCategory == category
                        ) {
                            selectedFinanceCategory = category
                            selectedCustomCategory = nil
                            dismiss()
                        }
                    }
                    
                    ForEach(filteredCustom) { category in
                        CategoryPill(
                            name: category.name,
                            icon: category.iconName,
                            isSelected: selectedCustomCategory?.id == category.id
                        ) {
                            selectedCustomCategory = category
                            selectedFinanceCategory = nil
                            dismiss()
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            
            // Search footer
            VStack(spacing: 0) {
                Divider()
                    .opacity(0.5)
                
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.secondary)
                    
                    TextField("Search or create a new category", text: $searchText)
                        .font(.body)
                        .submitLabel(.done)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color(.tertiaryLabel))
                        }
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color(.systemGray6), in: Capsule())
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(.systemBackground).ignoresSafeArea(.all, edges: .bottom))
        }
    }
    
    private func createAndSelectCategory(name: String) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }
        
        let newCategory = CustomCategoryRecord(
            name: cleanName,
            iconName: "tag.fill",
            colorRed: 0.2, // Defaulting to a pleasant blue/gray tone randomly or hardcoded
            colorGreen: 0.5,
            colorBlue: 0.8
        )
        
        modelContext.insert(newCategory)
        selectedCustomCategory = newCategory
        selectedFinanceCategory = nil
        dismiss()
    }
}

private struct CategoryPill: View {
    let name: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(isSelected ? .white : .primary)
                    .frame(width: 24)
                
                Text(name)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(isSelected ? .white : .primary)
                    .lineLimit(1)
                
                Spacer(minLength: 0)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isSelected ? FinanceTheme.accent : Color(.systemGray6),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
        }
    }
}

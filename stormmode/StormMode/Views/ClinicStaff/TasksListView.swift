import SwiftUI

// MARK: - Tasks List View

struct TasksListView: View {
    @StateObject private var viewModel = ClinicStaffViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFilter: TaskFilter = .all
    
    enum TaskFilter: String, CaseIterable {
        case all = "All"
        case urgent = "Urgent"
        case storm = "Storm"
        case done = "Done"
    }
    
    var filteredTasks: [StormTask] {
        switch selectedFilter {
        case .all:
            return viewModel.allTasks.filter { $0.status != .done }
        case .urgent:
            return viewModel.allTasks.filter { $0.priority == .high && $0.status != .done }
        case .storm:
            return viewModel.allTasks.filter { $0.type == .stormCheckIn && $0.status != .done }
        case .done:
            return viewModel.allTasks.filter { $0.status == .done }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(TaskFilter.allCases, id: \.self) { filter in
                            FilterChip(
                                title: filter.rawValue,
                                isSelected: selectedFilter == filter,
                                action: { selectedFilter = filter }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                .background(Color.stormBackground)
                
                // Tasks List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if filteredTasks.isEmpty {
                            EmptyStateView(
                                icon: "checkmark.circle",
                                title: "No Tasks",
                                message: selectedFilter == .all ? "All caught up!" : "No tasks match this filter."
                            )
                            .padding(.top, 40)
                        } else {
                            ForEach(filteredTasks) { task in
                                TaskCard(
                                    task: task,
                                    patientName: viewModel.patientName(for: task.patientId ?? ""),
                                    onComplete: { viewModel.completeTask(task.id) }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .background(Color.stormBackground.ignoresSafeArea())
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.stormCaptionBold)
                .foregroundColor(isSelected ? .white : .textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.textPrimary : Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TasksListView()
}

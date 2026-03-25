import SwiftUI

struct RulesEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = RulesViewModel()
    @State private var showingNewRule = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Filter Rules")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("Add Rule") {
                    showingNewRule = true
                }
            }
            .padding()
            
            Divider()
            
            if viewModel.rules.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No Rules")
                        .font(.title2)
                    Text("Create rules to automatically organize your articles")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.rules) { rule in
                        RuleRowView(rule: rule, viewModel: viewModel)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            viewModel.deleteRule(viewModel.rules[index])
                        }
                    }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .sheet(isPresented: $showingNewRule) {
            RuleEditorView(viewModel: viewModel, rule: nil)
        }
    }
}

struct RuleRowView: View {
    let rule: FilterRule
    @ObservedObject var viewModel: RulesViewModel
    @State private var showingEditor = false
    
    var body: some View {
        HStack {
            Toggle("", isOn: Binding(
                get: { rule.isEnabled },
                set: { _ in viewModel.toggleRule(rule); }
            ))
            .labelsHidden()
            .toggleStyle(.checkbox)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(rule.name)
                    .font(.headline)
                Text("\(rule.conditions.count) conditions, \(rule.actions.count) actions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Edit") {
                showingEditor = true
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingEditor) {
            RuleEditorView(viewModel: viewModel, rule: rule)
        }
    }
}

struct RuleEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: RulesViewModel
    let rule: FilterRule?
    
    @State private var name: String = ""
    @State private var conditions: [RuleCondition] = []
    @State private var actions: [RuleAction] = []
    @State private var isEnabled: Bool = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(rule == nil ? "New Rule" : "Edit Rule")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") {
                    saveRule()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            Divider()
            
            Form {
                Section {
                    TextField("Rule Name", text: $name)
                    Toggle("Enabled", isOn: $isEnabled)
                }
                
                Section("Conditions") {
                    ForEach(conditions.indices, id: \.self) { index in
                        ConditionRowView(condition: $conditions[index])
                    }
                    Button("+ Add Condition") {
                        conditions.append(RuleCondition(type: .titleContains, value: "", operator_: .contains))
                    }
                }
                
                Section("Actions") {
                    ForEach(actions.indices, id: \.self) { index in
                        ActionRowView(action: $actions[index])
                    }
                    Button("+ Add Action") {
                        actions.append(RuleAction(type: .markAsRead, value: nil))
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(minWidth: 500, minHeight: 500)
        .onAppear {
            if let rule = rule {
                name = rule.name
                conditions = rule.conditions
                actions = rule.actions
                isEnabled = rule.isEnabled
            }
        }
    }
    
    private func saveRule() {
        let newRule = FilterRule(
            id: rule?.id ?? UUID(),
            name: name,
            conditions: conditions,
            actions: actions,
            isEnabled: isEnabled,
            createdAt: rule?.createdAt ?? Date()
        )
        viewModel.saveRule(newRule)
    }
}

struct ConditionRowView: View {
    @Binding var condition: RuleCondition
    
    var body: some View {
        HStack {
            Picker("Type", selection: $condition.type) {
                ForEach(RuleCondition.ConditionType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .labelsHidden()
            
            TextField("Value", text: $condition.value)
        }
    }
}

struct ActionRowView: View {
    @Binding var action: RuleAction
    
    var body: some View {
        HStack {
            Picker("Type", selection: $action.type) {
                ForEach(RuleAction.ActionType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .labelsHidden()
            
            if action.type == .addToCategory || action.type == .addTag {
                TextField("Value", text: Binding(
                    get: { action.value ?? "" },
                    set: { action.value = $0 }
                ))
            }
        }
    }
}

final class RulesViewModel: ObservableObject {
    @Published var rules: [FilterRule] = []
    
    private let rulesEngine = RulesEngine.shared
    
    init() {
        loadRules()
    }
    
    func loadRules() {
        rules = rulesEngine.getAllRules()
    }
    
    func saveRule(_ rule: FilterRule) {
        rulesEngine.saveRule(rule)
        loadRules()
    }
    
    func deleteRule(_ rule: FilterRule) {
        rulesEngine.deleteRule(id: rule.id)
        loadRules()
    }
    
    func toggleRule(_ rule: FilterRule) {
        var updatedRule = rule
        updatedRule.isEnabled.toggle()
        rulesEngine.saveRule(updatedRule)
        loadRules()
    }
}

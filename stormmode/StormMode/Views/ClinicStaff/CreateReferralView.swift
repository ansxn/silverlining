import SwiftUI

// MARK: - Create Referral View

struct CreateReferralView: View {
    @StateObject private var viewModel = ClinicStaffViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPatientId: String = ""
    @State private var selectedType: ReferralType = .cardiology
    @State private var selectedPriority: Priority = .medium
    @State private var notes: String = ""
    @State private var stormSensitive: Bool = true
    @State private var showSuccess = false
    
    var patients: [User] {
        viewModel.patients()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Patient Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Patient")
                            .font(.stormHeadline)
                            .foregroundColor(.textPrimary)
                        
                        Menu {
                            ForEach(patients) { patient in
                                Button(action: { selectedPatientId = patient.id }) {
                                    HStack {
                                        Text(patient.fullName)
                                        if patient.isVulnerable {
                                            Image(systemName: "heart.fill")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedPatientId.isEmpty ? "Select patient..." : patientName(for: selectedPatientId))
                                    .font(.stormBody)
                                    .foregroundColor(selectedPatientId.isEmpty ? .textLight : .textPrimary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(12)
                            .cardShadow()
                        }
                    }
                    
                    // Referral Type
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Referral Type")
                            .font(.stormHeadline)
                            .foregroundColor(.textPrimary)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(ReferralType.allCases, id: \.self) { type in
                                ReferralTypeButton(
                                    type: type,
                                    isSelected: selectedType == type,
                                    action: { selectedType = type }
                                )
                            }
                        }
                    }
                    
                    // Priority
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Priority")
                            .font(.stormHeadline)
                            .foregroundColor(.textPrimary)
                        
                        HStack(spacing: 12) {
                            ForEach(Priority.allCases, id: \.self) { priority in
                                Button(action: { selectedPriority = priority }) {
                                    Text(priority.displayName)
                                        .font(.stormBodyBold)
                                        .foregroundColor(selectedPriority == priority ? .white : priority.color)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(selectedPriority == priority ? priority.color : priority.color.opacity(0.2))
                                        .cornerRadius(12)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    
                    // Storm Sensitive Toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Storm Sensitive")
                                .font(.stormBodyBold)
                                .foregroundColor(.textPrimary)
                            
                            Text("Flag during Storm Mode")
                                .font(.stormCaption)
                                .foregroundColor(.textSecondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $stormSensitive)
                            .tint(.stormActive)
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                    .cardShadow()
                    
                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Clinical Notes (clinic-only)")
                            .font(.stormCaptionBold)
                            .foregroundColor(.textSecondary)
                        
                        TextEditor(text: $notes)
                            .font(.stormBody)
                            .frame(minHeight: 100)
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(12)
                            .cardShadow()
                    }
                    
                    // Submit Button
                    Button(action: submitReferral) {
                        Text("Create Referral")
                    }
                    .buttonStyle(PrimaryButtonStyle(isDisabled: !isValid))
                    .disabled(!isValid)
                    
                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .background(Color.stormBackground.ignoresSafeArea())
            .navigationTitle("New Referral")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Referral Created", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("A \(selectedType.displayName) referral has been created for \(patientName(for: selectedPatientId)).")
            }
        }
    }
    
    private var isValid: Bool {
        !selectedPatientId.isEmpty
    }
    
    private func patientName(for id: String) -> String {
        viewModel.patientName(for: id)
    }
    
    private func submitReferral() {
        viewModel.createReferral(
            patientId: selectedPatientId,
            type: selectedType,
            priority: selectedPriority,
            notes: notes.isEmpty ? nil : notes,
            stormSensitive: stormSensitive
        )
        showSuccess = true
    }
}

// MARK: - Referral Type Button

struct ReferralTypeButton: View {
    let type: ReferralType
    let isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: type.icon)
                    .font(.title3)
                
                Text(type.displayName)
                    .font(.stormCaptionBold)
                
                Spacer()
            }
            .foregroundColor(isSelected ? .white : .textPrimary)
            .padding(14)
            .background(isSelected ? type.color : type.color.opacity(0.2))
            .cornerRadius(14)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CreateReferralView()
}

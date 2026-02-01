import SwiftUI

// MARK: - Create Request View

struct CreateRequestView: View {
    @StateObject private var viewModel = PatientViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedType: TransportType = .rideToAppointment
    @State private var pickupLocation: String = ""
    @State private var dropoffLocation: String = ""
    @State private var selectedDate: Date = Date()
    @State private var notes: String = ""
    @State private var showSuccess = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Request Type Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What do you need?")
                            .font(.stormHeadline)
                            .foregroundColor(.textPrimary)
                        
                        HStack(spacing: 12) {
                            ForEach(TransportType.allCases, id: \.self) { type in
                                RequestTypeButton(
                                    type: type,
                                    isSelected: selectedType == type,
                                    action: { selectedType = type }
                                )
                            }
                        }
                    }
                    
                    // Pickup Location
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pickup Location")
                            .font(.stormCaptionBold)
                            .foregroundColor(.textSecondary)
                        
                        HStack {
                            Image(systemName: "location.circle.fill")
                                .foregroundColor(.statusOk)
                            
                            TextField("Enter pickup address", text: $pickupLocation)
                                .font(.stormBody)
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(12)
                        .cardShadow()
                    }
                    
                    // Dropoff Location
                    VStack(alignment: .leading, spacing: 8) {
                        Text(selectedType == .pharmacyPickup ? "Delivery Address" : "Dropoff Location")
                            .font(.stormCaptionBold)
                            .foregroundColor(.textSecondary)
                        
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.statusUrgent)
                            
                            TextField(selectedType == .pharmacyPickup ? "Enter delivery address" : "Enter destination", text: $dropoffLocation)
                                .font(.stormBody)
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(12)
                        .cardShadow()
                    }
                    
                    // Date & Time
                    VStack(alignment: .leading, spacing: 8) {
                        Text("When do you need this?")
                            .font(.stormCaptionBold)
                            .foregroundColor(.textSecondary)
                        
                        DatePicker(
                            "Date & Time",
                            selection: $selectedDate,
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.graphical)
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(12)
                        .cardShadow()
                    }
                    
                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Additional Notes (optional)")
                            .font(.stormCaptionBold)
                            .foregroundColor(.textSecondary)
                        
                        TextEditor(text: $notes)
                            .font(.stormBody)
                            .frame(minHeight: 80)
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(12)
                            .cardShadow()
                    }
                    
                    // Submit Button
                    Button(action: submitRequest) {
                        Text("Submit Request")
                    }
                    .buttonStyle(PrimaryButtonStyle(isDisabled: !isValid))
                    .disabled(!isValid)
                    
                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .background(Color.stormBackground.ignoresSafeArea())
            .navigationTitle("New Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Request Submitted", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Your \(selectedType.displayName.lowercased()) request has been submitted. A volunteer will be assigned soon.")
            }
        }
    }
    
    private var isValid: Bool {
        !pickupLocation.isEmpty && !dropoffLocation.isEmpty
    }
    
    private func submitRequest() {
        viewModel.createTransportRequest(
            type: selectedType,
            pickup: pickupLocation,
            dropoff: dropoffLocation,
            date: selectedDate,
            notes: notes.isEmpty ? nil : notes
        )
        showSuccess = true
    }
}

// MARK: - Request Type Button

struct RequestTypeButton: View {
    let type: TransportType
    let isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title2)
                
                Text(type.shortName)
                    .font(.stormCaptionBold)
            }
            .foregroundColor(isSelected ? .white : .textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? type.color : type.color.opacity(0.2))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CreateRequestView()
}

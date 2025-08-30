import SwiftUI
import CoreLocation

struct ManageSpotView: View {
    @State var spot: ParkingSpot
    @EnvironmentObject var viewModel: ParkingSpotViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var isEditing = false
    @State private var editedAddress = ""
    @State private var editedHourlyRate = ""
    @State private var editedAvailabilityStart = Date()
    @State private var editedAvailabilityEnd = Date()
    @State private var editedMaxVehicleSize = VehicleSize.any
    @State private var editedDescription = ""
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header image placeholder
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                        .overlay(
                            VStack {
                                Image(systemName: "car.2.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("Photo Coming Soon")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        )
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Status and price
                        HStack {
                            VStack(alignment: .leading) {
                                if isEditing {
                                    HStack {
                                        Text("$")
                                            .font(.title)
                                            .fontWeight(.bold)
                                            .foregroundColor(.blue)
                                        
                                        TextField("15", text: $editedHourlyRate)
                                            .keyboardType(.decimalPad)
                                            .font(.title)
                                            .fontWeight(.bold)
                                            .foregroundColor(.blue)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                        
                                        Text("/hr")
                                            .font(.title)
                                            .fontWeight(.bold)
                                            .foregroundColor(.blue)
                                    }
                                } else {
                                    Text(viewModel.formatPrice(spot.hourlyRate))
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            Spacer()
                            
                            // Availability toggle
                            VStack(alignment: .trailing) {
                                HStack {
                                    Circle()
                                        .fill(spot.isAvailable ? Color.green : Color.red)
                                        .frame(width: 8, height: 8)
                                    
                                    Text(spot.isAvailable ? "Available" : "Unavailable")
                                        .font(.subheadline)
                                        .foregroundColor(spot.isAvailable ? .green : .red)
                                }
                                
                                Button(spot.isAvailable ? "Mark Unavailable" : "Mark Available") {
                                    toggleAvailability()
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                        }
                        
                        Divider()
                        
                        // Address
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.blue)
                                Text("Address")
                                    .font(.headline)
                            }
                            
                            if isEditing {
                                TextField("Address", text: $editedAddress)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            } else {
                                Text(spot.address)
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        Divider()
                        
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "text.alignleft")
                                    .foregroundColor(.blue)
                                Text("Description")
                                    .font(.headline)
                            }
                            
                            if isEditing {
                                TextField("Description", text: $editedDescription, axis: .vertical)
                                    .lineLimit(3...6)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            } else {
                                Text(spot.description)
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        Divider()
                        
                        // Vehicle size
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "car.fill")
                                    .foregroundColor(.blue)
                                Text("Max Vehicle Size")
                                    .font(.headline)
                            }
                            
                            if isEditing {
                                Picker("Max Vehicle Size", selection: $editedMaxVehicleSize) {
                                    ForEach(VehicleSize.allCases, id: \.self) { size in
                                        Text(size.displayName).tag(size)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            } else {
                                Text(spot.maxVehicleSize.displayName)
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        if isEditing {
                            Divider()
                            
                            // Availability times
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .foregroundColor(.blue)
                                    Text("Availability")
                                        .font(.headline)
                                }
                                
                                VStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Available From")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        
                                        DatePicker("", selection: $editedAvailabilityStart, in: Date()...)
                                            .datePickerStyle(CompactDatePickerStyle())
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Available Until")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        
                                        DatePicker("", selection: $editedAvailabilityEnd, in: editedAvailabilityStart...)
                                            .datePickerStyle(CompactDatePickerStyle())
                                    }
                                }
                            }
                        } else {
                            Divider()
                            
                            // Read-only availability times
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .foregroundColor(.blue)
                                    Text("Availability")
                                        .font(.headline)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("From: \(viewModel.formatDate(spot.availabilityStart))")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Text("Until: \(viewModel.formatDate(spot.availabilityEnd))")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        
                        // Recent bookings
                        let recentBookings = getRecentBookings()
                        if !recentBookings.isEmpty {
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "calendar.badge.clock")
                                        .foregroundColor(.blue)
                                    Text("Recent Bookings")
                                        .font(.headline)
                                }
                                
                                ForEach(recentBookings.prefix(3)) { booking in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(booking.finderName)
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                            
                                            Text(viewModel.formatDate(booking.startTime))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Text("$\(String(format: "%.2f", booking.totalAmount))")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.green)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        
                        if !isEditing {
                            Divider()
                            
                            // Delete button
                            Button(action: {
                                showingDeleteAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "trash.fill")
                                    Text("Delete Parking Spot")
                                }
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Manage Spot")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(isEditing ? "Cancel" : "Close") {
                    if isEditing {
                        cancelEditing()
                    } else {
                        dismiss()
                    }
                },
                trailing: Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        saveChanges()
                    } else {
                        startEditing()
                    }
                }
            )
            .alert("Delete Parking Spot", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteSpot()
                }
            } message: {
                Text("Are you sure you want to delete this parking spot? This action cannot be undone.")
            }
        }
    }
    
    /// Get recent bookings for this spot
    private func getRecentBookings() -> [Booking] {
        return viewModel.getBookingsForUserSpots()
            .filter { $0.spotID == spot.id }
            .sorted { $0.startTime > $1.startTime }
    }
    
    /// Start editing mode
    private func startEditing() {
        editedAddress = spot.address
        editedHourlyRate = String(format: "%.0f", spot.hourlyRate)
        editedAvailabilityStart = spot.availabilityStart
        editedAvailabilityEnd = spot.availabilityEnd
        editedMaxVehicleSize = spot.maxVehicleSize
        editedDescription = spot.description
        
        withAnimation {
            isEditing = true
        }
    }
    
    /// Cancel editing
    private func cancelEditing() {
        withAnimation {
            isEditing = false
        }
    }
    
    /// Save changes
    private func saveChanges() {
        guard let rate = Double(editedHourlyRate), rate > 0 else {
            return
        }
        
        spot.address = editedAddress
        spot.hourlyRate = rate
        spot.availabilityStart = editedAvailabilityStart
        spot.availabilityEnd = editedAvailabilityEnd
        spot.maxVehicleSize = editedMaxVehicleSize
        spot.description = editedDescription
        
        viewModel.updateParkingSpot(spot)
        
        withAnimation {
            isEditing = false
        }
    }
    
    /// Toggle availability
    private func toggleAvailability() {
        viewModel.toggleSpotAvailability(spot)
        spot.isAvailable.toggle()
    }
    
    /// Delete spot
    private func deleteSpot() {
        viewModel.deleteParkingSpot(spot)
        dismiss()
    }
}

#Preview {
    ManageSpotView(
        spot: ParkingSpot(
            address: "123 Test Street, San Francisco, CA 94107",
            latitude: 37.7749,
            longitude: -122.4194,
            hourlyRate: 15.0,
            isAvailable: true,
            availabilityStart: Date(),
            availabilityEnd: Date().addingTimeInterval(3600 * 8),
            maxVehicleSize: .any,
            description: "Secure driveway spot with easy access to the venue",
            imageURL: nil,
            ownerID: "test",
            ownerName: "John Doe"
        )
    )
    .environmentObject(ParkingSpotViewModel())
}
import SwiftUI
import CoreLocation

struct SpotDetailView: View {
    let spot: ParkingSpot
    @EnvironmentObject var viewModel: ParkingSpotViewModel
    @StateObject private var locationManager = LocationManager()
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedStartTime = Date()
    @State private var selectedEndTime = Date().addingTimeInterval(3600 * 2) // Default 2 hours
    @State private var showingBookingConfirmation = false
    @State private var messageToOwner = ""
    @State private var showingRequestSheet = false
    
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
                        // Price and distance
                        HStack {
                            VStack(alignment: .leading) {
                                Text(viewModel.formatPrice(spot.hourlyRate))
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                
                                if let location = locationManager.location {
                                    Text("\(viewModel.formatDistance(spot.distance(from: location))) away")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            // Availability status
                            HStack {
                                Circle()
                                    .fill(spot.isAvailable ? Color.green : Color.red)
                                    .frame(width: 8, height: 8)
                                
                                Text(spot.isAvailable ? "Available" : "Unavailable")
                                    .font(.subheadline)
                                    .foregroundColor(spot.isAvailable ? .green : .red)
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
                            
                            Text(spot.address)
                                .font(.body)
                                .foregroundColor(.primary)
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
                            
                            Text(spot.description)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        
                        Divider()
                        
                        // Details
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Details")
                                    .font(.headline)
                            }
                            
                            DetailRow(icon: "car.fill", label: "Max Vehicle Size", value: spot.maxVehicleSize.displayName)
                            DetailRow(icon: "person.fill", label: "Owner", value: spot.ownerName)
                            DetailRow(icon: "clock.fill", label: "Available From", value: viewModel.formatDate(spot.availabilityStart))
                            DetailRow(icon: "clock.fill", label: "Available Until", value: viewModel.formatDate(spot.availabilityEnd))
                        }
                        
                        if spot.isAvailable {
                            Divider()
                            
                            // Booking section
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.blue)
                                    Text("Request to Book This Spot")
                                        .font(.headline)
                                }
                                
                                VStack(spacing: 12) {
                                    // Start time picker
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Start Time")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        
                                        DatePicker("", selection: $selectedStartTime, in: Date()...spot.availabilityEnd)
                                            .datePickerStyle(CompactDatePickerStyle())
                                    }
                                    
                                    // End time picker
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("End Time")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        
                                        DatePicker("", selection: $selectedEndTime, in: selectedStartTime...spot.availabilityEnd)
                                            .datePickerStyle(CompactDatePickerStyle())
                                    }
                                    
                                    // Price calculation
                                    HStack {
                                        Text("Total Price:")
                                            .font(.headline)
                                        
                                        Spacer()
                                        
                                        Text("$\(String(format: "%.2f", totalPrice))")
                                            .font(.headline)
                                            .foregroundColor(.blue)
                                    }
                                    .padding()
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Parking Spot")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
            )
            .safeAreaInset(edge: .bottom) {
                if spot.isAvailable {
                    // Request booking button
                    Button(action: {
                        showingRequestSheet = true
                    }) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Send Booking Request")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(16)
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                }
            }
        }
        .sheet(isPresented: $showingRequestSheet) {
            BookingRequestSheet(
                spot: spot,
                startTime: selectedStartTime,
                endTime: selectedEndTime,
                totalPrice: totalPrice,
                message: $messageToOwner,
                onSendRequest: {
                    sendBookingRequest()
                }
            )
        }
        .onAppear {
            // Ensure end time is after start time
            if selectedEndTime <= selectedStartTime {
                selectedEndTime = selectedStartTime.addingTimeInterval(3600) // Add 1 hour
            }
        }
        .onChange(of: selectedStartTime) { newStartTime in
            // Update end time if it's before the new start time
            if selectedEndTime <= newStartTime {
                selectedEndTime = newStartTime.addingTimeInterval(3600) // Add 1 hour
            }
        }
    }
    
    /// Calculate total price based on selected time range
    private var totalPrice: Double {
        viewModel.calculateTotalPrice(
            hourlyRate: spot.hourlyRate,
            startTime: selectedStartTime,
            endTime: selectedEndTime
        )
    }
    
    /// Send booking request
    private func sendBookingRequest() {
        viewModel.sendBookingRequest(
            spot: spot,
            startTime: selectedStartTime,
            endTime: selectedEndTime,
            message: messageToOwner.isEmpty ? nil : messageToOwner
        )
        showingRequestSheet = false
        dismiss()
    }
}

// MARK: - BookingRequestSheet
struct BookingRequestSheet: View {
    let spot: ParkingSpot
    let startTime: Date
    let endTime: Date
    let totalPrice: Double
    @Binding var message: String
    let onSendRequest: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Request summary
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Booking Request Summary")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Spot:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(spot.address)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                                
                                HStack {
                                    Text("Start Time:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(formatDate(startTime))
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                                
                                HStack {
                                    Text("End Time:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(formatDate(endTime))
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                                
                                HStack {
                                    Text("Total Price:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("$\(String(format: "%.2f", totalPrice))")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        Divider()
                        
                        // Message to owner
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Message to Owner (Optional)")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("Add a personal message to the spot owner to increase your chances of approval.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextField("e.g., I'll be attending a nearby event and need parking for 2 hours...", text: $message, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(4...6)
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
                
                // Send request button
                Button(action: onSendRequest) {
                    HStack {
                        Image(systemName: "paperplane.fill")
                        Text("Send Booking Request")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(16)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Booking Request")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
            )
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - DetailRow
struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    SpotDetailView(
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
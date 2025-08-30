import SwiftUI
import CoreLocation

struct AddSpotView: View {
    @EnvironmentObject var viewModel: ParkingSpotViewModel
    @StateObject private var locationManager = LocationManager()
    @Environment(\.dismiss) private var dismiss
    
    @State private var address = ""
    @State private var hourlyRate = ""
    @State private var availabilityStart = Date()
    @State private var availabilityEnd = Date().addingTimeInterval(3600 * 8) // Default 8 hours
    @State private var maxVehicleSize = VehicleSize.any
    @State private var description = ""
    @State private var isLoadingLocation = false
    @State private var coordinate: CLLocationCoordinate2D?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Location")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Address")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button(action: {
                                getCurrentLocation()
                            }) {
                                HStack(spacing: 4) {
                                    if isLoadingLocation {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "location.fill")
                                    }
                                    Text("Use Current")
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                            .disabled(isLoadingLocation)
                        }
                        
                        TextField("Enter your address", text: $address)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                Section(header: Text("Pricing")) {
                    HStack {
                        Text("Hourly Rate")
                        Spacer()
                        TextField("$0", text: $hourlyRate)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section(header: Text("Availability")) {
                    DatePicker("Available From", selection: $availabilityStart, in: Date()...)
                        .datePickerStyle(CompactDatePickerStyle())
                    
                    DatePicker("Available Until", selection: $availabilityEnd, in: availabilityStart...)
                        .datePickerStyle(CompactDatePickerStyle())
                }
                
                Section(header: Text("Vehicle Requirements")) {
                    Picker("Max Vehicle Size", selection: $maxVehicleSize) {
                        ForEach(VehicleSize.allCases, id: \.self) { size in
                            Text(size.displayName).tag(size)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section(header: Text("Description")) {
                    TextField("Describe your parking spot (e.g., covered, secure, easy access)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    VStack(spacing: 12) {
                        // Preview card
                        if !address.isEmpty && !hourlyRate.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Preview")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Text(viewModel.formatPrice(Double(hourlyRate) ?? 0))
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                }
                                
                                Text(address)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                
                                if !description.isEmpty {
                                    Text(description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack {
                                    Text("Max: \(maxVehicleSize.displayName)")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(8)
                                    
                                    Spacer()
                                }
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        }
                        
                        // Add spot button
                        Button(action: {
                            addSpot()
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Parking Spot")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color.blue : Color.gray)
                            .cornerRadius(12)
                        }
                        .disabled(!isFormValid)
                    }
                }
            }
            .navigationTitle("Add Parking Spot")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    addSpot()
                }
                .disabled(!isFormValid)
            )
            .onAppear {
                locationManager.requestLocationPermission()
            }
        }
    }
    
    /// Check if form is valid
    private var isFormValid: Bool {
        !address.isEmpty &&
        !hourlyRate.isEmpty &&
        Double(hourlyRate) != nil &&
        Double(hourlyRate) ?? 0 > 0 &&
        availabilityEnd > availabilityStart
    }
    
    /// Get current location and auto-fill address
    private func getCurrentLocation() {
        guard let location = locationManager.location else {
            locationManager.startLocationUpdates()
            return
        }
        
        isLoadingLocation = true
        
        locationManager.getAddress(from: location.coordinate) { addressString in
            DispatchQueue.main.async {
                self.isLoadingLocation = false
                if let addressString = addressString {
                    self.address = addressString
                    self.coordinate = location.coordinate
                }
            }
        }
    }
    
    /// Add the parking spot
    private func addSpot() {
        guard isFormValid,
              let rate = Double(hourlyRate) else {
            return
        }
        
        // If we don't have coordinates, try to geocode the address
        if let coord = coordinate {
            // Use existing coordinates
            viewModel.addParkingSpot(
                address: address,
                coordinate: coord,
                hourlyRate: rate,
                availabilityStart: availabilityStart,
                availabilityEnd: availabilityEnd,
                maxVehicleSize: maxVehicleSize,
                description: description
            )
            dismiss()
        } else {
            // Geocode the address
            locationManager.getCoordinates(from: address) { coord in
                DispatchQueue.main.async {
                    if let coord = coord {
                        self.viewModel.addParkingSpot(
                            address: self.address,
                            coordinate: coord,
                            hourlyRate: rate,
                            availabilityStart: self.availabilityStart,
                            availabilityEnd: self.availabilityEnd,
                            maxVehicleSize: self.maxVehicleSize,
                            description: self.description
                        )
                        self.dismiss()
                    } else {
                        // Use default San Francisco coordinates if geocoding fails
                        let defaultCoord = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
                        self.viewModel.addParkingSpot(
                            address: self.address,
                            coordinate: defaultCoord,
                            hourlyRate: rate,
                            availabilityStart: self.availabilityStart,
                            availabilityEnd: self.availabilityEnd,
                            maxVehicleSize: self.maxVehicleSize,
                            description: self.description
                        )
                        self.dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AddSpotView()
        .environmentObject(ParkingSpotViewModel())
}
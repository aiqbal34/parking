import SwiftUI

struct RenterView: View {
    @EnvironmentObject var viewModel: ParkingSpotViewModel
    @State private var showingAddSpot = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom segmented control
                Picker("", selection: $selectedTab) {
                    Text("My Spots").tag(0)
                    Text("Requests").tag(1)
                    Text("Bookings").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on selected tab
                if selectedTab == 0 {
                    // My Spots tab
                    MyParkingSpotsView()
                } else if selectedTab == 1 {
                    // Booking Requests tab
                    BookingRequestsView()
                } else {
                    // Bookings tab
                    MyBookingsView()
                }
            }
            .navigationTitle("Rent Out Spot")
            .navigationBarItems(
                trailing: selectedTab == 0 ? AnyView(
                    Button(action: {
                        showingAddSpot = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                ) : AnyView(EmptyView())
            )
            .sheet(isPresented: $showingAddSpot) {
                AddSpotView()
                    .environmentObject(viewModel)
            }
            .onAppear {
                Task {
                    await viewModel.refreshAllData()
                }
            }
            .onChange(of: showingAddSpot) { isShowing in
                if !isShowing {
                    // Refresh data when AddSpotView is dismissed
                    Task {
                        await viewModel.refreshAllData()
                    }
                }
            }
        }
    }
}

// MARK: - MyParkingSpotsView
struct MyParkingSpotsView: View {
    @EnvironmentObject var viewModel: ParkingSpotViewModel
    @State private var selectedSpot: ParkingSpot?
    
    var body: some View {
        Group {
            if viewModel.userParkingSpots.isEmpty {
                // Empty state
                VStack(spacing: 20) {
                    Image(systemName: "car.2")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No Parking Spots Yet")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Add your first parking spot to start earning money from your driveway or unused space.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Add Your First Spot") {
                        // This will be handled by the parent view
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(16)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemGroupedBackground))
            } else {
                // List of user's parking spots
                List(viewModel.userParkingSpots) { spot in
                    UserSpotRowView(spot: spot) {
                        selectedSpot = spot
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
                .listStyle(PlainListStyle())
                .background(Color(UIColor.systemGroupedBackground))
            }
        }
        .sheet(item: $selectedSpot) { spot in
            ManageSpotView(spot: spot)
                .environmentObject(viewModel)
        }
    }
}

// MARK: - BookingRequestsView
struct BookingRequestsView: View {
    @EnvironmentObject var viewModel: ParkingSpotViewModel
    @State private var selectedRequest: Booking?
    
    var body: some View {
        let pendingRequests = viewModel.getPendingBookingsForUserSpots()
        
        Group {
            if pendingRequests.isEmpty {
                // Empty state
                VStack(spacing: 20) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No Pending Requests")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("When people request to book your parking spots, you'll see their requests here for approval.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemGroupedBackground))
            } else {
                // List of pending requests
                List(pendingRequests) { request in
                    BookingRequestRowView(request: request) {
                        selectedRequest = request
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
                .listStyle(PlainListStyle())
                .background(Color(UIColor.systemGroupedBackground))
            }
        }
        .sheet(item: $selectedRequest) { request in
            BookingRequestDetailView(request: request)
                .environmentObject(viewModel)
        }
    }
}

// MARK: - MyBookingsView
struct MyBookingsView: View {
    @EnvironmentObject var viewModel: ParkingSpotViewModel
    
    var body: some View {
        let bookings = viewModel.getBookingsForUserSpots()
        
        Group {
            if bookings.isEmpty {
                // Empty state
                VStack(spacing: 20) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No Bookings Yet")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("When people book your parking spots, you'll see their reservations here.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemGroupedBackground))
            } else {
                // List of bookings
                List(bookings) { booking in
                    BookingRowView(booking: booking)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
                .listStyle(PlainListStyle())
                .background(Color(UIColor.systemGroupedBackground))
            }
        }
    }
}

// MARK: - UserSpotRowView
struct UserSpotRowView: View {
    let spot: ParkingSpot
    let onTap: () -> Void
    @EnvironmentObject var viewModel: ParkingSpotViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Status indicator
                VStack {
                    Circle()
                        .fill(spot.isAvailable ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                    
                    Spacer()
                }
                .frame(height: 60)
                
                // Placeholder image
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "car.fill")
                            .foregroundColor(.gray)
                    )
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(viewModel.formatPrice(spot.hourlyRate))
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Text(spot.isAvailable ? "Available" : "Unavailable")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(spot.isAvailable ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                            .foregroundColor(spot.isAvailable ? .green : .red)
                            .cornerRadius(8)
                    }
                    
                    Text(spot.address)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(spot.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Arrow
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .onTapGesture {
                onTap()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

// MARK: - BookingRequestRowView
struct BookingRequestRowView: View {
    let request: Booking
    let onTap: () -> Void
    @EnvironmentObject var viewModel: ParkingSpotViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Status indicator
                VStack {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 12, height: 12)
                    
                    Spacer()
                }
                .frame(height: 80)
                
                // Request icon
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "clock.badge.questionmark")
                            .foregroundColor(.orange)
                    )
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(request.finderName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("$\(String(format: "%.2f", request.totalAmount))")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    
                    Text(viewModel.formatDate(request.startTime))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("to \(viewModel.formatDate(request.endTime))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Pending Approval")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(6)
                }
                
                // Arrow
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .onTapGesture {
                onTap()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

// MARK: - BookingRowView
struct BookingRowView: View {
    let booking: Booking
    @EnvironmentObject var viewModel: ParkingSpotViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Status indicator
                VStack {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 12, height: 12)
                    
                    Spacer()
                }
                .frame(height: 80)
                
                // Booking icon
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.blue)
                    )
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(booking.finderName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("$\(String(format: "%.2f", booking.totalAmount))")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    
                    Text(viewModel.formatDate(booking.startTime))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("to \(viewModel.formatDate(booking.endTime))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(booking.status.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.2))
                        .foregroundColor(statusColor)
                        .cornerRadius(6)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
    
    private var statusColor: Color {
        switch booking.status {
        case .pending:
            return .orange
        case .approved:
            return .blue
        case .rejected:
            return .red
        case .confirmed:
            return .green
        case .completed:
            return .gray
        case .cancelled:
            return .red
        }
    }
}

// MARK: - BookingRequestDetailView
struct BookingRequestDetailView: View {
    let request: Booking
    @EnvironmentObject var viewModel: ParkingSpotViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var responseMessage = ""
    @State private var showingResponseSheet = false
    @State private var isApproving = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Request summary
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Booking Request Details")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            DetailRow(icon: "person.fill", label: "Requester", value: request.finderName)
                            DetailRow(icon: "envelope.fill", label: "Email", value: request.finderEmail)
                            DetailRow(icon: "calendar", label: "Start Time", value: viewModel.formatDate(request.startTime))
                            DetailRow(icon: "calendar", label: "End Time", value: viewModel.formatDate(request.endTime))
                            DetailRow(icon: "dollarsign.circle.fill", label: "Total Amount", value: "$\(String(format: "%.2f", request.totalAmount))")
                            DetailRow(icon: "clock.fill", label: "Requested", value: viewModel.formatDate(request.createdAt))
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // Message from requester
                    if let message = request.message {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Message from Requester")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(message)
                                .font(.body)
                                .foregroundColor(.primary)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Booking Request")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: HStack {
                    Button("Reject") {
                        isApproving = false
                        showingResponseSheet = true
                    }
                    .foregroundColor(.red)
                    
                    Button("Approve") {
                        isApproving = true
                        showingResponseSheet = true
                    }
                    .foregroundColor(.green)
                }
            )
        }
        .sheet(isPresented: $showingResponseSheet) {
            ResponseSheet(
                isApproving: isApproving,
                responseMessage: $responseMessage,
                onSendResponse: {
                    if isApproving {
                        viewModel.approveBookingRequest(request, response: responseMessage.isEmpty ? nil : responseMessage)
                    } else {
                        viewModel.rejectBookingRequest(request, response: responseMessage.isEmpty ? nil : responseMessage)
                    }
                    showingResponseSheet = false
                    dismiss()
                }
            )
        }
    }
}

// MARK: - ResponseSheet
struct ResponseSheet: View {
    let isApproving: Bool
    @Binding var responseMessage: String
    let onSendResponse: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(isApproving ? "Approve Request" : "Reject Request")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(isApproving ? "Add an optional message to the requester:" : "Add an optional reason for rejection:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("Optional message...", text: $responseMessage, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(4...6)
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 12) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    Button(isApproving ? "Approve" : "Reject") {
                        onSendResponse()
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isApproving ? Color.green : Color.red)
                    .cornerRadius(12)
                }
            }
            .padding()
            .navigationTitle(isApproving ? "Approve Request" : "Reject Request")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
            )
        }
    }
}

#Preview {
    RenterView()
        .environmentObject(ParkingSpotViewModel())
}

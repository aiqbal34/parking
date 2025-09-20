// User Types
export interface User {
  uid: string
  email: string
  name: string
  phone_number?: string
  profile_image_url?: string
  role: UserRole
  created_at: string
  last_login_at?: string
}

export enum UserRole {
  FINDER = 'finder',
  RENTER = 'renter',
  BOTH = 'both'
}

// Parking Spot Types
export interface ParkingSpot {
  id: string
  address: string
  latitude: number
  longitude: number
  hourly_rate: number
  is_available: boolean
  availability_start: string
  availability_end: string
  max_vehicle_size: VehicleSize
  description: string
  image_url?: string
  owner_id: string
  owner_name: string
  created_at: string
  updated_at: string
  distance?: number // Added for nearby spots
}

export enum VehicleSize {
  COMPACT = 'compact',
  MIDSIZE = 'midsize',
  LARGE = 'large',
  SUV = 'suv',
  ANY = 'any'
}

// Booking Types
export interface Booking {
  id: string
  spot_id: string
  finder_id: string
  finder_name: string
  finder_email: string
  start_time: string
  end_time: string
  total_amount: number
  status: BookingStatus
  created_at: string
  message?: string
  owner_response?: string
  responded_at?: string
}

export enum BookingStatus {
  PENDING = 'pending',
  APPROVED = 'approved',
  REJECTED = 'rejected',
  CONFIRMED = 'confirmed',
  COMPLETED = 'completed',
  CANCELLED = 'cancelled'
}

// API Response Types
export interface APIResponse<T = any> {
  success: boolean
  message: string
  data?: T
}

export interface PaginatedResponse<T> {
  items: T[]
  total: number
  page: number
  size: number
  pages: number
}

// Location Types
export interface LocationQuery {
  latitude: number
  longitude: number
  radius?: number
}

// Search Types
export interface ParkingSpotSearch {
  latitude?: number
  longitude?: number
  radius?: number
  max_price?: number
  vehicle_size?: VehicleSize
  start_time?: string
  end_time?: string
}

// Form Types
export interface CreateParkingSpotData {
  address: string
  latitude: number
  longitude: number
  hourly_rate: number
  is_available: boolean
  availability_start: string
  availability_end: string
  max_vehicle_size: VehicleSize
  description: string
  image_url?: string
  owner_id: string
  owner_name: string
}

export interface UpdateParkingSpotData {
  address?: string
  latitude?: number
  longitude?: number
  hourly_rate?: number
  is_available?: boolean
  availability_start?: string
  availability_end?: string
  max_vehicle_size?: VehicleSize
  description?: string
  image_url?: string
}

export interface CreateBookingData {
  spot_id: string
  finder_id: string
  finder_name: string
  finder_email: string
  start_time: string
  end_time: string
  message?: string
}

export interface UpdateBookingData {
  status?: BookingStatus
  owner_response?: string
  responded_at?: string
}

// Auth Types
export interface AuthUser {
  uid: string
  email: string | null
  displayName: string | null
  photoURL: string | null
}

// Map Types
export interface MapMarker {
  id: string
  position: [number, number]
  spot: ParkingSpot
}

// Utility Types
export interface SelectOption {
  value: string
  label: string
}

export interface FilterOptions {
  maxPrice?: number
  vehicleSize?: VehicleSize
  startTime?: Date
  endTime?: Date
  radius?: number
}

// Error Types
export interface AppError {
  code: string
  message: string
  details?: any
}

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum

# Enums
class VehicleSize(str, Enum):
    compact = "compact"
    midsize = "midsize"
    large = "large"
    suv = "suv"
    any = "any"

class BookingStatus(str, Enum):
    pending = "pending"
    approved = "approved"
    rejected = "rejected"
    confirmed = "confirmed"
    completed = "completed"
    cancelled = "cancelled"

class UserRole(str, Enum):
    finder = "finder"
    renter = "renter"
    both = "both"

# Base models
class UserBase(BaseModel):
    email: str
    name: str
    phone_number: Optional[str] = None
    profile_image_url: Optional[str] = None
    role: UserRole = UserRole.finder

class UserCreate(UserBase):
    firebase_uid: str

class UserUpdate(BaseModel):
    name: Optional[str] = None
    phone_number: Optional[str] = None
    profile_image_url: Optional[str] = None
    role: Optional[UserRole] = None

class User(UserBase):
    uid: str
    created_at: datetime
    last_login_at: Optional[datetime] = None

    class Config:
        from_attributes = True

# Parking Spot models
class ParkingSpotBase(BaseModel):
    address: str
    latitude: float
    longitude: float
    hourly_rate: float
    is_available: bool = True
    availability_start: datetime
    availability_end: datetime
    max_vehicle_size: VehicleSize
    description: str
    image_url: Optional[str] = None

class ParkingSpotCreate(ParkingSpotBase):
    owner_id: str
    owner_name: str

class ParkingSpotUpdate(BaseModel):
    address: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    hourly_rate: Optional[float] = None
    is_available: Optional[bool] = None
    availability_start: Optional[datetime] = None
    availability_end: Optional[datetime] = None
    max_vehicle_size: Optional[VehicleSize] = None
    description: Optional[str] = None
    image_url: Optional[str] = None

class ParkingSpot(ParkingSpotBase):
    id: str
    owner_id: str
    owner_name: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

# Booking models
class BookingBase(BaseModel):
    spot_id: str
    start_time: datetime
    end_time: datetime
    message: Optional[str] = None

class BookingCreate(BookingBase):
    finder_id: str
    finder_name: str
    finder_email: str

class BookingUpdate(BaseModel):
    status: Optional[BookingStatus] = None
    owner_response: Optional[str] = None
    responded_at: Optional[datetime] = None

class Booking(BookingBase):
    id: str
    finder_id: str
    finder_name: str
    finder_email: str
    total_amount: float
    status: BookingStatus
    created_at: datetime
    owner_response: Optional[str] = None
    responded_at: Optional[datetime] = None

    class Config:
        from_attributes = True

# Response models
class BookingResponse(BaseModel):
    booking: Booking
    spot: ParkingSpot

class BookingRequestResponse(BaseModel):
    booking: Booking
    spot: ParkingSpot
    owner: User

# Location models
class LocationQuery(BaseModel):
    latitude: float
    longitude: float
    radius: Optional[float] = 5000  # meters

# Search models
class ParkingSpotSearch(BaseModel):
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    radius: Optional[float] = None
    max_price: Optional[float] = None
    vehicle_size: Optional[VehicleSize] = None
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None

# API Response models
class APIResponse(BaseModel):
    success: bool
    message: str
    data: Optional[dict] = None

class PaginatedResponse(BaseModel):
    items: List[dict]
    total: int
    page: int
    size: int
    pages: int

from fastapi import APIRouter, HTTPException, Depends, status, Query
from typing import List, Optional
from app.models.models import (
    ParkingSpotCreate, 
    ParkingSpotUpdate, 
    ParkingSpot, 
    ParkingSpotSearch,
    LocationQuery,
    APIResponse,
    PaginatedResponse
)
from app.services.firebase_service import FirebaseService
from app.dependencies import verify_token
from datetime import datetime
import math

router = APIRouter()
firebase_service = FirebaseService()

@router.post("/", response_model=APIResponse)
async def create_parking_spot(
    spot_data: ParkingSpotCreate,
    token_data: dict = Depends(verify_token)
):
    """
    Create a new parking spot
    """
    try:
        firebase_uid = token_data.get("uid")
        
        # Verify ownership
        if spot_data.owner_id != firebase_uid:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only create parking spots for yourself"
            )
        
        # Prepare spot data
        spot_dict = {
            "address": spot_data.address,
            "latitude": spot_data.latitude,
            "longitude": spot_data.longitude,
            "hourly_rate": spot_data.hourly_rate,
            "is_available": spot_data.is_available,
            "availability_start": spot_data.availability_start,
            "availability_end": spot_data.availability_end,
            "max_vehicle_size": spot_data.max_vehicle_size.value,
            "description": spot_data.description,
            "image_url": spot_data.image_url,
            "owner_id": spot_data.owner_id,
            "owner_name": spot_data.owner_name,
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow()
        }
        
        # Create parking spot
        spot_id = await firebase_service.create_parking_spot(spot_dict)
        
        return APIResponse(
            success=True,
            message="Parking spot created successfully",
            data={"spot_id": spot_id}
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create parking spot: {str(e)}"
        )

@router.get("/", response_model=APIResponse)
async def get_parking_spots(
    search: Optional[ParkingSpotSearch] = None,
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100)
):
    """
    Get parking spots with optional search filters
    """
    try:
        # Get all available spots
        spots = await firebase_service.get_available_parking_spots()
        
        # Apply search filters
        if search:
            filtered_spots = []
            for spot in spots:
                # Location filter
                if search.latitude and search.longitude and search.radius:
                    distance = calculate_distance(
                        search.latitude, search.longitude,
                        spot["latitude"], spot["longitude"]
                    )
                    if distance > search.radius:
                        continue
                
                # Price filter
                if search.max_price and spot["hourly_rate"] > search.max_price:
                    continue
                
                # Vehicle size filter
                if search.vehicle_size and spot["max_vehicle_size"] != search.vehicle_size.value:
                    continue
                
                # Time availability filter
                if search.start_time and search.end_time:
                    if (spot["availability_start"] > search.start_time or 
                        spot["availability_end"] < search.end_time):
                        continue
                
                filtered_spots.append(spot)
            spots = filtered_spots
        
        # Pagination
        total = len(spots)
        start_idx = (page - 1) * size
        end_idx = start_idx + size
        paginated_spots = spots[start_idx:end_idx]
        
        return APIResponse(
            success=True,
            message="Parking spots retrieved successfully",
            data={
                "spots": paginated_spots,
                "pagination": {
                    "total": total,
                    "page": page,
                    "size": size,
                    "pages": math.ceil(total / size)
                }
            }
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get parking spots: {str(e)}"
        )

@router.get("/nearby", response_model=APIResponse)
async def get_nearby_parking_spots(
    latitude: float = Query(..., ge=-90, le=90),
    longitude: float = Query(..., ge=-180, le=180),
    radius: float = Query(5000, ge=100, le=50000)
):
    """
    Get parking spots near a location
    """
    try:
        # Get all available spots
        spots = await firebase_service.get_available_parking_spots()
        
        # Filter by distance
        nearby_spots = []
        for spot in spots:
            distance = calculate_distance(
                latitude, longitude,
                spot["latitude"], spot["longitude"]
            )
            if distance <= radius:
                spot["distance"] = distance
                nearby_spots.append(spot)
        
        # Sort by distance
        nearby_spots.sort(key=lambda x: x["distance"])
        
        return APIResponse(
            success=True,
            message="Nearby parking spots retrieved successfully",
            data={"spots": nearby_spots}
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get nearby parking spots: {str(e)}"
        )

@router.get("/my-spots", response_model=APIResponse)
async def get_my_parking_spots(token_data: dict = Depends(verify_token)):
    """
    Get parking spots owned by the current user
    """
    try:
        firebase_uid = token_data.get("uid")
        spots = await firebase_service.get_parking_spots_by_owner(firebase_uid)
        
        return APIResponse(
            success=True,
            message="Your parking spots retrieved successfully",
            data={"spots": spots}
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get your parking spots: {str(e)}"
        )

@router.get("/{spot_id}", response_model=APIResponse)
async def get_parking_spot(spot_id: str):
    """
    Get a specific parking spot by ID
    """
    try:
        spot = await firebase_service.get_parking_spot(spot_id)
        
        if not spot:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Parking spot not found"
            )
        
        return APIResponse(
            success=True,
            message="Parking spot retrieved successfully",
            data={"spot": spot}
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get parking spot: {str(e)}"
        )

@router.put("/{spot_id}", response_model=APIResponse)
async def update_parking_spot(
    spot_id: str,
    spot_update: ParkingSpotUpdate,
    token_data: dict = Depends(verify_token)
):
    """
    Update a parking spot
    """
    try:
        firebase_uid = token_data.get("uid")
        
        # Get existing spot
        existing_spot = await firebase_service.get_parking_spot(spot_id)
        if not existing_spot:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Parking spot not found"
            )
        
        # Verify ownership
        if existing_spot["owner_id"] != firebase_uid:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only update your own parking spots"
            )
        
        # Prepare update data
        update_data = {}
        if spot_update.address is not None:
            update_data["address"] = spot_update.address
        if spot_update.latitude is not None:
            update_data["latitude"] = spot_update.latitude
        if spot_update.longitude is not None:
            update_data["longitude"] = spot_update.longitude
        if spot_update.hourly_rate is not None:
            update_data["hourly_rate"] = spot_update.hourly_rate
        if spot_update.is_available is not None:
            update_data["is_available"] = spot_update.is_available
        if spot_update.availability_start is not None:
            update_data["availability_start"] = spot_update.availability_start
        if spot_update.availability_end is not None:
            update_data["availability_end"] = spot_update.availability_end
        if spot_update.max_vehicle_size is not None:
            update_data["max_vehicle_size"] = spot_update.max_vehicle_size.value
        if spot_update.description is not None:
            update_data["description"] = spot_update.description
        if spot_update.image_url is not None:
            update_data["image_url"] = spot_update.image_url
        
        update_data["updated_at"] = datetime.utcnow()
        
        # Update parking spot
        success = await firebase_service.update_parking_spot(spot_id, update_data)
        if not success:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update parking spot"
            )
        
        # Get updated spot
        updated_spot = await firebase_service.get_parking_spot(spot_id)
        
        return APIResponse(
            success=True,
            message="Parking spot updated successfully",
            data={"spot": updated_spot}
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update parking spot: {str(e)}"
        )

@router.delete("/{spot_id}", response_model=APIResponse)
async def delete_parking_spot(
    spot_id: str,
    token_data: dict = Depends(verify_token)
):
    """
    Delete a parking spot
    """
    try:
        firebase_uid = token_data.get("uid")
        
        # Get existing spot
        existing_spot = await firebase_service.get_parking_spot(spot_id)
        if not existing_spot:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Parking spot not found"
            )
        
        # Verify ownership
        if existing_spot["owner_id"] != firebase_uid:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only delete your own parking spots"
            )
        
        # Delete parking spot
        success = await firebase_service.delete_parking_spot(spot_id)
        if not success:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to delete parking spot"
            )
        
        return APIResponse(
            success=True,
            message="Parking spot deleted successfully"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete parking spot: {str(e)}"
        )

def calculate_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Calculate distance between two points using Haversine formula
    Returns distance in meters
    """
    import math
    
    R = 6371000  # Earth's radius in meters
    
    lat1_rad = math.radians(lat1)
    lon1_rad = math.radians(lon1)
    lat2_rad = math.radians(lat2)
    lon2_rad = math.radians(lon2)
    
    dlat = lat2_rad - lat1_rad
    dlon = lon2_rad - lon1_rad
    
    a = (math.sin(dlat/2)**2 + 
         math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(dlon/2)**2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
    
    return R * c

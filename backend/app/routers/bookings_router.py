from fastapi import APIRouter, HTTPException, Depends, status
from app.models.models import (
    BookingCreate, 
    BookingUpdate, 
    Booking, 
    APIResponse
)
from app.services.firebase_service import FirebaseService
from app.dependencies import verify_token
from datetime import datetime

router = APIRouter()
firebase_service = FirebaseService()

@router.post("/", response_model=APIResponse)
async def create_booking_request(
    booking_data: BookingCreate,
    token_data: dict = Depends(verify_token)
):
    """
    Create a new booking request
    """
    try:
        firebase_uid = token_data.get("uid")
        
        # Verify the requester is the authenticated user
        if booking_data.finder_id != firebase_uid:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only create booking requests for yourself"
            )
        
        # Verify the parking spot exists and is available
        spot = await firebase_service.get_parking_spot(booking_data.spot_id)
        if not spot:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Parking spot not found"
            )
        
        if not spot["is_available"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Parking spot is not available"
            )
        
        # Check if the requested time is within spot availability
        if (booking_data.start_time < spot["availability_start"] or 
            booking_data.end_time > spot["availability_end"]):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Requested time is outside spot availability"
            )
        
        # Calculate total amount
        hours = (booking_data.end_time - booking_data.start_time).total_seconds() / 3600
        total_amount = hours * spot["hourly_rate"]
        
        # Prepare booking data
        booking_dict = {
            "spot_id": booking_data.spot_id,
            "finder_id": booking_data.finder_id,
            "finder_name": booking_data.finder_name,
            "finder_email": booking_data.finder_email,
            "start_time": booking_data.start_time,
            "end_time": booking_data.end_time,
            "total_amount": total_amount,
            "status": "pending",
            "message": booking_data.message,
            "created_at": datetime.utcnow()
        }
        
        # Create booking request
        booking_id = await firebase_service.create_booking(booking_dict)
        
        return APIResponse(
            success=True,
            message="Booking request created successfully",
            data={"booking_id": booking_id}
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create booking request: {str(e)}"
        )

@router.get("/my-bookings", response_model=APIResponse)
async def get_my_bookings(token_data: dict = Depends(verify_token)):
    """
    Get all bookings for the current user (as finder)
    """
    try:
        firebase_uid = token_data.get("uid")
        bookings = await firebase_service.get_user_bookings(firebase_uid)
        
        return APIResponse(
            success=True,
            message="Your bookings retrieved successfully",
            data={"bookings": bookings}
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get your bookings: {str(e)}"
        )

@router.get("/pending-requests", response_model=APIResponse)
async def get_pending_booking_requests(token_data: dict = Depends(verify_token)):
    """
    Get pending booking requests for spots owned by the current user
    """
    try:
        firebase_uid = token_data.get("uid")
        pending_requests = await firebase_service.get_pending_bookings_for_owner(firebase_uid)
        
        return APIResponse(
            success=True,
            message="Pending booking requests retrieved successfully",
            data={"requests": pending_requests}
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get pending requests: {str(e)}"
        )

@router.get("/{booking_id}", response_model=APIResponse)
async def get_booking(booking_id: str, token_data: dict = Depends(verify_token)):
    """
    Get a specific booking by ID
    """
    try:
        firebase_uid = token_data.get("uid")
        
        booking = await firebase_service.get_booking(booking_id)
        if not booking:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Booking not found"
            )
        
        # Verify user has access to this booking
        if booking["finder_id"] != firebase_uid:
            # Check if user owns the spot
            spot = await firebase_service.get_parking_spot(booking["spot_id"])
            if not spot or spot["owner_id"] != firebase_uid:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="You don't have access to this booking"
                )
        
        return APIResponse(
            success=True,
            message="Booking retrieved successfully",
            data={"booking": booking}
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get booking: {str(e)}"
        )

@router.put("/{booking_id}/approve", response_model=APIResponse)
async def approve_booking_request(
    booking_id: str,
    response_message: str = None,
    token_data: dict = Depends(verify_token)
):
    """
    Approve a booking request (spot owner only)
    """
    try:
        firebase_uid = token_data.get("uid")
        
        # Get booking
        booking = await firebase_service.get_booking(booking_id)
        if not booking:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Booking not found"
            )
        
        # Verify user owns the spot
        spot = await firebase_service.get_parking_spot(booking["spot_id"])
        if not spot or spot["owner_id"] != firebase_uid:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only approve requests for your own spots"
            )
        
        # Check if booking is pending
        if booking["status"] != "pending":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Can only approve pending booking requests"
            )
        
        # Update booking status
        update_data = {
            "status": "approved",
            "owner_response": response_message,
            "responded_at": datetime.utcnow()
        }
        
        success = await firebase_service.update_booking(booking_id, update_data)
        if not success:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to approve booking request"
            )
        
        # Get updated booking
        updated_booking = await firebase_service.get_booking(booking_id)
        
        return APIResponse(
            success=True,
            message="Booking request approved successfully",
            data={"booking": updated_booking}
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to approve booking request: {str(e)}"
        )

@router.put("/{booking_id}/reject", response_model=APIResponse)
async def reject_booking_request(
    booking_id: str,
    response_message: str = None,
    token_data: dict = Depends(verify_token)
):
    """
    Reject a booking request (spot owner only)
    """
    try:
        firebase_uid = token_data.get("uid")
        
        # Get booking
        booking = await firebase_service.get_booking(booking_id)
        if not booking:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Booking not found"
            )
        
        # Verify user owns the spot
        spot = await firebase_service.get_parking_spot(booking["spot_id"])
        if not spot or spot["owner_id"] != firebase_uid:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only reject requests for your own spots"
            )
        
        # Check if booking is pending
        if booking["status"] != "pending":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Can only reject pending booking requests"
            )
        
        # Update booking status
        update_data = {
            "status": "rejected",
            "owner_response": response_message,
            "responded_at": datetime.utcnow()
        }
        
        success = await firebase_service.update_booking(booking_id, update_data)
        if not success:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to reject booking request"
            )
        
        # Get updated booking
        updated_booking = await firebase_service.get_booking(booking_id)
        
        return APIResponse(
            success=True,
            message="Booking request rejected successfully",
            data={"booking": updated_booking}
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to reject booking request: {str(e)}"
        )

@router.put("/{booking_id}/cancel", response_model=APIResponse)
async def cancel_booking_request(
    booking_id: str,
    token_data: dict = Depends(verify_token)
):
    """
    Cancel a booking request (finder only)
    """
    try:
        firebase_uid = token_data.get("uid")
        
        # Get booking
        booking = await firebase_service.get_booking(booking_id)
        if not booking:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Booking not found"
            )
        
        # Verify user is the finder
        if booking["finder_id"] != firebase_uid:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only cancel your own booking requests"
            )
        
        # Check if booking can be cancelled
        if booking["status"] not in ["pending", "approved"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Can only cancel pending or approved booking requests"
            )
        
        # Update booking status
        update_data = {
            "status": "cancelled",
            "responded_at": datetime.utcnow()
        }
        
        success = await firebase_service.update_booking(booking_id, update_data)
        if not success:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to cancel booking request"
            )
        
        # Get updated booking
        updated_booking = await firebase_service.get_booking(booking_id)
        
        return APIResponse(
            success=True,
            message="Booking request cancelled successfully",
            data={"booking": updated_booking}
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to cancel booking request: {str(e)}"
        )

@router.delete("/{booking_id}", response_model=APIResponse)
async def delete_booking(
    booking_id: str,
    token_data: dict = Depends(verify_token)
):
    """
    Delete a booking (only for cancelled or completed bookings)
    """
    try:
        firebase_uid = token_data.get("uid")
        
        # Get booking
        booking = await firebase_service.get_booking(booking_id)
        if not booking:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Booking not found"
            )
        
        # Verify user has access
        if booking["finder_id"] != firebase_uid:
            spot = await firebase_service.get_parking_spot(booking["spot_id"])
            if not spot or spot["owner_id"] != firebase_uid:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="You don't have access to this booking"
                )
        
        # Check if booking can be deleted
        if booking["status"] not in ["cancelled", "completed"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Can only delete cancelled or completed bookings"
            )
        
        # Delete booking
        success = await firebase_service.delete_booking(booking_id)
        if not success:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to delete booking"
            )
        
        return APIResponse(
            success=True,
            message="Booking deleted successfully"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete booking: {str(e)}"
        )

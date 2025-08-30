from fastapi import APIRouter, HTTPException, Depends, status
from app.models.models import UserUpdate, APIResponse
from app.services.firebase_service import FirebaseService
from app.dependencies import verify_token

router = APIRouter()
firebase_service = FirebaseService()

@router.get("/profile", response_model=APIResponse)
async def get_user_profile(token_data: dict = Depends(verify_token)):
    """
    Get user profile
    """
    try:
        firebase_uid = token_data.get("uid")
        user = await firebase_service.get_user(firebase_uid)
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        return APIResponse(
            success=True,
            message="Profile retrieved successfully",
            data={"user": user}
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get profile: {str(e)}"
        )

@router.put("/profile", response_model=APIResponse)
async def update_user_profile(
    user_update: UserUpdate,
    token_data: dict = Depends(verify_token)
):
    """
    Update user profile
    """
    try:
        firebase_uid = token_data.get("uid")
        
        # Check if user exists
        existing_user = await firebase_service.get_user(firebase_uid)
        if not existing_user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        # Prepare update data
        update_data = {}
        if user_update.name is not None:
            update_data["name"] = user_update.name
        if user_update.phone_number is not None:
            update_data["phone_number"] = user_update.phone_number
        if user_update.profile_image_url is not None:
            update_data["profile_image_url"] = user_update.profile_image_url
        if user_update.role is not None:
            update_data["role"] = user_update.role.value
        
        if not update_data:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No fields to update"
            )
        
        # Update user
        success = await firebase_service.update_user(firebase_uid, update_data)
        if not success:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update profile"
            )
        
        # Get updated user
        updated_user = await firebase_service.get_user(firebase_uid)
        
        return APIResponse(
            success=True,
            message="Profile updated successfully",
            data={"user": updated_user}
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update profile: {str(e)}"
        )

@router.delete("/profile", response_model=APIResponse)
async def delete_user_profile(token_data: dict = Depends(verify_token)):
    """
    Delete user profile
    """
    try:
        firebase_uid = token_data.get("uid")
        
        # Check if user exists
        existing_user = await firebase_service.get_user(firebase_uid)
        if not existing_user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        # Delete user
        success = await firebase_service.delete_user(firebase_uid)
        if not success:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to delete profile"
            )
        
        return APIResponse(
            success=True,
            message="Profile deleted successfully"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete profile: {str(e)}"
        )

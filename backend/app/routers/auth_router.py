from fastapi import APIRouter, HTTPException, Depends, status
from firebase_admin import auth
from app.models.models import UserCreate, User, APIResponse
from app.services.firebase_service import FirebaseService
from app.dependencies import verify_token
from datetime import datetime

router = APIRouter()
firebase_service = FirebaseService()

@router.post("/register", response_model=APIResponse)
async def register_user(user_data: UserCreate):
    """
    Register a new user
    """
    try:
        # Verify the Firebase UID is valid
        try:
            firebase_user = auth.get_user(user_data.firebase_uid)
        except Exception:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid Firebase UID"
            )
        
        # Check if user already exists
        existing_user = await firebase_service.get_user(user_data.firebase_uid)
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="User already exists"
            )
        
        # Create user data
        user_dict = {
            "uid": user_data.firebase_uid,
            "email": user_data.email,
            "name": user_data.name,
            "phone_number": user_data.phone_number,
            "profile_image_url": user_data.profile_image_url,
            "role": user_data.role.value,
            "created_at": datetime.utcnow(),
            "last_login_at": datetime.utcnow()
        }
        
        # Save to Firestore
        await firebase_service.create_user(user_dict)
        
        return APIResponse(
            success=True,
            message="User registered successfully",
            data={"user_id": user_data.firebase_uid}
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Registration failed: {str(e)}"
        )

@router.post("/login", response_model=APIResponse)
async def login_user(firebase_uid: str):
    """
    Login user and update last login time
    """
    try:
        # Get user from Firestore
        user = await firebase_service.get_user(firebase_uid)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        # Update last login time
        await firebase_service.update_user(firebase_uid, {
            "last_login_at": datetime.utcnow()
        })
        
        return APIResponse(
            success=True,
            message="Login successful",
            data={"user": user}
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Login failed: {str(e)}"
        )

@router.get("/me", response_model=APIResponse)
async def get_current_user(token_data: dict = Depends(verify_token)):
    """
    Get current user information
    """
    try:
        firebase_uid = token_data.get("uid")
        if not firebase_uid:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token"
            )
        
        user = await firebase_service.get_user(firebase_uid)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        return APIResponse(
            success=True,
            message="User retrieved successfully",
            data={"user": user}
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get user: {str(e)}"
        )

@router.delete("/logout", response_model=APIResponse)
async def logout_user():
    """
    Logout user (client-side token invalidation)
    """
    return APIResponse(
        success=True,
        message="Logout successful"
    )

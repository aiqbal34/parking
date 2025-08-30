from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

from app.routers import auth_router, parking_spots_router, bookings_router, users_router
from app.services.firebase_service import initialize_firebase
from app.dependencies import verify_token

# Initialize FastAPI app
app = FastAPI(
    title="Parking App API",
    description="Backend API for the parking spot booking application",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your frontend domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize Firebase
initialize_firebase()

# Include routers
app.include_router(
    auth_router.router,
    prefix="/api/auth",
    tags=["Authentication"]
)

app.include_router(
    users_router.router,
    prefix="/api/users",
    tags=["Users"],
    dependencies=[Depends(verify_token)]
)

app.include_router(
    parking_spots_router.router,
    prefix="/api/parking-spots",
    tags=["Parking Spots"],
    dependencies=[Depends(verify_token)]
)

app.include_router(
    bookings_router.router,
    prefix="/api/bookings",
    tags=["Bookings"],
    dependencies=[Depends(verify_token)]
)

@app.get("/")
async def root():
    return {"message": "Parking App API is running!"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)

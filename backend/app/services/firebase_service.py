import firebase_admin
from firebase_admin import credentials, firestore
import os
from typing import Optional, Dict, Any
import json

# Global Firestore client
db: Optional[firestore.Client] = None

def initialize_firebase():
    """Initialize Firebase Admin SDK"""
    global db
    
    try:
        # Check if Firebase is already initialized
        firebase_admin.get_app()
        print("Firebase already initialized")
    except ValueError:
        # Initialize Firebase
        if os.getenv("FIREBASE_SERVICE_ACCOUNT_KEY"):
            # Use service account key from environment variable
            service_account_info = json.loads(os.getenv("FIREBASE_SERVICE_ACCOUNT_KEY"))
            cred = credentials.Certificate(service_account_info)
        elif os.path.exists("firebase-service-account.json"):
            # Use service account key file
            cred = credentials.Certificate("firebase-service-account.json")
        else:
            # Use default credentials (for local development)
            cred = credentials.ApplicationDefault()
        
        firebase_admin.initialize_app(cred)
        print("Firebase initialized successfully")
    
    # Initialize Firestore client
    db = firestore.client()
    print("Firestore client initialized")

def get_db() -> firestore.Client:
    """Get Firestore database client"""
    if db is None:
        raise Exception("Firebase not initialized. Call initialize_firebase() first.")
    return db

class FirebaseService:
    """Service class for Firebase operations"""
    
    def __init__(self):
        self._db = None
    
    @property
    def db(self):
        """Lazy initialization of Firestore client"""
        if self._db is None:
            self._db = get_db()
        return self._db
    
    # User operations
    async def create_user(self, user_data: Dict[str, Any]) -> str:
        """Create a new user in Firestore"""
        doc_ref = self.db.collection('users').document(user_data['uid'])
        doc_ref.set(user_data)
        return doc_ref.id
    
    async def get_user(self, uid: str) -> Optional[Dict[str, Any]]:
        """Get user by UID"""
        doc = self.db.collection('users').document(uid).get()
        if doc.exists:
            return doc.to_dict()
        return None
    
    async def update_user(self, uid: str, user_data: Dict[str, Any]) -> bool:
        """Update user data"""
        try:
            self.db.collection('users').document(uid).update(user_data)
            return True
        except Exception:
            return False
    
    async def delete_user(self, uid: str) -> bool:
        """Delete user"""
        try:
            self.db.collection('users').document(uid).delete()
            return True
        except Exception:
            return False
    
    # Parking spot operations
    async def create_parking_spot(self, spot_data: Dict[str, Any]) -> str:
        """Create a new parking spot"""
        doc_ref = self.db.collection('parking_spots').document()
        spot_data['id'] = doc_ref.id
        doc_ref.set(spot_data)
        return doc_ref.id
    
    async def get_parking_spot(self, spot_id: str) -> Optional[Dict[str, Any]]:
        """Get parking spot by ID"""
        doc = self.db.collection('parking_spots').document(spot_id).get()
        if doc.exists:
            return doc.to_dict()
        return None
    
    async def get_parking_spots_by_owner(self, owner_id: str) -> list:
        """Get all parking spots owned by a user"""
        docs = self.db.collection('parking_spots').where('owner_id', '==', owner_id).stream()
        return [doc.to_dict() for doc in docs]
    
    async def get_available_parking_spots(self) -> list:
        """Get all available parking spots"""
        docs = self.db.collection('parking_spots').where('is_available', '==', True).stream()
        return [doc.to_dict() for doc in docs]
    
    async def update_parking_spot(self, spot_id: str, spot_data: Dict[str, Any]) -> bool:
        """Update parking spot"""
        try:
            self.db.collection('parking_spots').document(spot_id).update(spot_data)
            return True
        except Exception:
            return False
    
    async def delete_parking_spot(self, spot_id: str) -> bool:
        """Delete parking spot"""
        try:
            self.db.collection('parking_spots').document(spot_id).delete()
            return True
        except Exception:
            return False
    
    # Booking operations
    async def create_booking(self, booking_data: Dict[str, Any]) -> str:
        """Create a new booking request"""
        doc_ref = self.db.collection('bookings').document()
        booking_data['id'] = doc_ref.id
        doc_ref.set(booking_data)
        return doc_ref.id
    
    async def get_booking(self, booking_id: str) -> Optional[Dict[str, Any]]:
        """Get booking by ID"""
        doc = self.db.collection('bookings').document(booking_id).get()
        if doc.exists:
            return doc.to_dict()
        return None
    
    async def get_user_bookings(self, user_id: str) -> list:
        """Get all bookings for a user (as finder)"""
        docs = self.db.collection('bookings').where('finder_id', '==', user_id).stream()
        return [doc.to_dict() for doc in docs]
    
    async def get_pending_bookings_for_owner(self, owner_id: str) -> list:
        """Get pending booking requests for spots owned by a user"""
        # First get all spots owned by the user
        spots = await self.get_parking_spots_by_owner(owner_id)
        spot_ids = [spot['id'] for spot in spots]
        
        if not spot_ids:
            return []
        
        # Get pending bookings for these spots
        pending_bookings = []
        for spot_id in spot_ids:
            docs = self.db.collection('bookings').where('spot_id', '==', spot_id).where('status', '==', 'pending').stream()
            pending_bookings.extend([doc.to_dict() for doc in docs])
        
        return pending_bookings
    
    async def update_booking(self, booking_id: str, booking_data: Dict[str, Any]) -> bool:
        """Update booking"""
        try:
            self.db.collection('bookings').document(booking_id).update(booking_data)
            return True
        except Exception:
            return False
    
    async def delete_booking(self, booking_id: str) -> bool:
        """Delete booking"""
        try:
            self.db.collection('bookings').document(booking_id).delete()
            return True
        except Exception:
            return False

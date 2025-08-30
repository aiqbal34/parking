# Parking App Backend

A FastAPI backend for the parking spot booking application with Firebase integration.

## Features

- **User Authentication**: Firebase Authentication integration
- **Parking Spot Management**: CRUD operations for parking spots
- **Booking System**: Request-based booking with approval workflow
- **Real-time Data**: Firebase Firestore for data storage
- **RESTful API**: Clean and documented API endpoints
- **CORS Support**: Cross-origin resource sharing enabled

## Tech Stack

- **FastAPI**: Modern, fast web framework for building APIs
- **Firebase Admin SDK**: Authentication and Firestore database
- **Pydantic**: Data validation and serialization
- **Uvicorn**: ASGI server for running the application

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register a new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/me` - Get current user info
- `DELETE /api/auth/logout` - Logout user

### Users
- `GET /api/users/profile` - Get user profile
- `PUT /api/users/profile` - Update user profile
- `DELETE /api/users/profile` - Delete user profile

### Parking Spots
- `POST /api/parking-spots/` - Create a new parking spot
- `GET /api/parking-spots/` - Get all parking spots (with filters)
- `GET /api/parking-spots/nearby` - Get nearby parking spots
- `GET /api/parking-spots/my-spots` - Get user's parking spots
- `GET /api/parking-spots/{spot_id}` - Get specific parking spot
- `PUT /api/parking-spots/{spot_id}` - Update parking spot
- `DELETE /api/parking-spots/{spot_id}` - Delete parking spot

### Bookings
- `POST /api/bookings/` - Create booking request
- `GET /api/bookings/my-bookings` - Get user's bookings
- `GET /api/bookings/pending-requests` - Get pending requests for user's spots
- `GET /api/bookings/{booking_id}` - Get specific booking
- `PUT /api/bookings/{booking_id}/approve` - Approve booking request
- `PUT /api/bookings/{booking_id}/reject` - Reject booking request
- `PUT /api/bookings/{booking_id}/cancel` - Cancel booking request
- `DELETE /api/bookings/{booking_id}` - Delete booking

## Setup Instructions

### Prerequisites

1. Python 3.8 or higher
2. Firebase project with Authentication and Firestore enabled
3. Firebase service account key

### Local Development

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd backend
   ```

2. **Create virtual environment**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Set up Firebase**
   - Go to Firebase Console
   - Create a new project or use existing one
   - Enable Authentication and Firestore
   - Generate a service account key
   - Save the key as `firebase-service-account.json` in the backend directory

5. **Set environment variables**
   ```bash
   export FIREBASE_SERVICE_ACCOUNT_KEY='{"your":"service_account_json"}'
   ```

6. **Run the application**
   ```bash
   python main.py
   ```

   Or with uvicorn:
   ```bash
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

7. **Access the API**
   - API: http://localhost:8000
   - Documentation: http://localhost:8000/docs
   - ReDoc: http://localhost:8000/redoc

### Deployment to Vercel

1. **Install Vercel CLI**
   ```bash
   npm i -g vercel
   ```

2. **Set up environment variables in Vercel**
   ```bash
   vercel env add FIREBASE_SERVICE_ACCOUNT_KEY
   ```

3. **Deploy**
   ```bash
   vercel --prod
   ```

### Environment Variables

- `FIREBASE_SERVICE_ACCOUNT_KEY`: Firebase service account JSON (required)

## API Documentation

Once the server is running, you can access:
- **Swagger UI**: `/docs` - Interactive API documentation
- **ReDoc**: `/redoc` - Alternative API documentation
- **OpenAPI JSON**: `/openapi.json` - OpenAPI specification

## Authentication

The API uses Firebase Authentication. All protected endpoints require a valid Firebase ID token in the Authorization header:

```
Authorization: Bearer <firebase_id_token>
```

## Data Models

### User
```json
{
  "uid": "string",
  "email": "string",
  "name": "string",
  "phone_number": "string?",
  "profile_image_url": "string?",
  "role": "finder|renter|both",
  "created_at": "datetime",
  "last_login_at": "datetime?"
}
```

### Parking Spot
```json
{
  "id": "string",
  "address": "string",
  "latitude": "number",
  "longitude": "number",
  "hourly_rate": "number",
  "is_available": "boolean",
  "availability_start": "datetime",
  "availability_end": "datetime",
  "max_vehicle_size": "compact|midsize|large|suv|any",
  "description": "string",
  "image_url": "string?",
  "owner_id": "string",
  "owner_name": "string",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

### Booking
```json
{
  "id": "string",
  "spot_id": "string",
  "finder_id": "string",
  "finder_name": "string",
  "finder_email": "string",
  "start_time": "datetime",
  "end_time": "datetime",
  "total_amount": "number",
  "status": "pending|approved|rejected|confirmed|completed|cancelled",
  "message": "string?",
  "owner_response": "string?",
  "created_at": "datetime",
  "responded_at": "datetime?"
}
```

## Error Handling

The API returns consistent error responses:

```json
{
  "detail": "Error message"
}
```

Common HTTP status codes:
- `200`: Success
- `201`: Created
- `400`: Bad Request
- `401`: Unauthorized
- `403`: Forbidden
- `404`: Not Found
- `409`: Conflict
- `500`: Internal Server Error

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License.

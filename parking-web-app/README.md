# Parking Web App

A modern web application for finding and renting parking spots, built with Next.js, TypeScript, and Firebase. This is the web version of the iOS parking app, featuring all the same functionality with a responsive design.

## Features

### 🔍 Find Parking
- Interactive map view with Leaflet
- List view with filtering options
- Real-time location services
- Advanced filters (price, vehicle size, radius)
- Detailed spot information and booking

### 🏠 Rent Out Spots
- Add and manage parking spots
- Set availability times and pricing
- Handle booking requests
- Approve/reject requests with messages
- View booking history and earnings

### 👤 User Management
- Firebase Authentication
- User profiles and settings
- Booking history
- Account management

### 📱 Responsive Design
- Mobile-first approach
- Works on all device sizes
- Modern UI with Tailwind CSS
- Smooth animations and transitions

## Tech Stack

- **Frontend**: Next.js 14, React 18, TypeScript
- **Styling**: Tailwind CSS, Headless UI
- **Authentication**: Firebase Auth
- **Database**: Firebase Firestore
- **Maps**: Leaflet with React-Leaflet
- **State Management**: React Context + Hooks
- **HTTP Client**: Axios
- **Icons**: Heroicons, Lucide React
- **Notifications**: React Hot Toast
- **Date Handling**: date-fns

## Getting Started

### Prerequisites

- Node.js 18+ 
- npm or yarn
- Firebase project
- Backend API (FastAPI)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd parking-web-app
```

2. Install dependencies:
```bash
npm install
```

3. Set up environment variables:
```bash
cp env.example .env.local
```

4. Configure your `.env.local` file:
```env
NEXT_PUBLIC_FIREBASE_API_KEY=your_firebase_api_key
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
NEXT_PUBLIC_FIREBASE_PROJECT_ID=your_project_id
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=your_project.appspot.com
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=your_sender_id
NEXT_PUBLIC_FIREBASE_APP_ID=your_app_id
NEXT_PUBLIC_API_BASE_URL=https://your-backend-api.vercel.app/api
```

5. Run the development server:
```bash
npm run dev
```

6. Open [http://localhost:3000](http://localhost:3000) in your browser.

## Project Structure

```
parking-web-app/
├── app/                    # Next.js app directory
│   ├── dashboard/         # Dashboard page
│   ├── globals.css        # Global styles
│   ├── layout.tsx         # Root layout
│   └── page.tsx           # Home page
├── components/            # React components
│   ├── AuthPage.tsx       # Authentication page
│   ├── FinderView.tsx     # Find parking view
│   ├── RenterView.tsx     # Rent out spots view
│   ├── MapView.tsx        # Interactive map
│   ├── SpotDetailView.tsx # Spot details modal
│   └── ...                # Other components
├── lib/                   # Utilities and services
│   ├── firebase.ts        # Firebase configuration
│   ├── auth-context.tsx   # Authentication context
│   └── api.ts             # API service layer
├── types/                 # TypeScript type definitions
│   └── index.ts           # All type definitions
└── ...                    # Configuration files
```

## Key Components

### Authentication
- Firebase Authentication integration
- Email/password sign up and sign in
- Protected routes and user context
- Automatic token refresh

### Map Integration
- Leaflet maps with custom markers
- Real-time location services
- Interactive spot selection
- Distance calculations

### API Integration
- RESTful API communication
- Automatic authentication headers
- Error handling and retry logic
- Type-safe API calls

### State Management
- React Context for global state
- Local state with useState/useEffect
- Optimistic updates
- Error boundary handling

## Deployment

### Vercel (Recommended)

1. Push your code to GitHub
2. Connect your repository to Vercel
3. Set environment variables in Vercel dashboard
4. Deploy automatically on push

### Manual Deployment

1. Build the application:
```bash
npm run build
```

2. Start the production server:
```bash
npm start
```

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `NEXT_PUBLIC_FIREBASE_API_KEY` | Firebase API key | Yes |
| `NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN` | Firebase auth domain | Yes |
| `NEXT_PUBLIC_FIREBASE_PROJECT_ID` | Firebase project ID | Yes |
| `NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET` | Firebase storage bucket | Yes |
| `NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID` | Firebase messaging sender ID | Yes |
| `NEXT_PUBLIC_FIREBASE_APP_ID` | Firebase app ID | Yes |
| `NEXT_PUBLIC_API_BASE_URL` | Backend API base URL | Yes |

## API Endpoints

The app connects to a FastAPI backend with the following main endpoints:

- `GET /api/parking-spots/` - Get all parking spots
- `GET /api/parking-spots/nearby` - Get nearby spots
- `GET /api/parking-spots/my-spots` - Get user's spots
- `POST /api/parking-spots/` - Create new spot
- `PUT /api/parking-spots/{id}` - Update spot
- `DELETE /api/parking-spots/{id}` - Delete spot
- `POST /api/bookings/` - Create booking request
- `GET /api/bookings/my-bookings` - Get user's bookings
- `GET /api/bookings/pending-requests` - Get pending requests
- `PUT /api/bookings/{id}/approve` - Approve booking
- `PUT /api/bookings/{id}/reject` - Reject booking

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For support, please contact the development team or create an issue in the repository.

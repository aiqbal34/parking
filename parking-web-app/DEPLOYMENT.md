# Deployment Guide

This guide will help you deploy the Parking Web App to Vercel.

## Prerequisites

1. **Firebase Project**: Set up a Firebase project with Authentication and Firestore
2. **Backend API**: Deploy your FastAPI backend to Vercel (or another hosting service)
3. **GitHub Repository**: Push your code to a GitHub repository

## Step 1: Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use an existing one
3. Enable Authentication with Email/Password
4. Enable Firestore Database
5. Go to Project Settings > General > Your apps
6. Add a web app and copy the configuration

## Step 2: Backend API Setup

Make sure your FastAPI backend is deployed and accessible. The backend should be running at a URL like:
- `https://your-backend-api.vercel.app/api`

## Step 3: Vercel Deployment

### Option A: Deploy via Vercel Dashboard

1. Go to [Vercel Dashboard](https://vercel.com/dashboard)
2. Click "New Project"
3. Import your GitHub repository
4. Configure the project:
   - **Framework Preset**: Next.js
   - **Root Directory**: `parking-web-app`
   - **Build Command**: `npm run build`
   - **Output Directory**: `.next`

### Option B: Deploy via Vercel CLI

1. Install Vercel CLI:
```bash
npm i -g vercel
```

2. Login to Vercel:
```bash
vercel login
```

3. Deploy:
```bash
cd parking-web-app
vercel
```

## Step 4: Environment Variables

Set the following environment variables in your Vercel project:

### Required Variables

```env
NEXT_PUBLIC_FIREBASE_API_KEY=your_firebase_api_key
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
NEXT_PUBLIC_FIREBASE_PROJECT_ID=your_project_id
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=your_project.appspot.com
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=your_sender_id
NEXT_PUBLIC_FIREBASE_APP_ID=your_app_id
NEXT_PUBLIC_API_BASE_URL=https://your-backend-api.vercel.app/api
```

### How to Set Environment Variables in Vercel

1. Go to your project in Vercel Dashboard
2. Click on "Settings" tab
3. Click on "Environment Variables"
4. Add each variable with its value
5. Make sure to add them for all environments (Production, Preview, Development)

## Step 5: Firebase Security Rules

Update your Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own user document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Parking spots are readable by all authenticated users
    // Only owners can write to their spots
    match /parking_spots/{spotId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        (resource == null || resource.data.owner_id == request.auth.uid);
    }
    
    // Bookings are readable by the finder or spot owner
    // Only finders can create bookings
    match /bookings/{bookingId} {
      allow read: if request.auth != null && 
        (resource.data.finder_id == request.auth.uid || 
         get(/databases/$(database)/documents/parking_spots/$(resource.data.spot_id)).data.owner_id == request.auth.uid);
      allow create: if request.auth != null && request.auth.uid == resource.data.finder_id;
      allow update: if request.auth != null && 
        get(/databases/$(database)/documents/parking_spots/$(resource.data.spot_id)).data.owner_id == request.auth.uid;
    }
  }
}
```

## Step 6: Domain Configuration (Optional)

1. Go to your Vercel project settings
2. Click on "Domains"
3. Add your custom domain
4. Update your DNS settings as instructed

## Step 7: Testing

After deployment:

1. Visit your deployed URL
2. Test user registration and login
3. Test creating parking spots
4. Test booking functionality
5. Test map functionality
6. Test on mobile devices

## Troubleshooting

### Common Issues

1. **Firebase Configuration Error**
   - Check that all environment variables are set correctly
   - Verify Firebase project settings

2. **API Connection Issues**
   - Verify the backend API URL is correct
   - Check CORS settings on your backend
   - Ensure the backend is deployed and accessible

3. **Map Not Loading**
   - Check browser console for errors
   - Verify Leaflet CSS is loaded
   - Check if location services are enabled

4. **Authentication Issues**
   - Verify Firebase Auth is enabled
   - Check Firestore security rules
   - Ensure proper Firebase configuration

### Debug Mode

To enable debug mode, add this to your environment variables:
```env
NEXT_PUBLIC_DEBUG=true
```

## Monitoring

1. **Vercel Analytics**: Enable in your Vercel project settings
2. **Firebase Analytics**: Enable in Firebase Console
3. **Error Tracking**: Consider adding Sentry or similar service

## Updates and Maintenance

1. **Automatic Deployments**: Vercel automatically deploys on git push
2. **Environment Variables**: Update in Vercel dashboard when needed
3. **Dependencies**: Keep dependencies updated for security

## Performance Optimization

1. **Image Optimization**: Use Next.js Image component
2. **Code Splitting**: Implement dynamic imports for large components
3. **Caching**: Configure proper caching headers
4. **CDN**: Vercel provides global CDN automatically

## Security Considerations

1. **Environment Variables**: Never commit sensitive data to git
2. **Firebase Rules**: Regularly review and update security rules
3. **API Security**: Ensure backend API has proper authentication
4. **HTTPS**: Vercel provides HTTPS by default

## Support

If you encounter issues:

1. Check the Vercel deployment logs
2. Check browser console for errors
3. Verify all environment variables are set
4. Test locally with the same environment variables
5. Check Firebase and backend API status

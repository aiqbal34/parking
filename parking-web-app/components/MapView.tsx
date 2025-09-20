'use client'

import { useEffect, useRef } from 'react'
import { MapContainer, TileLayer, Marker, Popup, useMap } from 'react-leaflet'
import L from 'leaflet'
import { ParkingSpot } from '@/types'
import { MapPinIcon, TruckIcon } from '@heroicons/react/24/outline'
import 'leaflet/dist/leaflet.css'

// Fix for default markers in react-leaflet
delete (L.Icon.Default.prototype as any)._getIconUrl
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png',
  iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
})

interface MapViewProps {
  spots: ParkingSpot[]
  userLocation: { lat: number; lng: number } | null
  selectedSpot: ParkingSpot | null
  onSpotSelect: (spot: ParkingSpot) => void
}

// Custom marker icons
const createCustomIcon = (color: string) => {
  return L.divIcon({
    className: 'custom-marker',
    html: `
      <div style="
        background-color: ${color};
        width: 30px;
        height: 30px;
        border-radius: 50% 50% 50% 0;
        border: 2px solid white;
        box-shadow: 0 2px 4px rgba(0,0,0,0.3);
        display: flex;
        align-items: center;
        justify-content: center;
        transform: rotate(-45deg);
      ">
        <div style="
          transform: rotate(45deg);
          color: white;
          font-size: 12px;
          font-weight: bold;
        ">$</div>
      </div>
    `,
    iconSize: [30, 30],
    iconAnchor: [15, 30],
  })
}

const userLocationIcon = L.divIcon({
  className: 'user-location-marker',
  html: `
    <div style="
      background-color: #3B82F6;
      width: 20px;
      height: 20px;
      border-radius: 50%;
      border: 3px solid white;
      box-shadow: 0 2px 4px rgba(0,0,0,0.3);
    "></div>
  `,
  iconSize: [20, 20],
  iconAnchor: [10, 10],
})

function MapController({ 
  userLocation, 
  selectedSpot 
}: { 
  userLocation: { lat: number; lng: number } | null
  selectedSpot: ParkingSpot | null 
}) {
  const map = useMap()

  useEffect(() => {
    if (userLocation) {
      map.setView([userLocation.lat, userLocation.lng], 13)
    }
  }, [map, userLocation])

  useEffect(() => {
    if (selectedSpot) {
      map.setView([selectedSpot.latitude, selectedSpot.longitude], 16)
    }
  }, [map, selectedSpot])

  return null
}

export default function MapView({ 
  spots, 
  userLocation, 
  selectedSpot, 
  onSpotSelect 
}: MapViewProps) {
  const mapRef = useRef<L.Map>(null)

  const formatPrice = (price: number) => {
    return `$${price.toFixed(0)}/hr`
  }

  const formatDistance = (distance?: number) => {
    if (!distance) return ''
    if (distance < 1000) {
      return `${Math.round(distance)}m`
    }
    return `${(distance / 1000).toFixed(1)}km`
  }

  const getMarkerColor = (spot: ParkingSpot) => {
    if (selectedSpot?.id === spot.id) return '#EF4444' // Red for selected
    if (!spot.is_available) return '#6B7280' // Gray for unavailable
    return '#10B981' // Green for available
  }

  // Default center (San Francisco)
  const defaultCenter: [number, number] = [37.7749, -122.4194]
  const center = userLocation ? [userLocation.lat, userLocation.lng] : defaultCenter

  return (
    <div className="w-full h-full rounded-lg overflow-hidden border border-gray-200">
      <MapContainer
        center={center as [number, number]}
        zoom={13}
        style={{ height: '100%', width: '100%' }}
        ref={mapRef}
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />

        <MapController userLocation={userLocation} selectedSpot={selectedSpot} />

        {/* User Location Marker */}
        {userLocation && (
          <Marker
            position={[userLocation.lat, userLocation.lng]}
            icon={userLocationIcon}
          >
            <Popup>
              <div className="text-center">
                <MapPinIcon className="h-5 w-5 text-blue-600 mx-auto mb-1" />
                <p className="font-medium">Your Location</p>
              </div>
            </Popup>
          </Marker>
        )}

        {/* Parking Spot Markers */}
        {spots.map((spot) => (
          <Marker
            key={spot.id}
            position={[spot.latitude, spot.longitude]}
            icon={createCustomIcon(getMarkerColor(spot))}
            eventHandlers={{
              click: () => onSpotSelect(spot),
            }}
          >
            <Popup>
              <div className="p-2 min-w-[200px]">
                <div className="flex items-start justify-between mb-2">
                  <div className="flex-1">
                    <h3 className="font-semibold text-gray-900 text-sm mb-1">
                      {formatPrice(spot.hourly_rate)}
                    </h3>
                    <p className="text-xs text-gray-600 mb-2 line-clamp-2">
                      {spot.address}
                    </p>
                  </div>
                  <div className="ml-2">
                    <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${
                      spot.is_available 
                        ? 'bg-green-100 text-green-800' 
                        : 'bg-gray-100 text-gray-800'
                    }`}>
                      {spot.is_available ? 'Available' : 'Unavailable'}
                    </span>
                  </div>
                </div>

                <div className="space-y-1 text-xs text-gray-600">
                  <div className="flex items-center">
                    <TruckIcon className="h-3 w-3 mr-1" />
                    <span>{spot.max_vehicle_size}</span>
                  </div>
                  
                  {spot.distance && (
                    <div className="flex items-center">
                      <MapPinIcon className="h-3 w-3 mr-1" />
                      <span>{formatDistance(spot.distance)} away</span>
                    </div>
                  )}
                </div>

                <button
                  onClick={() => onSpotSelect(spot)}
                  className="w-full mt-3 bg-primary-600 text-white text-xs py-1 px-2 rounded hover:bg-primary-700 transition-colors"
                >
                  View Details
                </button>
              </div>
            </Popup>
          </Marker>
        ))}
      </MapContainer>
    </div>
  )
}

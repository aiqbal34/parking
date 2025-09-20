'use client'

import { ParkingSpot, VehicleSize } from '@/types'
import { MapPinIcon, TruckIcon, ClockIcon, UserIcon } from '@heroicons/react/24/outline'
import { formatDistanceToNow } from 'date-fns'

interface ParkingSpotCardProps {
  spot: ParkingSpot
  onClick: () => void
}

export default function ParkingSpotCard({ spot, onClick }: ParkingSpotCardProps) {
  const formatPrice = (price: number) => {
    return `$${price.toFixed(0)}/hr`
  }

  const formatDistance = (distance?: number) => {
    if (!distance) return ''
    if (distance < 1000) {
      return `${Math.round(distance)}m away`
    }
    return `${(distance / 1000).toFixed(1)}km away`
  }

  const formatVehicleSize = (size: VehicleSize) => {
    switch (size) {
      case VehicleSize.COMPACT:
        return 'Compact'
      case VehicleSize.MIDSIZE:
        return 'Mid-size'
      case VehicleSize.LARGE:
        return 'Large'
      case VehicleSize.SUV:
        return 'SUV/Truck'
      case VehicleSize.ANY:
        return 'Any Size'
      default:
        return size
    }
  }

  const formatDate = (dateString: string) => {
    try {
      return formatDistanceToNow(new Date(dateString), { addSuffix: true })
    } catch {
      return 'Recently'
    }
  }

  return (
    <div 
      className="card p-6 hover:shadow-lg transition-shadow cursor-pointer"
      onClick={onClick}
    >
      {/* Header */}
      <div className="flex items-start justify-between mb-4">
        <div className="flex-1">
          <div className="flex items-center mb-2">
            <h3 className="text-lg font-semibold text-gray-900">
              {formatPrice(spot.hourly_rate)}
            </h3>
            <span className={`ml-2 inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${
              spot.is_available 
                ? 'bg-green-100 text-green-800' 
                : 'bg-gray-100 text-gray-800'
            }`}>
              {spot.is_available ? 'Available' : 'Unavailable'}
            </span>
          </div>
          
          {spot.distance && (
            <p className="text-sm text-gray-600 flex items-center">
              <MapPinIcon className="h-4 w-4 mr-1" />
              {formatDistance(spot.distance)}
            </p>
          )}
        </div>
      </div>

      {/* Address */}
      <div className="mb-4">
        <p className="text-gray-900 font-medium line-clamp-2">
          {spot.address}
        </p>
      </div>

      {/* Description */}
      {spot.description && (
        <div className="mb-4">
          <p className="text-sm text-gray-600 line-clamp-2">
            {spot.description}
          </p>
        </div>
      )}

      {/* Details */}
      <div className="space-y-2 mb-4">
        <div className="flex items-center text-sm text-gray-600">
          <TruckIcon className="h-4 w-4 mr-2" />
          <span>Max: {formatVehicleSize(spot.max_vehicle_size)}</span>
        </div>
        
        <div className="flex items-center text-sm text-gray-600">
          <UserIcon className="h-4 w-4 mr-2" />
          <span>Owner: {spot.owner_name}</span>
        </div>
        
        <div className="flex items-center text-sm text-gray-600">
          <ClockIcon className="h-4 w-4 mr-2" />
          <span>Available {formatDate(spot.availability_start)}</span>
        </div>
      </div>

      {/* Footer */}
      <div className="flex items-center justify-between pt-4 border-t border-gray-100">
        <div className="text-xs text-gray-500">
          Added {formatDate(spot.created_at)}
        </div>
        
        <button className="text-primary-600 hover:text-primary-700 text-sm font-medium transition-colors">
          View Details →
        </button>
      </div>
    </div>
  )
}

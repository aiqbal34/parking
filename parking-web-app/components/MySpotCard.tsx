'use client'

import { useState } from 'react'
import { ParkingSpot, VehicleSize } from '@/types'
import { apiService } from '@/lib/api'
import { 
  MapPinIcon, 
  TruckIcon, 
  ClockIcon, 
  PencilIcon, 
  TrashIcon,
  EyeIcon,
  PowerIcon
} from '@heroicons/react/24/outline'
import { format } from 'date-fns'
import toast from 'react-hot-toast'

interface MySpotCardProps {
  spot: ParkingSpot
  onUpdated: () => void
  onDeleted: () => void
  onError: (error: string) => void
}

export default function MySpotCard({ spot, onUpdated, onDeleted, onError }: MySpotCardProps) {
  const [loading, setLoading] = useState(false)
  const [showDetails, setShowDetails] = useState(false)

  const formatPrice = (price: number) => {
    return `$${price.toFixed(0)}/hr`
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

  const handleToggleAvailability = async () => {
    try {
      setLoading(true)
      await apiService.updateParkingSpot(spot.id, {
        is_available: !spot.is_available
      })
      onUpdated()
    } catch (error) {
      console.error('Error toggling availability:', error)
      onError('Failed to update availability')
    } finally {
      setLoading(false)
    }
  }

  const handleDelete = async () => {
    if (!confirm('Are you sure you want to delete this parking spot? This action cannot be undone.')) {
      return
    }

    try {
      setLoading(true)
      await apiService.deleteParkingSpot(spot.id)
      onDeleted()
    } catch (error) {
      console.error('Error deleting spot:', error)
      onError('Failed to delete parking spot')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="card p-6">
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
        </div>

        <div className="flex items-center space-x-1">
          <button
            onClick={() => setShowDetails(!showDetails)}
            className="p-2 text-gray-400 hover:text-gray-600 transition-colors"
            title="View details"
          >
            <EyeIcon className="h-4 w-4" />
          </button>
        </div>
      </div>

      {/* Address */}
      <div className="mb-4">
        <p className="text-gray-900 font-medium line-clamp-2 flex items-start">
          <MapPinIcon className="h-4 w-4 mr-1 mt-0.5 flex-shrink-0" />
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
          <ClockIcon className="h-4 w-4 mr-2" />
          <span>Available until {format(new Date(spot.availability_end), 'MMM d')}</span>
        </div>
      </div>

      {/* Expanded Details */}
      {showDetails && (
        <div className="border-t border-gray-100 pt-4 mb-4 space-y-2">
          <div className="text-sm text-gray-600">
            <span className="font-medium">Created:</span> {format(new Date(spot.created_at), 'MMM d, yyyy')}
          </div>
          <div className="text-sm text-gray-600">
            <span className="font-medium">Available from:</span> {format(new Date(spot.availability_start), 'MMM d, yyyy h:mm a')}
          </div>
          <div className="text-sm text-gray-600">
            <span className="font-medium">Available until:</span> {format(new Date(spot.availability_end), 'MMM d, yyyy h:mm a')}
          </div>
        </div>
      )}

      {/* Actions */}
      <div className="flex items-center justify-between pt-4 border-t border-gray-100">
        <button
          onClick={handleToggleAvailability}
          disabled={loading}
          className={`flex items-center text-sm font-medium transition-colors ${
            spot.is_available 
              ? 'text-orange-600 hover:text-orange-700' 
              : 'text-green-600 hover:text-green-700'
          }`}
        >
          {spot.is_available ? (
            <>
              <PowerIcon className="h-4 w-4 mr-1" />
              Mark Unavailable
            </>
          ) : (
            <>
              <PowerIcon className="h-4 w-4 mr-1" />
              Mark Available
            </>
          )}
        </button>

        <div className="flex items-center space-x-2">
          <button
            onClick={handleDelete}
            disabled={loading}
            className="p-2 text-red-400 hover:text-red-600 transition-colors"
            title="Delete spot"
          >
            <TrashIcon className="h-4 w-4" />
          </button>
        </div>
      </div>

      {loading && (
        <div className="absolute inset-0 bg-white bg-opacity-75 flex items-center justify-center rounded-lg">
          <div className="loading-spinner h-6 w-6" />
        </div>
      )}
    </div>
  )
}

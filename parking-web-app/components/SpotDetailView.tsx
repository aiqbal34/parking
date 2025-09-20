'use client'

import { useState } from 'react'
import { ParkingSpot, VehicleSize, BookingStatus } from '@/types'
import { useAuth } from '@/lib/auth-context'
import { apiService } from '@/lib/api'
import { 
  MapPinIcon, 
  TruckIcon, 
  ClockIcon, 
  UserIcon, 
  XMarkIcon,
  CalendarIcon,
  CurrencyDollarIcon
} from '@heroicons/react/24/outline'
import { format } from 'date-fns'
import toast from 'react-hot-toast'

interface SpotDetailViewProps {
  spot: ParkingSpot
  onClose: () => void
}

export default function SpotDetailView({ spot, onClose }: SpotDetailViewProps) {
  const { user } = useAuth()
  const [showBookingForm, setShowBookingForm] = useState(false)
  const [bookingData, setBookingData] = useState({
    startTime: '',
    endTime: '',
    message: ''
  })
  const [loading, setLoading] = useState(false)

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

  const calculateTotalPrice = () => {
    if (!bookingData.startTime || !bookingData.endTime) return 0
    
    const start = new Date(bookingData.startTime)
    const end = new Date(bookingData.endTime)
    const hours = (end.getTime() - start.getTime()) / (1000 * 60 * 60)
    
    return hours * spot.hourly_rate
  }

  const handleBookingSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!user) {
      toast.error('Please sign in to book a spot')
      return
    }

    if (!bookingData.startTime || !bookingData.endTime) {
      toast.error('Please select start and end times')
      return
    }

    const startTime = new Date(bookingData.startTime)
    const endTime = new Date(bookingData.endTime)

    if (endTime <= startTime) {
      toast.error('End time must be after start time')
      return
    }

    setLoading(true)

    try {
      await apiService.createBookingRequest({
        spot_id: spot.id,
        finder_id: user.uid,
        finder_name: user.name,
        finder_email: user.email,
        start_time: startTime.toISOString(),
        end_time: endTime.toISOString(),
        message: bookingData.message || undefined
      })

      toast.success('Booking request sent successfully!')
      setShowBookingForm(false)
      setBookingData({ startTime: '', endTime: '', message: '' })
    } catch (error) {
      console.error('Error creating booking:', error)
      toast.error('Failed to send booking request')
    } finally {
      setLoading(false)
    }
  }

  const isOwner = user?.uid === spot.owner_id

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-[9999]">
      <div className="bg-white rounded-lg max-w-2xl w-full max-h-[90vh] overflow-y-auto relative z-[10000]">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-gray-200">
          <h2 className="text-xl font-semibold text-gray-900">Parking Spot Details</h2>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600 transition-colors"
          >
            <XMarkIcon className="h-6 w-6" />
          </button>
        </div>

        {/* Content */}
        <div className="p-6 space-y-6">
          {/* Price and Status */}
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-2xl font-bold text-primary-600">
                {formatPrice(spot.hourly_rate)}
              </h3>
              <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${
                spot.is_available 
                  ? 'bg-green-100 text-green-800' 
                  : 'bg-gray-100 text-gray-800'
              }`}>
                {spot.is_available ? 'Available' : 'Unavailable'}
              </span>
            </div>
          </div>

          {/* Address */}
          <div>
            <h4 className="font-medium text-gray-900 mb-2 flex items-center">
              <MapPinIcon className="h-5 w-5 mr-2" />
              Location
            </h4>
            <p className="text-gray-700">{spot.address}</p>
          </div>

          {/* Description */}
          {spot.description && (
            <div>
              <h4 className="font-medium text-gray-900 mb-2">Description</h4>
              <p className="text-gray-700">{spot.description}</p>
            </div>
          )}

          {/* Details */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <h4 className="font-medium text-gray-900 mb-2 flex items-center">
                <TruckIcon className="h-5 w-5 mr-2" />
                Vehicle Size
              </h4>
              <p className="text-gray-700">{formatVehicleSize(spot.max_vehicle_size)}</p>
            </div>

            <div>
              <h4 className="font-medium text-gray-900 mb-2 flex items-center">
                <UserIcon className="h-5 w-5 mr-2" />
                Owner
              </h4>
              <p className="text-gray-700">{spot.owner_name}</p>
            </div>

            <div>
              <h4 className="font-medium text-gray-900 mb-2 flex items-center">
                <ClockIcon className="h-5 w-5 mr-2" />
                Available From
              </h4>
              <p className="text-gray-700">
                {format(new Date(spot.availability_start), 'MMM d, yyyy h:mm a')}
              </p>
            </div>

            <div>
              <h4 className="font-medium text-gray-900 mb-2 flex items-center">
                <ClockIcon className="h-5 w-5 mr-2" />
                Available Until
              </h4>
              <p className="text-gray-700">
                {format(new Date(spot.availability_end), 'MMM d, yyyy h:mm a')}
              </p>
            </div>
          </div>

          {/* Booking Section */}
          {!isOwner && spot.is_available && (
            <div className="border-t border-gray-200 pt-6">
              {!showBookingForm ? (
                <button
                  onClick={() => setShowBookingForm(true)}
                  className="w-full btn-primary flex items-center justify-center"
                >
                  <CalendarIcon className="h-5 w-5 mr-2" />
                  Request to Book This Spot
                </button>
              ) : (
                <form onSubmit={handleBookingSubmit} className="space-y-4">
                  <h4 className="font-medium text-gray-900">Booking Request</h4>
                  
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <label className="label">Start Time</label>
                      <input
                        type="datetime-local"
                        value={bookingData.startTime}
                        onChange={(e) => setBookingData(prev => ({ ...prev, startTime: e.target.value }))}
                        className="input-field"
                        min={new Date().toISOString().slice(0, 16)}
                        required
                      />
                    </div>

                    <div>
                      <label className="label">End Time</label>
                      <input
                        type="datetime-local"
                        value={bookingData.endTime}
                        onChange={(e) => setBookingData(prev => ({ ...prev, endTime: e.target.value }))}
                        className="input-field"
                        min={bookingData.startTime || new Date().toISOString().slice(0, 16)}
                        required
                      />
                    </div>
                  </div>

                  {bookingData.startTime && bookingData.endTime && (
                    <div className="bg-primary-50 p-4 rounded-lg">
                      <div className="flex items-center justify-between">
                        <span className="font-medium text-gray-900">Total Price:</span>
                        <span className="text-xl font-bold text-primary-600 flex items-center">
                          <CurrencyDollarIcon className="h-5 w-5 mr-1" />
                          {calculateTotalPrice().toFixed(2)}
                        </span>
                      </div>
                    </div>
                  )}

                  <div>
                    <label className="label">Message to Owner (Optional)</label>
                    <textarea
                      value={bookingData.message}
                      onChange={(e) => setBookingData(prev => ({ ...prev, message: e.target.value }))}
                      className="input-field"
                      rows={3}
                      placeholder="Add a personal message to increase your chances of approval..."
                    />
                  </div>

                  <div className="flex space-x-3">
                    <button
                      type="button"
                      onClick={() => setShowBookingForm(false)}
                      className="flex-1 btn-secondary"
                    >
                      Cancel
                    </button>
                    <button
                      type="submit"
                      disabled={loading}
                      className="flex-1 btn-primary"
                    >
                      {loading ? 'Sending...' : 'Send Request'}
                    </button>
                  </div>
                </form>
              )}
            </div>
          )}

          {isOwner && (
            <div className="border-t border-gray-200 pt-6">
              <div className="bg-blue-50 p-4 rounded-lg">
                <p className="text-blue-800 text-sm">
                  This is your parking spot. You can manage it from the &quot;Rent Out Spot&quot; tab.
                </p>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

'use client'

import { useState } from 'react'
import { Booking, BookingStatus } from '@/types'
import { apiService } from '@/lib/api'
import { 
  CalendarIcon, 
  CurrencyDollarIcon,
  XMarkIcon,
  MapPinIcon
} from '@heroicons/react/24/outline'
import { format } from 'date-fns'
import toast from 'react-hot-toast'

interface BookingCardProps {
  booking: Booking
  onUpdated: () => void
  onError: (error: string) => void
}

export default function BookingCard({ booking, onUpdated, onError }: BookingCardProps) {
  const [loading, setLoading] = useState(false)

  const formatPrice = (price: number) => {
    return `$${price.toFixed(2)}`
  }

  const getStatusColor = (status: BookingStatus) => {
    switch (status) {
      case BookingStatus.PENDING:
        return 'bg-yellow-100 text-yellow-800'
      case BookingStatus.APPROVED:
        return 'bg-blue-100 text-blue-800'
      case BookingStatus.REJECTED:
        return 'bg-red-100 text-red-800'
      case BookingStatus.CONFIRMED:
        return 'bg-green-100 text-green-800'
      case BookingStatus.COMPLETED:
        return 'bg-gray-100 text-gray-800'
      case BookingStatus.CANCELLED:
        return 'bg-red-100 text-red-800'
      default:
        return 'bg-gray-100 text-gray-800'
    }
  }

  const getStatusText = (status: BookingStatus) => {
    switch (status) {
      case BookingStatus.PENDING:
        return 'Pending'
      case BookingStatus.APPROVED:
        return 'Approved'
      case BookingStatus.REJECTED:
        return 'Rejected'
      case BookingStatus.CONFIRMED:
        return 'Confirmed'
      case BookingStatus.COMPLETED:
        return 'Completed'
      case BookingStatus.CANCELLED:
        return 'Cancelled'
      default:
        return status
    }
  }

  const handleCancel = async () => {
    if (!confirm('Are you sure you want to cancel this booking?')) {
      return
    }

    setLoading(true)

    try {
      await apiService.cancelBookingRequest(booking.id)
      toast.success('Booking cancelled successfully!')
      onUpdated()
    } catch (error) {
      console.error('Error cancelling booking:', error)
      onError('Failed to cancel booking')
    } finally {
      setLoading(false)
    }
  }

  const canCancel = booking.status === BookingStatus.PENDING || booking.status === BookingStatus.APPROVED

  return (
    <div className="card p-6">
      {/* Header */}
      <div className="flex items-start justify-between mb-4">
        <div className="flex-1">
          <div className="flex items-center mb-2">
            <h3 className="text-lg font-semibold text-gray-900">
              Booking #{booking.id.slice(-8)}
            </h3>
            <span className={`ml-2 inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(booking.status)}`}>
              {getStatusText(booking.status)}
            </span>
          </div>
          <p className="text-sm text-gray-600">
            Created {format(new Date(booking.created_at), 'MMM d, yyyy h:mm a')}
          </p>
        </div>
        
        <div className="text-right">
          <p className="text-lg font-bold text-green-600">
            {formatPrice(booking.total_amount)}
          </p>
        </div>
      </div>

      {/* Booking Details */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
        <div className="flex items-center text-sm text-gray-600">
          <CalendarIcon className="h-4 w-4 mr-2" />
          <div>
            <p className="font-medium">Start Time</p>
            <p>{format(new Date(booking.start_time), 'MMM d, yyyy h:mm a')}</p>
          </div>
        </div>
        
        <div className="flex items-center text-sm text-gray-600">
          <CalendarIcon className="h-4 w-4 mr-2" />
          <div>
            <p className="font-medium">End Time</p>
            <p>{format(new Date(booking.end_time), 'MMM d, yyyy h:mm a')}</p>
          </div>
        </div>
      </div>

      {/* Owner Response */}
      {booking.owner_response && (
        <div className="mb-4 p-3 bg-gray-50 rounded-lg">
          <p className="text-sm font-medium text-gray-900 mb-1">Owner Response:</p>
          <p className="text-sm text-gray-700">{booking.owner_response}</p>
          {booking.responded_at && (
            <p className="text-xs text-gray-500 mt-1">
              {format(new Date(booking.responded_at), 'MMM d, yyyy h:mm a')}
            </p>
          )}
        </div>
      )}

      {/* Message to Owner */}
      {booking.message && (
        <div className="mb-4 p-3 bg-blue-50 rounded-lg">
          <p className="text-sm font-medium text-blue-900 mb-1">Your Message:</p>
          <p className="text-sm text-blue-800">{booking.message}</p>
        </div>
      )}

      {/* Actions */}
      {canCancel && (
        <div className="flex justify-end pt-4 border-t border-gray-100">
          <button
            onClick={handleCancel}
            disabled={loading}
            className="btn-danger flex items-center"
          >
            <XMarkIcon className="h-4 w-4 mr-2" />
            Cancel Booking
          </button>
        </div>
      )}

      {loading && (
        <div className="absolute inset-0 bg-white bg-opacity-75 flex items-center justify-center rounded-lg">
          <div className="loading-spinner h-6 w-6" />
        </div>
      )}
    </div>
  )
}

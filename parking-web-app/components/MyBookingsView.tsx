'use client'

import { useState, useEffect } from 'react'
import { useAuth } from '@/lib/auth-context'
import { apiService } from '@/lib/api'
import { Booking, BookingStatus } from '@/types'
import BookingCard from '@/components/BookingCard'
import LoadingSpinner from '@/components/LoadingSpinner'
import { CalendarIcon } from '@heroicons/react/24/outline'
import toast from 'react-hot-toast'

export default function MyBookingsView() {
  const { user } = useAuth()
  const [bookings, setBookings] = useState<Booking[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (user) {
      loadMyBookings()
    }
  }, [user])

  const loadMyBookings = async () => {
    try {
      setLoading(true)
      const response = await apiService.getMyBookings()
      setBookings(response.data?.bookings || [])
    } catch (error) {
      console.error('Error loading my bookings:', error)
      toast.error('Failed to load your bookings')
    } finally {
      setLoading(false)
    }
  }

  const handleBookingUpdated = () => {
    loadMyBookings()
  }

  const handleBookingUpdatedError = (error: string) => {
    toast.error(error)
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <LoadingSpinner size="lg" />
      </div>
    )
  }

  if (bookings.length === 0) {
    return (
      <div className="text-center py-12">
        <div className="mx-auto h-24 w-24 bg-gray-100 rounded-full flex items-center justify-center mb-4">
          <CalendarIcon className="h-12 w-12 text-gray-400" />
        </div>
        <h3 className="text-lg font-medium text-gray-900 mb-2">No bookings yet</h3>
        <p className="text-gray-600 max-w-md mx-auto">
          When you book parking spots, you&apos;ll see your reservations here.
        </p>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="card p-4">
          <div className="flex items-center">
            <div className="p-2 bg-yellow-100 rounded-lg">
              <CalendarIcon className="h-6 w-6 text-yellow-600" />
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600">Pending</p>
              <p className="text-2xl font-bold text-gray-900">
                {bookings.filter(b => b.status === BookingStatus.PENDING).length}
              </p>
            </div>
          </div>
        </div>

        <div className="card p-4">
          <div className="flex items-center">
            <div className="p-2 bg-blue-100 rounded-lg">
              <CalendarIcon className="h-6 w-6 text-blue-600" />
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600">Approved</p>
              <p className="text-2xl font-bold text-gray-900">
                {bookings.filter(b => b.status === BookingStatus.APPROVED).length}
              </p>
            </div>
          </div>
        </div>

        <div className="card p-4">
          <div className="flex items-center">
            <div className="p-2 bg-green-100 rounded-lg">
              <CalendarIcon className="h-6 w-6 text-green-600" />
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600">Confirmed</p>
              <p className="text-2xl font-bold text-gray-900">
                {bookings.filter(b => b.status === BookingStatus.CONFIRMED).length}
              </p>
            </div>
          </div>
        </div>

        <div className="card p-4">
          <div className="flex items-center">
            <div className="p-2 bg-gray-100 rounded-lg">
              <CalendarIcon className="h-6 w-6 text-gray-600" />
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600">Completed</p>
              <p className="text-2xl font-bold text-gray-900">
                {bookings.filter(b => b.status === BookingStatus.COMPLETED).length}
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Bookings */}
      <div className="space-y-4">
        {bookings.map((booking) => (
          <BookingCard
            key={booking.id}
            booking={booking}
            onUpdated={handleBookingUpdated}
            onError={handleBookingUpdatedError}
          />
        ))}
      </div>
    </div>
  )
}

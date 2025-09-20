'use client'

import { useState, useEffect } from 'react'
import { useAuth } from '@/lib/auth-context'
import { apiService } from '@/lib/api'
import { Booking } from '@/types'
import BookingRequestCard from '@/components/BookingRequestCard'
import LoadingSpinner from '@/components/LoadingSpinner'
import { ClockIcon } from '@heroicons/react/24/outline'
import toast from 'react-hot-toast'

export default function BookingRequestsView() {
  const { user } = useAuth()
  const [requests, setRequests] = useState<Booking[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (user) {
      loadPendingRequests()
    }
  }, [user])

  const loadPendingRequests = async () => {
    try {
      setLoading(true)
      const response = await apiService.getPendingRequests()
      setRequests(response.data?.requests || [])
    } catch (error) {
      console.error('Error loading pending requests:', error)
      toast.error('Failed to load booking requests')
    } finally {
      setLoading(false)
    }
  }

  const handleRequestUpdated = () => {
    loadPendingRequests()
  }

  const handleRequestUpdatedError = (error: string) => {
    toast.error(error)
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <LoadingSpinner size="lg" />
      </div>
    )
  }

  if (requests.length === 0) {
    return (
      <div className="text-center py-12">
        <div className="mx-auto h-24 w-24 bg-gray-100 rounded-full flex items-center justify-center mb-4">
          <ClockIcon className="h-12 w-12 text-gray-400" />
        </div>
        <h3 className="text-lg font-medium text-gray-900 mb-2">No pending requests</h3>
        <p className="text-gray-600 max-w-md mx-auto">
          When people request to book your parking spots, you&apos;ll see their requests here for approval.
        </p>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Stats */}
      <div className="card p-4">
        <div className="flex items-center">
          <div className="p-2 bg-yellow-100 rounded-lg">
            <ClockIcon className="h-6 w-6 text-yellow-600" />
          </div>
          <div className="ml-4">
            <p className="text-sm font-medium text-gray-600">Pending Requests</p>
            <p className="text-2xl font-bold text-gray-900">{requests.length}</p>
          </div>
        </div>
      </div>

      {/* Requests */}
      <div className="space-y-4">
        {requests.map((request) => (
          <BookingRequestCard
            key={request.id}
            request={request}
            onUpdated={handleRequestUpdated}
            onError={handleRequestUpdatedError}
          />
        ))}
      </div>
    </div>
  )
}

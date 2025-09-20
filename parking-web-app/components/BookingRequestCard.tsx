'use client'

import { useState } from 'react'
import { Booking, BookingStatus } from '@/types'
import { apiService } from '@/lib/api'
import { 
  UserIcon, 
  EnvelopeIcon, 
  CalendarIcon, 
  CurrencyDollarIcon,
  CheckIcon,
  XMarkIcon,
  ChatBubbleLeftIcon
} from '@heroicons/react/24/outline'
import { format } from 'date-fns'
import toast from 'react-hot-toast'

interface BookingRequestCardProps {
  request: Booking
  onUpdated: () => void
  onError: (error: string) => void
}

export default function BookingRequestCard({ request, onUpdated, onError }: BookingRequestCardProps) {
  const [loading, setLoading] = useState(false)
  const [showResponseForm, setShowResponseForm] = useState(false)
  const [responseMessage, setResponseMessage] = useState('')
  const [actionType, setActionType] = useState<'approve' | 'reject' | null>(null)

  const formatPrice = (price: number) => {
    return `$${price.toFixed(2)}`
  }

  const handleApprove = async () => {
    setActionType('approve')
    setShowResponseForm(true)
  }

  const handleReject = async () => {
    setActionType('reject')
    setShowResponseForm(true)
  }

  const handleSubmitResponse = async () => {
    if (!actionType) return

    setLoading(true)

    try {
      if (actionType === 'approve') {
        await apiService.approveBookingRequest(request.id, responseMessage || undefined)
        toast.success('Booking request approved!')
      } else {
        await apiService.rejectBookingRequest(request.id, responseMessage || undefined)
        toast.success('Booking request rejected!')
      }
      
      onUpdated()
      setShowResponseForm(false)
      setResponseMessage('')
      setActionType(null)
    } catch (error) {
      console.error(`Error ${actionType}ing request:`, error)
      onError(`Failed to ${actionType} booking request`)
    } finally {
      setLoading(false)
    }
  }

  const handleCancelResponse = () => {
    setShowResponseForm(false)
    setResponseMessage('')
    setActionType(null)
  }

  return (
    <div className="card p-6">
      {/* Header */}
      <div className="flex items-start justify-between mb-4">
        <div className="flex-1">
          <div className="flex items-center mb-2">
            <h3 className="text-lg font-semibold text-gray-900">
              {request.finder_name}
            </h3>
            <span className="ml-2 inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
              Pending
            </span>
          </div>
          <p className="text-sm text-gray-600 flex items-center">
            <EnvelopeIcon className="h-4 w-4 mr-1" />
            {request.finder_email}
          </p>
        </div>
        
        <div className="text-right">
          <p className="text-lg font-bold text-green-600">
            {formatPrice(request.total_amount)}
          </p>
        </div>
      </div>

      {/* Booking Details */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
        <div className="flex items-center text-sm text-gray-600">
          <CalendarIcon className="h-4 w-4 mr-2" />
          <div>
            <p className="font-medium">Start Time</p>
            <p>{format(new Date(request.start_time), 'MMM d, yyyy h:mm a')}</p>
          </div>
        </div>
        
        <div className="flex items-center text-sm text-gray-600">
          <CalendarIcon className="h-4 w-4 mr-2" />
          <div>
            <p className="font-medium">End Time</p>
            <p>{format(new Date(request.end_time), 'MMM d, yyyy h:mm a')}</p>
          </div>
        </div>
      </div>

      {/* Message from requester */}
      {request.message && (
        <div className="mb-4 p-3 bg-blue-50 rounded-lg">
          <div className="flex items-start">
            <ChatBubbleLeftIcon className="h-4 w-4 mr-2 mt-0.5 text-blue-600" />
            <div>
              <p className="text-sm font-medium text-blue-900 mb-1">Message from requester:</p>
              <p className="text-sm text-blue-800">{request.message}</p>
            </div>
          </div>
        </div>
      )}

      {/* Response Form */}
      {showResponseForm && (
        <div className="mb-4 p-4 bg-gray-50 rounded-lg">
          <h4 className="font-medium text-gray-900 mb-2">
            {actionType === 'approve' ? 'Approve Request' : 'Reject Request'}
          </h4>
          <p className="text-sm text-gray-600 mb-3">
            {actionType === 'approve' 
              ? 'Add an optional message to the requester:' 
              : 'Add an optional reason for rejection:'
            }
          </p>
          <textarea
            value={responseMessage}
            onChange={(e) => setResponseMessage(e.target.value)}
            className="input-field mb-3"
            rows={3}
            placeholder={`Optional ${actionType === 'approve' ? 'message' : 'reason'}...`}
          />
          <div className="flex space-x-2">
            <button
              onClick={handleCancelResponse}
              className="btn-secondary"
            >
              Cancel
            </button>
            <button
              onClick={handleSubmitResponse}
              disabled={loading}
              className={`btn-primary ${
                actionType === 'approve' 
                  ? 'bg-green-600 hover:bg-green-700' 
                  : 'bg-red-600 hover:bg-red-700'
              }`}
            >
              {loading ? 'Processing...' : actionType === 'approve' ? 'Approve' : 'Reject'}
            </button>
          </div>
        </div>
      )}

      {/* Actions */}
      {!showResponseForm && (
        <div className="flex space-x-3 pt-4 border-t border-gray-100">
          <button
            onClick={handleReject}
            disabled={loading}
            className="flex-1 btn-danger flex items-center justify-center"
          >
            <XMarkIcon className="h-4 w-4 mr-2" />
            Reject
          </button>
          <button
            onClick={handleApprove}
            disabled={loading}
            className="flex-1 bg-green-600 hover:bg-green-700 text-white font-medium py-2 px-4 rounded-lg transition-colors flex items-center justify-center"
          >
            <CheckIcon className="h-4 w-4 mr-2" />
            Approve
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

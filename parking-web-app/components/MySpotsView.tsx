'use client'

import { useState, useEffect } from 'react'
import { useAuth } from '@/lib/auth-context'
import { apiService } from '@/lib/api'
import { ParkingSpot } from '@/types'
import MySpotCard from '@/components/MySpotCard'
import LoadingSpinner from '@/components/LoadingSpinner'
import { HomeIcon, PlusIcon } from '@heroicons/react/24/outline'
import toast from 'react-hot-toast'

export default function MySpotsView() {
  const { user } = useAuth()
  const [spots, setSpots] = useState<ParkingSpot[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (user) {
      loadMySpots()
    }
  }, [user])

  const loadMySpots = async () => {
    try {
      setLoading(true)
      const response = await apiService.getMyParkingSpots()
      setSpots(response.data?.spots || [])
    } catch (error) {
      console.error('Error loading my spots:', error)
      toast.error('Failed to load your parking spots')
    } finally {
      setLoading(false)
    }
  }

  const handleSpotUpdated = () => {
    loadMySpots()
    toast.success('Parking spot updated successfully!')
  }

  const handleSpotDeleted = () => {
    loadMySpots()
    toast.success('Parking spot deleted successfully!')
  }

  const handleSpotUpdatedError = (error: string) => {
    toast.error(error)
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <LoadingSpinner size="lg" />
      </div>
    )
  }

  if (spots.length === 0) {
    return (
      <div className="text-center py-12">
        <div className="mx-auto h-24 w-24 bg-gray-100 rounded-full flex items-center justify-center mb-4">
          <HomeIcon className="h-12 w-12 text-gray-400" />
        </div>
        <h3 className="text-lg font-medium text-gray-900 mb-2">No parking spots yet</h3>
        <p className="text-gray-600 mb-6 max-w-md mx-auto">
          Add your first parking spot to start earning money from your driveway or unused space.
        </p>
        <button className="btn-primary flex items-center mx-auto">
          <PlusIcon className="h-5 w-5 mr-2" />
          Add Your First Spot
        </button>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="card p-4">
          <div className="flex items-center">
            <div className="p-2 bg-primary-100 rounded-lg">
              <HomeIcon className="h-6 w-6 text-primary-600" />
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600">Total Spots</p>
              <p className="text-2xl font-bold text-gray-900">{spots.length}</p>
            </div>
          </div>
        </div>

        <div className="card p-4">
          <div className="flex items-center">
            <div className="p-2 bg-green-100 rounded-lg">
              <HomeIcon className="h-6 w-6 text-green-600" />
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600">Available</p>
              <p className="text-2xl font-bold text-gray-900">
                {spots.filter(spot => spot.is_available).length}
              </p>
            </div>
          </div>
        </div>

        <div className="card p-4">
          <div className="flex items-center">
            <div className="p-2 bg-gray-100 rounded-lg">
              <HomeIcon className="h-6 w-6 text-gray-600" />
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600">Unavailable</p>
              <p className="text-2xl font-bold text-gray-900">
                {spots.filter(spot => !spot.is_available).length}
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Spots Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {spots.map((spot) => (
          <MySpotCard
            key={spot.id}
            spot={spot}
            onUpdated={handleSpotUpdated}
            onDeleted={handleSpotDeleted}
            onError={handleSpotUpdatedError}
          />
        ))}
      </div>
    </div>
  )
}

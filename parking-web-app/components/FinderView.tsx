'use client'

import { useState, useEffect } from 'react'
import { useAuth } from '@/lib/auth-context'
import { apiService } from '@/lib/api'
import { ParkingSpot, VehicleSize } from '@/types'
import MapView from '@/components/MapView'
import ParkingSpotCard from '@/components/ParkingSpotCard'
import SpotDetailView from '@/components/SpotDetailView'
import LoadingSpinner from '@/components/LoadingSpinner'
import { 
  MapIcon, 
  ListBulletIcon, 
  ArrowPathIcon,
  MapPinIcon,
  FunnelIcon
} from '@heroicons/react/24/outline'
import toast from 'react-hot-toast'

export default function FinderView() {
  const { user } = useAuth()
  const [parkingSpots, setParkingSpots] = useState<ParkingSpot[]>([])
  const [loading, setLoading] = useState(true)
  const [viewMode, setViewMode] = useState<'map' | 'list'>('map')
  const [userLocation, setUserLocation] = useState<{ lat: number; lng: number } | null>(null)
  const [selectedSpot, setSelectedSpot] = useState<ParkingSpot | null>(null)
  const [showFilters, setShowFilters] = useState(false)
  const [filters, setFilters] = useState({
    maxPrice: '',
    vehicleSize: '' as VehicleSize | '',
    radius: '5000'
  })

  useEffect(() => {
    if (user) {
      loadParkingSpots()
      getUserLocation()
    }
  }, [user])

  const getUserLocation = () => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          setUserLocation({
            lat: position.coords.latitude,
            lng: position.coords.longitude
          })
        },
        (error) => {
          console.error('Error getting location:', error)
          toast.error('Unable to get your location')
        }
      )
    }
  }

  const loadParkingSpots = async () => {
    try {
      setLoading(true)
      let spots: ParkingSpot[] = []

      if (userLocation) {
        // Get nearby spots
        const response = await apiService.getNearbyParkingSpots(
          userLocation.lat,
          userLocation.lng,
          parseInt(filters.radius)
        )
        spots = response.data?.spots || []
      } else {
        // Get all spots
        const response = await apiService.getParkingSpots()
        spots = response.data?.spots || []
      }

      // Apply filters
      let filteredSpots = spots

      if (filters.maxPrice) {
        const maxPrice = parseFloat(filters.maxPrice)
        filteredSpots = filteredSpots.filter(spot => spot.hourly_rate <= maxPrice)
      }

      if (filters.vehicleSize) {
        filteredSpots = filteredSpots.filter(spot => 
          spot.max_vehicle_size === filters.vehicleSize || spot.max_vehicle_size === VehicleSize.ANY
        )
      }

      setParkingSpots(filteredSpots)
    } catch (error) {
      console.error('Error loading parking spots:', error)
      toast.error('Failed to load parking spots')
    } finally {
      setLoading(false)
    }
  }

  const handleRefresh = () => {
    loadParkingSpots()
  }

  const handleFilterChange = (key: string, value: string) => {
    setFilters(prev => ({
      ...prev,
      [key]: value
    }))
  }

  const applyFilters = () => {
    loadParkingSpots()
    setShowFilters(false)
  }

  const clearFilters = () => {
    setFilters({
      maxPrice: '',
      vehicleSize: '',
      radius: '5000'
    })
    loadParkingSpots()
    setShowFilters(false)
  }

  if (loading && parkingSpots.length === 0) {
    return (
      <div className="flex items-center justify-center h-96">
        <LoadingSpinner size="lg" />
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Header Controls */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div className="flex items-center space-x-4">
          <h1 className="text-2xl font-bold text-gray-900">Find Parking</h1>
          {userLocation && (
            <div className="flex items-center text-sm text-gray-600">
              <MapPinIcon className="h-4 w-4 mr-1" />
              <span>Location enabled</span>
            </div>
          )}
        </div>

        <div className="flex items-center space-x-2">
          <button
            onClick={() => setShowFilters(!showFilters)}
            className={`btn-secondary ${showFilters ? 'bg-primary-100 text-primary-700' : ''}`}
          >
            <FunnelIcon className="h-4 w-4 mr-1" />
            Filters
          </button>
          
          <button
            onClick={handleRefresh}
            className="btn-secondary"
            disabled={loading}
          >
            <ArrowPathIcon className={`h-4 w-4 mr-1 ${loading ? 'animate-spin' : ''}`} />
            Refresh
          </button>

          <div className="flex rounded-lg border border-gray-300">
            <button
              onClick={() => setViewMode('map')}
              className={`px-3 py-2 text-sm font-medium rounded-l-lg transition-colors ${
                viewMode === 'map'
                  ? 'bg-primary-600 text-white'
                  : 'bg-white text-gray-700 hover:bg-gray-50'
              }`}
            >
              <MapIcon className="h-4 w-4" />
            </button>
            <button
              onClick={() => setViewMode('list')}
              className={`px-3 py-2 text-sm font-medium rounded-r-lg transition-colors ${
                viewMode === 'list'
                  ? 'bg-primary-600 text-white'
                  : 'bg-white text-gray-700 hover:bg-gray-50'
              }`}
            >
              <ListBulletIcon className="h-4 w-4" />
            </button>
          </div>
        </div>
      </div>

      {/* Filters */}
      {showFilters && (
        <div className="card p-6">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <label className="label">Max Price per Hour</label>
              <input
                type="number"
                value={filters.maxPrice}
                onChange={(e) => handleFilterChange('maxPrice', e.target.value)}
                className="input-field"
                placeholder="e.g., 20"
                min="0"
                step="0.01"
              />
            </div>
            
            <div>
              <label className="label">Vehicle Size</label>
              <select
                value={filters.vehicleSize}
                onChange={(e) => handleFilterChange('vehicleSize', e.target.value)}
                className="input-field"
              >
                <option value="">Any Size</option>
                <option value={VehicleSize.COMPACT}>Compact</option>
                <option value={VehicleSize.MIDSIZE}>Mid-size</option>
                <option value={VehicleSize.LARGE}>Large</option>
                <option value={VehicleSize.SUV}>SUV/Truck</option>
              </select>
            </div>

            <div>
              <label className="label">Search Radius (meters)</label>
              <select
                value={filters.radius}
                onChange={(e) => handleFilterChange('radius', e.target.value)}
                className="input-field"
              >
                <option value="1000">1 km</option>
                <option value="2000">2 km</option>
                <option value="5000">5 km</option>
                <option value="10000">10 km</option>
                <option value="20000">20 km</option>
              </select>
            </div>
          </div>

          <div className="flex justify-end space-x-2 mt-4">
            <button onClick={clearFilters} className="btn-secondary">
              Clear
            </button>
            <button onClick={applyFilters} className="btn-primary">
              Apply Filters
            </button>
          </div>
        </div>
      )}

      {/* Results Summary */}
      <div className="flex items-center justify-between">
        <p className="text-sm text-gray-600">
          {loading ? 'Loading...' : `Found ${parkingSpots.length} parking spots`}
        </p>
      </div>

      {/* Content */}
      {viewMode === 'map' ? (
        <div className="h-96 lg:h-[600px]">
          <MapView
            spots={parkingSpots}
            userLocation={userLocation}
            selectedSpot={selectedSpot}
            onSpotSelect={setSelectedSpot}
          />
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {parkingSpots.map((spot) => (
            <ParkingSpotCard
              key={spot.id}
              spot={spot}
              onClick={() => setSelectedSpot(spot)}
            />
          ))}
        </div>
      )}

      {/* Empty State */}
      {!loading && parkingSpots.length === 0 && (
        <div className="text-center py-12">
          <div className="mx-auto h-24 w-24 bg-gray-100 rounded-full flex items-center justify-center mb-4">
            <MapIcon className="h-12 w-12 text-gray-400" />
          </div>
          <h3 className="text-lg font-medium text-gray-900 mb-2">No parking spots found</h3>
          <p className="text-gray-600 mb-4">
            Try adjusting your filters or search radius to find more spots.
          </p>
          <button onClick={handleRefresh} className="btn-primary">
            Refresh
          </button>
        </div>
      )}

      {/* Spot Detail Modal */}
      {selectedSpot && (
        <SpotDetailView
          spot={selectedSpot}
          onClose={() => setSelectedSpot(null)}
        />
      )}
    </div>
  )
}

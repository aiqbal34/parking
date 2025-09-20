'use client'

import { useState } from 'react'
import { useAuth } from '@/lib/auth-context'
import { apiService } from '@/lib/api'
import { VehicleSize, CreateParkingSpotData } from '@/types'
import { 
  XMarkIcon, 
  MapPinIcon, 
  CurrencyDollarIcon,
  CalendarIcon,
  TruckIcon,
  DocumentTextIcon
} from '@heroicons/react/24/outline'
import { format } from 'date-fns'

interface AddSpotViewProps {
  onClose: () => void
  onSuccess: () => void
  onError: (error: string) => void
}

export default function AddSpotView({ onClose, onSuccess, onError }: AddSpotViewProps) {
  const { user } = useAuth()
  const [loading, setLoading] = useState(false)
  const [formData, setFormData] = useState({
    address: '',
    latitude: '',
    longitude: '',
    hourlyRate: '',
    availabilityStart: '',
    availabilityEnd: '',
    maxVehicleSize: VehicleSize.ANY,
    description: ''
  })

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    const { name, value } = e.target
    setFormData(prev => ({
      ...prev,
      [name]: value
    }))
  }

  const getCurrentLocation = () => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          setFormData(prev => ({
            ...prev,
            latitude: position.coords.latitude.toString(),
            longitude: position.coords.longitude.toString()
          }))
        },
        (error) => {
          console.error('Error getting location:', error)
          onError('Unable to get your location')
        }
      )
    }
  }

  const geocodeAddress = async (address: string) => {
    try {
      // Using a simple geocoding service (you might want to use Google Maps API or similar)
      const response = await fetch(`https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(address)}&limit=1`)
      const data = await response.json()
      
      if (data && data.length > 0) {
        setFormData(prev => ({
          ...prev,
          latitude: data[0].lat,
          longitude: data[0].lon
        }))
      }
    } catch (error) {
      console.error('Error geocoding address:', error)
      // Don't show error for geocoding failure, user can still proceed
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!user) {
      onError('Please sign in to add a parking spot')
      return
    }

    // Validation
    if (!formData.address || !formData.hourlyRate || !formData.availabilityStart || !formData.availabilityEnd) {
      onError('Please fill in all required fields')
      return
    }

    const hourlyRate = parseFloat(formData.hourlyRate)
    if (isNaN(hourlyRate) || hourlyRate <= 0) {
      onError('Please enter a valid hourly rate')
      return
    }

    const startTime = new Date(formData.availabilityStart)
    const endTime = new Date(formData.availabilityEnd)
    
    if (endTime <= startTime) {
      onError('End time must be after start time')
      return
    }

    if (!formData.latitude || !formData.longitude) {
      onError('Please provide location coordinates')
      return
    }

    setLoading(true)

    try {
      const spotData: CreateParkingSpotData = {
        address: formData.address,
        latitude: parseFloat(formData.latitude),
        longitude: parseFloat(formData.longitude),
        hourly_rate: hourlyRate,
        is_available: true,
        availability_start: startTime.toISOString(),
        availability_end: endTime.toISOString(),
        max_vehicle_size: formData.maxVehicleSize,
        description: formData.description,
        owner_id: user.uid,
        owner_name: user.name
      }

      await apiService.createParkingSpot(spotData)
      onSuccess()
    } catch (error) {
      console.error('Error creating parking spot:', error)
      onError('Failed to create parking spot')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-lg max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-gray-200">
          <h2 className="text-xl font-semibold text-gray-900">Add New Parking Spot</h2>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600 transition-colors"
          >
            <XMarkIcon className="h-6 w-6" />
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="p-6 space-y-6">
          {/* Location */}
          <div>
            <label className="label flex items-center">
              <MapPinIcon className="h-5 w-5 mr-2" />
              Address *
            </label>
            <div className="flex space-x-2">
              <input
                type="text"
                name="address"
                value={formData.address}
                onChange={handleInputChange}
                onBlur={() => {
                  if (formData.address && !formData.latitude) {
                    geocodeAddress(formData.address)
                  }
                }}
                className="input-field flex-1"
                placeholder="Enter the address of your parking spot"
                required
              />
              <button
                type="button"
                onClick={getCurrentLocation}
                className="btn-secondary whitespace-nowrap"
              >
                Use Current
              </button>
            </div>
          </div>

          {/* Coordinates */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="label">Latitude</label>
              <input
                type="number"
                name="latitude"
                value={formData.latitude}
                onChange={handleInputChange}
                className="input-field"
                placeholder="e.g., 37.7749"
                step="any"
                required
              />
            </div>
            <div>
              <label className="label">Longitude</label>
              <input
                type="number"
                name="longitude"
                value={formData.longitude}
                onChange={handleInputChange}
                className="input-field"
                placeholder="e.g., -122.4194"
                step="any"
                required
              />
            </div>
          </div>

          {/* Pricing */}
          <div>
            <label className="label flex items-center">
              <CurrencyDollarIcon className="h-5 w-5 mr-2" />
              Hourly Rate *
            </label>
            <input
              type="number"
              name="hourlyRate"
              value={formData.hourlyRate}
              onChange={handleInputChange}
              className="input-field"
              placeholder="e.g., 15"
              min="0"
              step="0.01"
              required
            />
          </div>

          {/* Availability */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="label flex items-center">
                <CalendarIcon className="h-5 w-5 mr-2" />
                Available From *
              </label>
              <input
                type="datetime-local"
                name="availabilityStart"
                value={formData.availabilityStart}
                onChange={handleInputChange}
                className="input-field"
                min={new Date().toISOString().slice(0, 16)}
                required
              />
            </div>
            <div>
              <label className="label flex items-center">
                <CalendarIcon className="h-5 w-5 mr-2" />
                Available Until *
              </label>
              <input
                type="datetime-local"
                name="availabilityEnd"
                value={formData.availabilityEnd}
                onChange={handleInputChange}
                className="input-field"
                min={formData.availabilityStart || new Date().toISOString().slice(0, 16)}
                required
              />
            </div>
          </div>

          {/* Vehicle Size */}
          <div>
            <label className="label flex items-center">
              <TruckIcon className="h-5 w-5 mr-2" />
              Max Vehicle Size
            </label>
            <select
              name="maxVehicleSize"
              value={formData.maxVehicleSize}
              onChange={handleInputChange}
              className="input-field"
            >
              <option value={VehicleSize.ANY}>Any Size</option>
              <option value={VehicleSize.COMPACT}>Compact</option>
              <option value={VehicleSize.MIDSIZE}>Mid-size</option>
              <option value={VehicleSize.LARGE}>Large</option>
              <option value={VehicleSize.SUV}>SUV/Truck</option>
            </select>
          </div>

          {/* Description */}
          <div>
            <label className="label flex items-center">
              <DocumentTextIcon className="h-5 w-5 mr-2" />
              Description
            </label>
            <textarea
              name="description"
              value={formData.description}
              onChange={handleInputChange}
              className="input-field"
              rows={3}
              placeholder="Describe your parking spot (e.g., covered, secure, easy access)"
            />
          </div>

          {/* Preview */}
          {formData.address && formData.hourlyRate && (
            <div className="bg-gray-50 p-4 rounded-lg">
              <h4 className="font-medium text-gray-900 mb-2">Preview</h4>
              <div className="space-y-1 text-sm">
                <p><span className="font-medium">Address:</span> {formData.address}</p>
                <p><span className="font-medium">Rate:</span> ${formData.hourlyRate}/hr</p>
                <p><span className="font-medium">Vehicle Size:</span> {formData.maxVehicleSize}</p>
                {formData.description && (
                  <p><span className="font-medium">Description:</span> {formData.description}</p>
                )}
              </div>
            </div>
          )}

          {/* Actions */}
          <div className="flex space-x-3 pt-4">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 btn-secondary"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={loading}
              className="flex-1 btn-primary"
            >
              {loading ? 'Creating...' : 'Create Spot'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

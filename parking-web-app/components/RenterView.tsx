'use client'

import { useState, useEffect } from 'react'
import { useAuth } from '@/lib/auth-context'
import { apiService } from '@/lib/api'
import { ParkingSpot, Booking, BookingStatus } from '@/types'
import MySpotsView from '@/components/MySpotsView'
import BookingRequestsView from '@/components/BookingRequestsView'
import MyBookingsView from '@/components/MyBookingsView'
import AddSpotView from '@/components/AddSpotView'
import LoadingSpinner from '@/components/LoadingSpinner'
import { 
  HomeIcon, 
  ClockIcon, 
  CalendarIcon, 
  PlusIcon 
} from '@heroicons/react/24/outline'
import toast from 'react-hot-toast'

type TabType = 'spots' | 'requests' | 'bookings'

export default function RenterView() {
  const { user } = useAuth()
  const [activeTab, setActiveTab] = useState<TabType>('spots')
  const [showAddSpot, setShowAddSpot] = useState(false)
  const [loading, setLoading] = useState(false)

  const tabs = [
    {
      id: 'spots' as const,
      name: 'My Spots',
      icon: HomeIcon,
      description: 'Manage your parking spots'
    },
    {
      id: 'requests' as const,
      name: 'Requests',
      icon: ClockIcon,
      description: 'Review booking requests'
    },
    {
      id: 'bookings' as const,
      name: 'Bookings',
      icon: CalendarIcon,
      description: 'View confirmed bookings'
    }
  ]

  const handleAddSpot = () => {
    setShowAddSpot(true)
  }

  const handleSpotAdded = () => {
    setShowAddSpot(false)
    toast.success('Parking spot added successfully!')
  }

  const handleSpotAddedError = (error: string) => {
    toast.error(error)
  }

  const renderContent = () => {
    switch (activeTab) {
      case 'spots':
        return <MySpotsView />
      case 'requests':
        return <BookingRequestsView />
      case 'bookings':
        return <MyBookingsView />
      default:
        return <MySpotsView />
    }
  }

  if (!user) {
    return null
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Rent Out Spot</h1>
          <p className="text-gray-600">Manage your parking spots and bookings</p>
        </div>

        {activeTab === 'spots' && (
          <button
            onClick={handleAddSpot}
            className="btn-primary flex items-center"
          >
            <PlusIcon className="h-5 w-5 mr-2" />
            Add New Spot
          </button>
        )}
      </div>

      {/* Tab Navigation */}
      <div className="border-b border-gray-200">
        <nav className="-mb-px flex space-x-8">
          {tabs.map((tab) => {
            const Icon = tab.icon
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`group inline-flex items-center py-2 px-1 border-b-2 font-medium text-sm transition-colors ${
                  activeTab === tab.id
                    ? 'border-primary-500 text-primary-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                <Icon
                  className={`mr-2 h-5 w-5 ${
                    activeTab === tab.id ? 'text-primary-500' : 'text-gray-400 group-hover:text-gray-500'
                  }`}
                />
                {tab.name}
              </button>
            )
          })}
        </nav>
      </div>

      {/* Tab Description */}
      <div>
        <p className="text-sm text-gray-600">
          {tabs.find(tab => tab.id === activeTab)?.description}
        </p>
      </div>

      {/* Content */}
      <div className="animate-fade-in">
        {renderContent()}
      </div>

      {/* Add Spot Modal */}
      {showAddSpot && (
        <AddSpotView
          onClose={() => setShowAddSpot(false)}
          onSuccess={handleSpotAdded}
          onError={handleSpotAddedError}
        />
      )}
    </div>
  )
}

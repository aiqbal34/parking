'use client'

import { useState } from 'react'
import { useAuth } from '@/lib/auth-context'
import Navigation from '@/components/Navigation'
import FinderView from '@/components/FinderView'
import RenterView from '@/components/RenterView'
import ProfileView from '@/components/ProfileView'
import { MapIcon, HomeIcon, UserIcon } from '@heroicons/react/24/outline'

export default function DashboardPage() {
  const { user } = useAuth()
  const [activeTab, setActiveTab] = useState<'finder' | 'renter' | 'profile'>('finder')

  const tabs = [
    {
      id: 'finder' as const,
      name: 'Find Parking',
      icon: MapIcon,
      description: 'Find available parking spots near you'
    },
    {
      id: 'renter' as const,
      name: 'Rent Out Spot',
      icon: HomeIcon,
      description: 'Manage your parking spots and bookings'
    },
    {
      id: 'profile' as const,
      name: 'Profile',
      icon: UserIcon,
      description: 'Manage your account settings'
    }
  ]

  const renderContent = () => {
    switch (activeTab) {
      case 'finder':
        return <FinderView />
      case 'renter':
        return <RenterView />
      case 'profile':
        return <ProfileView />
      default:
        return <FinderView />
    }
  }

  if (!user) {
    return null
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <Navigation />
      
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Tab Navigation */}
        <div className="mb-8">
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
          <div className="mt-4">
            <p className="text-sm text-gray-600">
              {tabs.find(tab => tab.id === activeTab)?.description}
            </p>
          </div>
        </div>

        {/* Content */}
        <div className="animate-fade-in">
          {renderContent()}
        </div>
      </div>
    </div>
  )
}

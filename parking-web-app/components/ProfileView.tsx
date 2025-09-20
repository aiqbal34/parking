'use client'

import { useState } from 'react'
import { useAuth } from '@/lib/auth-context'
import { UserIcon, EnvelopeIcon, PhoneIcon, CalendarIcon } from '@heroicons/react/24/outline'
import { format } from 'date-fns'

export default function ProfileView() {
  const { user, logout } = useAuth()
  const [showEditForm, setShowEditForm] = useState(false)
  const [editData, setEditData] = useState({
    name: user?.name || '',
    phone_number: user?.phone_number || ''
  })

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target
    setEditData(prev => ({
      ...prev,
      [name]: value
    }))
  }

  const handleSave = async () => {
    // Profile update functionality would go here
    setShowEditForm(false)
  }

  const handleCancel = () => {
    setEditData({
      name: user?.name || '',
      phone_number: user?.phone_number || ''
    })
    setShowEditForm(false)
  }

  if (!user) {
    return null
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Profile</h1>
        <p className="text-gray-600">Manage your account information</p>
      </div>

      {/* Profile Card */}
      <div className="card p-6">
        <div className="flex items-start space-x-6">
          {/* Avatar */}
          <div className="flex-shrink-0">
            <div className="h-20 w-20 bg-primary-100 rounded-full flex items-center justify-center">
              <UserIcon className="h-10 w-10 text-primary-600" />
            </div>
          </div>

          {/* Profile Info */}
          <div className="flex-1">
            <div className="flex items-center justify-between mb-4">
              <div>
                <h2 className="text-xl font-semibold text-gray-900">
                  {user.name || 'User'}
                </h2>
                <p className="text-gray-600">{user.email}</p>
              </div>
              
              {!showEditForm && (
                <button
                  onClick={() => setShowEditForm(true)}
                  className="btn-secondary"
                >
                  Edit Profile
                </button>
              )}
            </div>

            {/* Profile Details */}
            <div className="space-y-4">
              <div className="flex items-center text-sm text-gray-600">
                <EnvelopeIcon className="h-4 w-4 mr-3" />
                <span className="font-medium mr-2">Email:</span>
                <span>{user.email}</span>
              </div>

              <div className="flex items-center text-sm text-gray-600">
                <PhoneIcon className="h-4 w-4 mr-3" />
                <span className="font-medium mr-2">Phone:</span>
                <span>{user.phone_number || 'Not provided'}</span>
              </div>

              <div className="flex items-center text-sm text-gray-600">
                <CalendarIcon className="h-4 w-4 mr-3" />
                <span className="font-medium mr-2">Member since:</span>
                <span>{format(new Date(user.created_at), 'MMM d, yyyy')}</span>
              </div>
            </div>
          </div>
        </div>

        {/* Edit Form */}
        {showEditForm && (
          <div className="mt-6 pt-6 border-t border-gray-200">
            <h3 className="text-lg font-medium text-gray-900 mb-4">Edit Profile</h3>
            <div className="space-y-4">
              <div>
                <label className="label">Full Name</label>
                <input
                  type="text"
                  name="name"
                  value={editData.name}
                  onChange={handleInputChange}
                  className="input-field"
                  placeholder="Enter your full name"
                />
              </div>

              <div>
                <label className="label">Phone Number</label>
                <input
                  type="tel"
                  name="phone_number"
                  value={editData.phone_number}
                  onChange={handleInputChange}
                  className="input-field"
                  placeholder="Enter your phone number"
                />
              </div>

              <div className="flex space-x-3">
                <button
                  onClick={handleCancel}
                  className="btn-secondary"
                >
                  Cancel
                </button>
                <button
                  onClick={handleSave}
                  className="btn-primary"
                >
                  Save Changes
                </button>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Account Actions */}
      <div className="card p-6">
        <h3 className="text-lg font-medium text-gray-900 mb-4">Account Actions</h3>
        <div className="space-y-3">
          <button
            onClick={logout}
            className="w-full btn-danger text-left"
          >
            Sign Out
          </button>
        </div>
      </div>

      {/* App Info */}
      <div className="card p-6">
        <h3 className="text-lg font-medium text-gray-900 mb-4">About Parking App</h3>
        <div className="space-y-2 text-sm text-gray-600">
          <p>Version 1.0.0</p>
          <p>Find or rent parking spots near you with ease.</p>
        </div>
      </div>
    </div>
  )
}

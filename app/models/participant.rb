# == Schema Information
#
# Table name: participants
#
#  id              :bigint           not null, primary key
#  email           :string           not null
#  name            :string           not null
#  password_digest :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_participants_on_email  (email) UNIQUE
#
class Participant < ApplicationRecord
  has_many :teams, dependent: :destroy
  has_many :pools, through: :teams

  has_secure_password validations: false

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 6, message: "must be at least 6 characters" }, allow_nil: true

  def registered?
    password_digest.present?
  end
end

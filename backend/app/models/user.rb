class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :jwt_authenticatable,
         jwt_revocation_strategy: JwtDenylist

  # Relaciones
  has_many :credit_applications, dependent: :destroy

  before_create :set_jti

  private

  def set_jti
    self.jti = SecureRandom.uuid
  end
end

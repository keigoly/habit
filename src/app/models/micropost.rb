class Micropost < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :history, optional: true
  has_many :likes, dependent: :destroy
  has_many  :likers, through: :likes, source: :user
  validates :user, presence: true
  validates :content, presence: true, length: {maximum: 255}
end

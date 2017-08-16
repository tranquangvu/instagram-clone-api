# == Schema Information
#
# Table name: users
#
#  id              :integer          not null, primary key
#  username        :string
#  email           :string
#  password_digest :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  avatar          :string
#  facebook_id     :string
#
# Indexes
#
#  index_users_on_facebook_id  (facebook_id)
#  index_users_on_username     (username) UNIQUE
#

class User < ApplicationRecord
  has_secure_password

  # associations
  has_many :posts, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :liked_posts, through: :likes, source: :post
  has_many :active_relationships, class_name: 'Relationship', foreign_key: 'follower_id', dependent: :destroy
  has_many :following, through: :active_relationships, source: :followed
  has_many :passive_relationships, class_name: 'Relationship', foreign_key: 'followed_id', dependent: :destroy
  has_many :followers, through: :passive_relationships, source: :follower
  has_many :notifications, dependent: :destroy, foreign_key: 'recipient_id'

  # validations
  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: /\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i }, unless: :facebook_login?
  validates :username, presence: true, uniqueness: { case_sensitive: false }, length: { in: 2..20 }
  validates :password, length: { minimum: 8 }, unless: :facebook_login?

  # uploaders
  mount_uploader :avatar, AvatarUploader

  def like!(post)
    likes.where(post_id: post.id).first_or_create!
  end

  def dislike!(post)
    likes.where(post_id: post.id).destroy_all
  end

  def follow(other_user)
    return false if self.id == other_user.id
    active_relationships.first_or_create(followed_id: other_user.id)
  end

  def unfollow(other_user)
    active_relationships.where(followed_id: other_user.id).destroy_all
  end

  def following?(other_user)
    following_ids.include?(other_user.id)
  end

  def avatar_url(options = {})
    return super(options) unless facebook_login?
    "http://graph.facebook.com/#{facebook_id}/picture?type=normal"
  end

  private

  def facebook_login?
    facebook_id.present?
  end
end

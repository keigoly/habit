class User < ApplicationRecord
  has_many :belongs, dependent: :destroy
  has_many :belonging, through: :belongs, source: :group
  has_many :achieving, through: :belongs, source: :achievement
  has_many :groups, dependent: :destroy
  has_many :microposts, dependent: :destroy
  has_many :active_relationships, class_name: "Relationship",
                                  foreign_key: "follower_id",
                                  dependent: :destroy
  has_many :following, through: :active_relationships, source: :followed
  has_many :passive_relationships, class_name: "Relationship",
                                   foreign_key: "followed_id",
                                   dependent: :destroy
  has_many :followers, through: :passive_relationships, source: :follower
  has_one_attached :image
  validates :name, presence: true, length: {maximum: 50}
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  validates :email, presence: true, length: {maximum: 255},
                                    format: {with: VALID_EMAIL_REGEX},
                                    uniqueness: {case_sensitive: false}
  validates :introduction, length: {maximum: 255}
  has_secure_password
  validates :password, presence: true, length: {minimum: 8}, allow_nil:true
  validates :image, content_type: { in: %w[image/jpeg image/gif image/png],
                                    message: "形式が無効です" },
                    size:         { less_than: 5.megabytes,
                                    message: "サイズが5MB超過です" }

    def profile_image
      image.variant(resize_to_limit: [150, 150])
    end

    def belong(group)
      belonging << group
      belongs.find_by(group: group).create_achievement
    end

    def belonging?(group)
      belonging.include?(group)
    end

    def leave(group)
      belongs.find_by(group: group).destroy
    end

    def achieved?(group)
      if self.belonging?(group)
        @achievement = achieving.find_by(belong: self.belongs.find_by(group: group))
        if @achievement.histories.find_by(date: Date.today) == nil
          @achievement.update(achieved: false)
        else
          @achievement.update(achieved: true)
        end
        @achievement.achieved
      end
    end

    def not_achieved
      not_achieved_list = []
      belonging.each do |group|
        unless achieved?(group)
          not_achieved_list.push(group.id)
        end
      end
      not_achieved_record = Group.where("id IN (?)", not_achieved_list )
    end

    def toggle_achieved(group)
      if achieved?(group)
        @history = History.find_by(achievement: @achievement, date: Date.today)
        @history.destroy unless @history == nil
      else
        if @achievement.histories.find_by(date: Date.today) == nil
          @history = @achievement.histories.create(date: Date.today)
          @history.microposts.create(user: self, content: "#{@history.date} 分の <a href=\"/groups/#{group.id}\">#{group.name}</a> の目標を達成しました。\n目標：#{group.habit}")
        end
      end
      @achievement.toggle!(:achieved) if self.belonging?(group)
    end

    def feed
      group_ids = "SELECT group_id FROM belongs
                   WHERE user_id = :user_id"
      group_members_ids = "SELECT user_id FROM belongs
                           WHERE group_id IN (#{group_ids})"
      Micropost.where("user_id IN (#{group_members_ids})
                       OR user_id = :user_id",
                       user_id: id).order("created_at DESC")
    end

    def encouraged_feed
      group_ids = "SELECT group_id FROM belongs
                   WHERE user_id = :user_id"
      group_members_ids = "SELECT user_id FROM belongs
                           WHERE group_id IN (#{group_ids})
                           AND user_id != :user_id"
      belong_ids = "SELECT id FROM belongs
                    WHERE user_id IN (#{group_members_ids})"
      achievement_ids = "SELECT id FROM achievements
                         WHERE belong_id IN (#{belong_ids})"
      history_ids = "SELECT id FROM histories
                     WHERE achievement_id IN (#{achievement_ids})
                     AND date = :today"
      Micropost.where("history_id IN (#{history_ids})
                       AND encouragement = true",
                       user_id: id, today: Date.today).order("created_at DESC")
    end

    def follow(other_user)
      following << other_user
    end

    def unfollow(other_user)
      active_relationships.find_by(followed: other_user).destroy
    end

    def following?(other_user)
      following.include?(other_user)
    end

    def followed_by?(other_user)
      followers.include?(other_user)
    end

end

class Movie < ActiveRecord::Base
  validates :title, presence: true, uniqueness: {case_insensitive: true}
  validates :director, presence: true
end

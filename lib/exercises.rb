# frozen_string_literal: true

require_relative 'workouts'
require_relative 'db'

class Exercise < Sequel::Model
  many_to_many :workouts
  one_to_many :sets
end

require_relative 'lib/base'

class Person < ReactiveRecord::Base
  validates :first_name, presence: true
  validates :last_name, presence: { message: 'Yes, last name is usally the same as House name, but it still must exist!' }
  validates :age, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than: 100 }

  belongs_to :house
  has_one_through :region, :house, :region
  has_many :pets, foreign_key: :owner_id

  before_validation :age_plus_one, :nth_of_his_name

  finalize!

  private

  def age_plus_one
    self.age += 1
  end

  def nth_of_his_name
    if Person.exists?(first_name: self.first_name, last_name: self.last_name)
      self.first_name += ' II'
    end
  end
end

class Pet < ReactiveRecord::Base
  validates :name, presence: true, uniqueness: true
  validates :species, presence: true, inclusion: { in: ['Dire Wolf', 'Dragon'] }

  belongs_to :owner, class_name: 'Person'
  has_one_through :house, :owner, :house
  has_one_through :region, :house, :region

  finalize!
end

class House < ReactiveRecord::Base
  validates :name, :seat, :sigil, presence: true, uniqueness: true
  validates :words, uniqueness: { allow_nil: true }, length: { minimum: 2 }

  belongs_to :region
  has_many :people, class_name: 'Person'
  has_many_through :pets, :people, :pets

  finalize!
end

class Region < ReactiveRecord::Base
  validates :name, presence: true, uniqueness: true

  has_many :houses
  has_many_through :people, :houses, :people
  has_many_through :pets, :people, :pets

  finalize!
end

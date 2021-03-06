require_relative 'lib/base'

class Person < ReactiveRecord::Base
  validates :first_name, presence: true
  validates :last_name, presence: { message: 'Yes, last name is usually the same as House name, but it still must exist!' }
  validates :age, presence: true, numericality: { only_integer: true, less_than: 100 }
  validates :sex, presence: true, inclusion: { in: ['M', 'F'] }

  belongs_to :house
  has_one_through :region, :house, :region
  has_many :pets, foreign_key: :owner_id

  after_create :age_plus_one
  after_initialize :nth_of_his_name

  finalize!

  private

  def age_plus_one
    self.age += 1
  end

  def nth_of_his_name
    return unless self.first_name && self.last_name
    return if self.id
    suffixes = {1 => 'st', 2 => 'nd', 3 => 'rd'}
    name_count = Person.where('first_name = ? AND last_name LIKE ?', self.first_name, "#{self.last_name}%").count
    n = name_count + 1
    suffix = suffixes[n] || 'th'
    pronoun = self.sex == 'M' ? 'his' : 'her'
    self.last_name += ", #{n}#{suffix} of #{pronoun} name"
  end
end

class Pet < ReactiveRecord::Base
  validates :name, presence: true, uniqueness: true, format: { without: /\d+/ }
  validates :species, presence: true, inclusion: { in: ['Dire Wolf', 'Dragon'] }

  belongs_to :owner, class_name: 'Person'
  has_one_through :house, :owner, :house
  has_one_through :region, :house, :region

  finalize!
end

class House < ReactiveRecord::Base
  validates :name, :seat, :sigil, presence: true, uniqueness: true
  validates :words, length: { minimum: 6, allow_nil: true }

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

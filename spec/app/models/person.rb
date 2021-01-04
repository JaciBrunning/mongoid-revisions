class Person
  include Mongoid::Document
  include Mongoid::Revisions

  field :name, type: String
  has_and_belongs_to_many :pets
  embeds_many :addresses
end
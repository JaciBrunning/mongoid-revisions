class Address
  include Mongoid::Document

  field :address, type: String
  embedded_in :person
end
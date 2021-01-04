Mongoid::Revisions
===
This gem adds the ability to keep revisions (versions) of your Mongoid documents to allow you to go back in time. 

This gem supports not only the base model itself, but also relations and embeds, as well as inherited types. Revision creation is not automatic, but rather triggered manually.

_This gem was inspired by Mongoid::Versioning, originally a part of Mongoid until it was extracted into [its own gem](https://github.com/ream88/mongoid-versioning). This gem shares no relation to [mongoid_revisions](https://github.com/emilianodellacasa/mongoid_revisions)_

## Installation
In your Gemfile:
```ruby
gem 'mongoid-revisions', github: 'JaciBrunning/mongoid-revisions'
```

## Usage
```ruby
class Person
  include Mongoid::Document
  # Make this model track revisions
  # This will implicitly include Mongoid::Timestamps::Updated
  include Mongoid::Revisions

  # [optional] Ignore field(s) when storing revisions
  revisions_ignore :my_field, :my_other_field
end
```

### Creating revisions
Revisions can be made with `.revise`
```ruby
person = Person.create(name: "John Smith")
person.revise  # => true
```

Revisions will only be made if there are changes. `.revise` will return `false` if a revision was not made.

```ruby
person = Person.create(name: "John Smith")
person.revise   # => true
person.revise   # => false

person.name = "Jane Smith"
person.revise   # => true
```

`.revise!` will force a new revision, even if no changes exist.
```ruby
person = Person.create(name: "John Smith")
person.revise   # => true
person.revise!  # => true
```

### Working with revisions
All revisions of a model are available in `.revisions`, with the oldest at the start and newest at the end.
```ruby
person = Person.create(name: "John Smith")
person.revise
person.name = "Jane Smith"
person.revise

person.has_revisions?   # => true
person.revisions  # => [ ModelRevision, ModelRevision, ... ]
person.revisions.first  # => <ModelRevision model_class=Person idx=1 updated_at=...>
person.revisions.last   # => <ModelRevision model_class=Person idx=2 updated_at=...>
```

Revisions can be restored using `.reify()`
```ruby
old_person = person.revisions.first.reify()
old_person.name   # => "John Smith"
```

You can also get a revision by timestamp, which are automatically reified.
```ruby
# What did this look like in May?
person.revision_at(DateTime.new(2020, 5))  # => <Person ...>
# If the timestamp is before the revision history begins, the earliest revision will be returned. If the timestamp is more recent, the current, live version will be returned.
```

The current reified revision can be queried with `.revision`
```ruby
old_person.revision?  # => true
old_person.revision   # => <ModelRevision ...>

person.revision?      # => false
person.revision       # => nil
```

You can also check if the current object is live
```ruby
person.live?      # => true
old_person.live?  # => false
```

### Associations and Embeds
mongoid-revisions works with embeds and associations out of the box. For embeds, the full structure of the embedded document is tracked. For associations, only has_many_and_belongs_to and belongs_to are tracked for the ID field, meaning updates in the child documents will not trigger a new change upstream. In essence, the changes are recorded as the document appears in mongodb.

```ruby
class Person
  include Mongoid::Document
  include Mongoid::Revisions

  field :name, type: String
  has_and_belongs_to_many :pets
  embeds_many :addresses
end

class Pet
  include Mongoid::Document

  field :name, type: String
end

class Address
  include Mongoid::Document

  field :address, type: String
  embedded_in :person
end

pet = Pet.create(name: "Mr Whiskers")
person = Person.create(name: "John Smith")
person.revise   # V1

person.addresses.create(address: "10 Downing St")
person.pets << pet
person.revise   # V2

pet.update name: "Mr Bark"      # This will not be tracked by person
person.pets.clear               # This will be tracked
person.addresses.first.update address: "5 Adelaide Ave"   # This will
person.revise   # V3

person.revisions[0].reify  # addresses: [], pets: []
person.revisions[1].reify  # addresses: ["10 Downing St"], pets: ["Mr Bark"]
person.revisions[2].reify  # addresses: ["5 Adelaide Ave"], pets: []
```

Note that if `Pet` were to include its own revisions, you could use `person.pets.map! { |x| x.revision_at person.updated_at } if person.version?`
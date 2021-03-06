# Tenancy [![Gem Version](https://badge.fury.io/rb/tenancy.png)](http://badge.fury.io/rb/tenancy) [![Build Status](https://travis-ci.org/yoolk/tenancy.png?branch=master)](https://travis-ci.org/yoolk/tenancy) [![Code Climate](https://codeclimate.com/repos/527a1d45f3ea005378005fdb/badges/cfbc9ff8993d02e13b9d/gpa.png)](https://codeclimate.com/repos/527a1d45f3ea005378005fdb/feed) [![Dependency Status](https://gemnasium.com/yoolk/tenancy.png)](https://gemnasium.com/yoolk/tenancy)

**Tenancy** is a simple gem that provides multi-tenancy support on activerecord through scoping. I suggest you to watch an excellent [RailsCast on Multitenancy with Scopes](http://railscasts.com/episodes/388-multitenancy-with-scopes) and read this book [Multitenancy with Rails](https://leanpub.com/multi-tenancy-rails).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tenancy'
```

And then execute:

```
$ bundle
```

## Usage

This gem provides two modules: `Tenancy::Resource` and `Tenancy::ResourceScope`.

### Tenancy::Resource

`Tenancy::Resource` is a module which you want others to be scoped by.

```ruby
class Portal < ActiveRecord::Base
  include Tenancy::Resource
end

camyp = Portal.where(domain_name: 'yp.com.kh').first
# => <Portal id: 1, domain_name: 'yp.com.kh'>

# set current portal by id
Portal.current = camyp

# or portal object
Portal.current = 1

# get current portal
Portal.current
# => <Portal id: 1, domain_name: 'yp.com.kh'>

# scope with this portal
Portal.with(camyp) do
  # Do something here with this portal
end
```

### Tenancy::ResourceScope

`Tenancy::ResourceScope` is a module which you want to scope itself to `Tenancy::Resource`.

```ruby
class Listing < ActiveRecord::Base
  include Tenancy::Resource
  include Tenancy::ResourceScope

  scope_to :portal
  validates_uniqueness_in_scope :name, case_sensitive: false
end

class Communication < ActiveRecord::Base
  include Tenancy::ResourceScope

  scope_to :portal, :listing
  default_scope -> { where(is_active: true) }
  validates_uniqueness_in_scope :value
end

class ExtraCommunication < ActiveRecord::Base
  include Tenancy::ResourceScope

  # options here will send to #belongs_to
  scope_to :portal, class_name: 'Portal'
  scope_to :listing, class_name: 'Listing'
  validates_uniqueness_in_scope :value
end

> Portal.current = 1
> Listing.find(1).to_sql
# => SELECT "listings".* FROM "listings" WHERE "portal_id" = 1 AND "id" = 1

> Listing.current = 1
> Communication.find(1).to_sql
# => SELECT "communications".* FROM "communications" WHERE "portal_id" = 1 AND "listing_id" = 1 AND "is_active" = true AND "id" = 1

# unscoped :current_portal, :current_listing
> Communication.without_scope(:portal).find(1)
# => SELECT "communications".* FROM "communications" WHERE "listing_id" = 1 AND "is_active" = true AND "id" = 1
> Communication.without_scope(:listing).find(1)
# => SELECT "communications".* FROM "communications" WHERE "portal_id" = 1 AND "is_active" = true AND "id" = 1
> Communication.without_scope(:portal, :listing).find(1)
# => SELECT "communications".* FROM "communications" WHERE "is_active" = true AND "id" = 1
```

`scope_to :portal` does 4 things:

1. it adds `belongs_to :portal`.

2. it adds `validates :portal, presence: true`.

3. it adds `default_scope { where(portal_id: Portal.current) if Portal.current }`.

4. it overrides `#portal` so that it doesn't touch the database if `portal_id` in that record is the same as `Portal.current_id`.

`validates :value, uniqueness: true` will validates uniqueness against the whole table. `validates_uniqueness_in_scope` validates uniqueness with the scopes you passed in `scope_to`.

## Rails

Because `#current` is using thread variable, it's advisable to set to `nil` after processing controller action. This can be easily achievable by using `around_filter` and `#with` inside `application_controller.rb`. Or, you can do it manually by using `#current=`.

```ruby
class ApplicationController < ActionController::Base
  around_filter :route_domain

  protected

    def route_domain(&block)
      Portal.with(current_portal, &block)
    end

    def current_portal
      @current_portal ||= Portal.find_by_domain_name(request.host)
    end
end
```

From version 0.2.0 up, you don't need to use `around_filter` because this gem add [request_store](https://github.com/steveklabnik/request_store) as dependency. It will clear threaded variables inside middleware on every request. You can just use `before_filter` to set the current tenant.

```ruby
class ApplicationController < ActionController::Base
  before_filter :scope_current_portal

  protected

    def current_portal
      Portal.current
    end

    def scope_current_portal
      Portal.current = Portal.find_by_domain_name(request.host)
    end
end
```

## Indexes

```ruby
add_index :listings, :portal_id
add_index :communications, [:portal_id, :listing_id]
```

## RSpec

In spec_helper.rb, you'll need to require the matchers:

```ruby
require "tenancy/matchers"
```

Example:

```ruby
describe Portal do
  it { should be_a_tenant }
end
```

```ruby
describe Listing do
  it { should have_scope_to(:portal) }
  it { should have_scope_to(:portal).class_name('Portal') }
end
```

## Authors

* [Chamnap Chhorn](https://github.com/chamnap)

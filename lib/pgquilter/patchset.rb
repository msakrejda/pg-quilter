module PgQuilter
  class Patchset < Sequel::Model
    many_to_one :topics
    one_to_many :patches
  end
end

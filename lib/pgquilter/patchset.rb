module PGQuilter
  class Patchset < Sequel::Model
    many_to_one :topic
    one_to_many :patches
  end
end

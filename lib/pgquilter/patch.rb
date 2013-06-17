module PGQuilter
  class Patch < Sequel::Model
    many_to_one :patchset
    one_to_many :applications
  end
end

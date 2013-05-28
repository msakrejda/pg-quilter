module PgQuilter
  class Patch < Sequel::Model
    many_to_one :patchsets
  end
end

Sequel.migration do
  change do
    create_table :users do
      uuid :uuid, default: 'uuid_generate_v4()'.lit, primary_key: true
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      text :provider
      text :uid
    end
  end
end

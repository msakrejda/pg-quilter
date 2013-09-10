Sequel.migration do
  change do
    create_table :api_tokens do
      uuid :uuid, default: 'uuid_generate_v4()'.lit, primary_key: true
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      text :secret, null: false
    end
  end
end

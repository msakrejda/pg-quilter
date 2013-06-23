Sequel.migration do
  change do
    create_table :failures do
      uuid :uuid, default: 'uuid_generate_v4()'.lit, primary_key: true
      timestamptz :created_at, null: false, default: 'now()'.lit
      text :message_id, null: false
      text :error, null: false
    end
  end
end

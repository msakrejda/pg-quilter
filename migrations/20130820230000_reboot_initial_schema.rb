Sequel.migration do
  change do
    self.execute <<-EOF
    CREATE EXTENSION IF NOT EXISTS hstore;
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
EOF

    create_table :builds do
      uuid :uuid, default: 'uuid_generate_v4()'.lit, primary_key: true
      timestamptz :created_at, null: false, default: 'now'
      text :base_rev, null: false
    end

    create_table :patches do
      uuid :uuid, default: 'uuid_generate_v4()'.lit, primary_key: true
      foreign_key :build_id, :builds, type: :uuid, null: false
      int :order, null: false
      text :body, null: false
    end
  end
end

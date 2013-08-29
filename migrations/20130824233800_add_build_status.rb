Sequel.migration do
  change do
    self.execute <<-EOF
    CREATE TYPE step AS ENUM (
        'reset', 'apply patch', 'configure', 'make',
        'make contrib', 'make check', 'make contribcheck'
    );
EOF

    create_table :build_steps do
      uuid :uuid, default: 'uuid_generate_v4()'.lit, primary_key: true
      foreign_key :build_id, :builds, type: :uuid, null: false
      step :name, null: false
      timestamptz :started_at, null: false
      timestamptz :completed_at, null: false, default: 'now'
      text :stdout, null: false
      text :stderr, null: false
      int :status, null: false
      hstore :attrs
    end

  end
end

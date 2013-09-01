Sequel.migration do
  change do
    self.execute <<-EOF
    CREATE TYPE build_state AS ENUM('pending', 'running', 'complete');
EOF
    add_column :builds, :state, :build_state, default: 'pending', null: false
  end
end

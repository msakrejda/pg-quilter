Sequel.migration do
  change do
    create_table :topics do
      uuid :uuid, default: 'uuid_generate_v4()'.lit, primary_key: true
      text :name, null: false
      text :pull_request, null: false
      timestamptz :created_at, null: false, default: 'now()'.lit
      text :committed_in
    end

    create_table :patchsests do
      uuid :uuid, default: 'uuid_generate_v4()'.lit, primary_key: true
      foreign_key :topic_id, :topics
      text :message_id, null: false
      timestamptz :created_at, null: false, default: 'now()'.lit
    end

    create_table :patches do
      uuid :uuid, default: 'uuid_generate_v4()'.lit, primary_key: true
      foreign_key :patchset_id, :patchsets
      integer :patchset_order
      text :body, null: false
    end

    create_table :applications do
      uuid :uuid, default: 'uuid_generate_v4()'.lit, primary_key: true
      foreign_key :patch_id, :patches
      text :base_sha, null: false
      boolean :succeeded, null: false
      text :output, null: false
      timestamptz :created_at, null: false, default: 'now()'.lit
    end
  end
end

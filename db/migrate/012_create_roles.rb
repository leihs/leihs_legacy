class CreateRoles < ActiveRecord::Migration
  def self.up
    create_table :roles do |t|
      t.integer :parent_id  # acts_as_nested_set
      t.integer :lft        # acts_as_nested_set
      t.integer :rgt        # acts_as_nested_set

      t.string :name
      #t.timestamps
    end

    r_im = Role.create(:name => "inventory_manager")
    r_s = Role.create(:name => "student")
    r_s.move_to_child_of r_im

  end

  def self.down
    drop_table :roles
  end
end

class AddGroupRolesToUsers < ActiveRecord::Migration[6.1]
  def change
    # Create a new table for group roles
    create_table :group_roles do |t|
      t.references :user, null: false, foreign_key: true
      t.references :group, null: false, foreign_key: true
      t.string :role, null: false, default: "member"
      t.jsonb :permissions, default: {}

      t.timestamps
    end

    # Add an index for quick lookup by user and group
    add_index :group_roles, [:user_id, :group_id], unique: true

    # Remove the old column from the users table
    # Deprecate system-wide roles for group-specific roles
    remove_column :users, :group_role, :string, if_exists: true
  end
end

# -------------------------------------------------
# Example Usage: Assigning Roles
# -------------------------------------------------
# Assign a role to a user in a specific group
# GroupRole.create!(
#   user: user, # Instance of the User model
#   group: group, # Instance of the Group model
#   role: "group_admin", # Role name
#   permissions: { 
#     can_add_members: true, 
#     can_edit_group: true 
#   } # Custom permissions for this role
# )

# -------------------------------------------------
# Example Usage: Querying Roles
# -------------------------------------------------
# Retrieve all roles for a specific user
# roles = GroupRole.where(user: user)
# roles.each do |role|
#   puts "User #{role.user.id} is a #{role.role} in group #{role.group.id}"
# end

# Retrieve all users with a specific role in a group
# users = GroupRole.where(group: group, role: "group_admin").map(&:user)

# -------------------------------------------------
# Example Usage: Modifying Permissions
# -------------------------------------------------
# Update permissions for a specific user's role in a group
# role = GroupRole.find_by(user: user, group: group)
# role.update!(permissions: { 
#   can_add_members: false, 
#   can_edit_group: true 
# })

# -------------------------------------------------
# Example Usage: Permission Checks
# -------------------------------------------------
# Check if a user has a specific permission within a group
# role = GroupRole.find_by(user: user, group: group)
# if role.permissions["can_add_members"]
#   puts "User #{user.id} can add members to group #{group.id}"
# else
#   puts "Permission denied"
# end

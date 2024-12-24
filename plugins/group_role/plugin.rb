# plugins/group_roles_plugin/plugin.rb
# frozen_string_literal: true

# Plugin metadata
# name: group_roles_plugin
# about: Adds group roles with permissions specific to the group they belong to.
# version: 0.3
# authors: Raphael Adesegun
# url: https://github.com/TheInvincibleRalph/group_roles_plugin

enabled_site_setting :group_roles_enabled

after_initialize do
  module ::GroupRolesPlugin
    ROLES = {
      "group_admin" => {
        can_edit_group: true,
        can_add_members: true,
        can_remove_members: true,
        can_manage_roles: true
      },
      "moderator" => {
        can_edit_group: false,
        can_add_members: true,
        can_remove_members: true,
        can_manage_roles: false
      },
      "member" => {
        can_edit_group: false,
        can_add_members: false,
        can_remove_members: false,
        can_manage_roles: false
      }
    }

    class RolesController < ::ApplicationController
      before_action :ensure_admin, except: [:list]

      def assign
        user = User.find_by(id: params[:user_id])
        group = Group.find_by(id: params[:group_id])
        role = params[:role]

        if user && group && ROLES.key?(role)
          group_role = GroupRole.find_or_initialize_by(user_id: user.id, group_id: group.id)
          if group_role.update(role: role, permissions: ROLES[role])
            render json: { success: true, role: group_role }
          else
            render json: { success: false, errors: group_role.errors.full_messages }, status: 422
          end
        else
          render json: { success: false, error: "Invalid input" }, status: 400
        end
      end

      def remove
        group_role = GroupRole.find_by(user_id: params[:user_id], group_id: params[:group_id])
        if group_role&.destroy
          render json: { success: true }
        else
          render json: { success: false, error: "Role not found" }, status: 404
        end
      end

      def list
        group = Group.find_by(id: params[:group_id])
        if group
          roles = GroupRole.where(group_id: group.id)
          render json: { roles: roles }
        else
          render json: { success: false, error: "Group not found" }, status: 404
        end
      end

      private

      def ensure_admin
        raise Discourse::InvalidAccess unless current_user&.admin?
      end
    end
  end

  # Define routes for API
  Discourse::Application.routes.append do
    post "/group_roles/assign" => "group_roles_plugin/roles#assign"
    delete "/group_roles/remove" => "group_roles_plugin/roles#remove"
    get "/group_roles/list" => "group_roles_plugin/roles#list"
  end

  # Extend Guardian to include role-based permissions
  module ::GuardianExtensions
    def has_permission?(user, permission)
      role = user.group_role
      return false unless role

      permissions = GroupRolesPlugin::ROLES[role]
      permissions ? permissions[permission] : false
    end

    def can_edit_group?(user)
      has_permission?(user, :can_edit_group)
    end

    def can_add_members?(user)
      has_permission?(user, :can_add_members)
    end

    def can_remove_members?(user)
      has_permission?(user, :can_remove_members)
    end

    def can_manage_roles?(user)
      has_permission?(user, :can_manage_roles)
    end
  end

  Guardian.prepend(::GuardianExtensions)
end

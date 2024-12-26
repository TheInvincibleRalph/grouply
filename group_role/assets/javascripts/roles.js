import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "group-roles-ui",
  initialize(container) {
    withPluginApi("0.8.7", (api) => {
      // Add a button to group settings for managing roles
      api.addAdminRoute("group.roles", "/groups/:group_id/roles");

      api.modifyClass("controller:groups-show", {
        actions: {
          manageRoles() {
            const groupId = this.get("model.id");
            this.transitionToRoute("group.roles", groupId);
          },
        },
      });

      // Add custom UI components for role management
      api.onPageChange((url) => {
        if (url.match(/\/groups\/\d+\/roles/)) {
          setupRoleManagementUI();
        }
      });
    });
  },
};

function setupRoleManagementUI() {
  const container = document.querySelector("#main-outlet");
  container.innerHTML = `
    <div id="group-roles-management">
      <h2>Group Roles Management</h2>
      <div id="roles-list"></div>
      <button id="add-role-btn">Add Role</button>
      <button id="assign-role-btn">Assign Role</button>
    </div>
  `;

  // Fetch and display roles
  fetchRoles();

  // Add role handler
  document.getElementById("add-role-btn").addEventListener("click", () => {
    // Show a modal or form to add a new role
    alert("Add role functionality coming soon!");
  });

  // Assign role handler
  document.getElementById("assign-role-btn").addEventListener("click", () => {
    const userId = prompt("Enter user ID to assign a role:");
    const role = prompt("Enter role to assign (group_admin, moderator, member):");

    if (userId && role) {
      assignRole(userId, role);
    }
  });
}

async function fetchRoles() {
  const groupId = window.location.pathname.split("/")[2];
  const response = await fetch(`/group_roles/list?group_id=${groupId}`);
  const data = await response.json();

  const rolesList = document.getElementById("roles-list");
  rolesList.innerHTML = data.roles
    .map(
      (role) =>
        `<div>
          <strong>${role.role}</strong> - ${JSON.stringify(role.permissions)}
          <button data-role-id="${role.id}" class="remove-role-btn">Remove</button>
        </div>`
    )
    .join("");

  document.querySelectorAll(".remove-role-btn").forEach((btn) => {
    btn.addEventListener("click", async (e) => {
      const roleId = e.target.dataset.roleId;
      await fetch(`/group_roles/remove`, {
        method: "DELETE",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ id: roleId }),
      });
      fetchRoles(); // Refresh roles
    });
  });
}

async function assignRole(userId, role) {
  const groupId = window.location.pathname.split("/")[2];
  const response = await fetch(`/group_roles/assign`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ group_id: groupId, user_id: userId, role }),
  });

  if (response.ok) {
    alert("Role assigned successfully!");
    fetchRoles(); // Refresh roles
  } else {
    alert("Failed to assign role.");
  }
}

// spec/views/group_roles_ui_spec.js
import { test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';
import { fetch } from 'fetch';

test('roles list is updated correctly in UI', async function (assert) {
  // Mocking the API call
  const dummyRoles = [
    { role: 'group_admin', permissions: { can_edit_group: true, can_add_members: true } },
    { role: 'member', permissions: { can_edit_group: false, can_add_members: false } }
  ];
  
  fetch.mockResponseOnce(JSON.stringify({ roles: dummyRoles }));

  await render(hbs`{{group-roles-management}}`);

  // Verify the roles are correctly rendered
  assert.dom('.role').exists({ count: 2 }, 'Two roles are displayed');
  assert.dom('.role:first-child').hasText('group_admin', 'First role is group_admin');
});

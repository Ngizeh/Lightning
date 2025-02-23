defmodule Lightning.PermissionsTest do
  use Lightning.DataCase, async: true

  import Lightning.ProjectsFixtures
  import Lightning.AccountsFixtures

  alias Lightning.Policies.{Permissions, Users, ProjectUsers}

  setup do
    %{
      superuser: superuser_fixture(),
      user: user_fixture(),
      another_user: user_fixture()
    }
  end

  describe "User policies by instance-wide role" do
    test ":user permissions", %{user: user, another_user: another_user} do
      refute Users |> Permissions.can(:create_projects, user, {})
      refute Users |> Permissions.can(:view_projects, user, {})
      refute Users |> Permissions.can(:edit_projects, user, {})
      refute Users |> Permissions.can(:create_users, user, {})
      refute Users |> Permissions.can(:view_users, user, {})
      refute Users |> Permissions.can(:edit_users, user, {})
      refute Users |> Permissions.can(:delete_users, user, {})
      refute Users |> Permissions.can(:disable_users, user, {})
      refute Users |> Permissions.can(:access_admin_space, user, {})

      refute Users
             |> Permissions.can(:configure_external_auth_provider, user, {})

      refute Users |> Permissions.can(:view_credentials_audit_trail, user, {})

      refute Users
             |> Permissions.can(:access_own_profile, user, another_user)

      assert Users |> Permissions.can(:access_own_profile, user, user)

      refute Users
             |> Permissions.can(:access_own_credentials, user, another_user)

      assert Users |> Permissions.can(:access_own_credentials, user, user)

      refute Users |> Permissions.can(:change_email, user, another_user)
      assert Users |> Permissions.can(:change_email, user, user)

      refute Users |> Permissions.can(:change_password, user, another_user)
      assert Users |> Permissions.can(:change_password, user, user)

      refute Users |> Permissions.can(:delete_account, user, another_user)
      assert Users |> Permissions.can(:delete_account, user, user)

      refute Users |> Permissions.can(:view_credentials, user, another_user)
      assert Users |> Permissions.can(:view_credentials, user, user)

      refute Users |> Permissions.can(:edit_credentials, user, another_user)
      assert Users |> Permissions.can(:edit_credentials, user, user)

      refute Users |> Permissions.can(:delete_credential, user, another_user)
      assert Users |> Permissions.can(:delete_credential, user, user)
    end

    test ":superuser permissions", %{
      superuser: superuser,
      another_user: another_user
    } do
      assert Users |> Permissions.can(:create_projects, superuser, {})
      assert Users |> Permissions.can(:view_projects, superuser, {})
      assert Users |> Permissions.can(:edit_projects, superuser, {})
      assert Users |> Permissions.can(:create_users, superuser, {})
      assert Users |> Permissions.can(:view_users, superuser, {})
      assert Users |> Permissions.can(:edit_users, superuser, {})
      assert Users |> Permissions.can(:delete_users, superuser, {})
      assert Users |> Permissions.can(:disable_users, superuser, {})
      assert Users |> Permissions.can(:access_admin_space, superuser, {})

      assert Users
             |> Permissions.can(:configure_external_auth_provider, superuser, {})

      assert Users
             |> Permissions.can(:view_credentials_audit_trail, superuser, {})

      refute Users
             |> Permissions.can(:access_own_profile, superuser, another_user)

      assert Users |> Permissions.can(:access_own_profile, superuser, superuser)

      refute Users
             |> Permissions.can(:access_own_credentials, superuser, another_user)

      assert Users
             |> Permissions.can(:access_own_credentials, superuser, superuser)

      refute Users |> Permissions.can(:change_email, superuser, another_user)
      assert Users |> Permissions.can(:change_email, superuser, superuser)

      refute Users |> Permissions.can(:change_password, superuser, another_user)
      assert Users |> Permissions.can(:change_password, superuser, superuser)

      refute Users |> Permissions.can(:delete_account, superuser, another_user)
      assert Users |> Permissions.can(:delete_account, superuser, superuser)

      refute Users |> Permissions.can(:view_credentials, superuser, another_user)
      assert Users |> Permissions.can(:view_credentials, superuser, superuser)

      refute Users |> Permissions.can(:edit_credentials, superuser, another_user)
      assert Users |> Permissions.can(:edit_credentials, superuser, superuser)

      refute Users
             |> Permissions.can(:delete_credential, superuser, another_user)

      assert Users |> Permissions.can(:delete_credential, superuser, superuser)
    end
  end

  setup do
    viewer = user_fixture()
    admin = user_fixture()
    owner = user_fixture()
    editor = user_fixture()
    thief = user_fixture()

    project =
      project_fixture(
        project_users: [
          %{user_id: viewer.id, role: :viewer},
          %{user_id: editor.id, role: :editor},
          %{user_id: admin.id, role: :admin},
          %{user_id: owner.id, role: :owner}
        ]
      )

    %{
      project: project,
      viewer: viewer,
      admin: admin,
      owner: owner,
      editor: editor,
      thief: thief
    }
  end

  describe "Project user policies by project user role" do
    test ":viewer permissions", %{project: project, viewer: viewer} do
      refute ProjectUsers |> Permissions.can(:create_workflow, viewer, project)
      refute ProjectUsers |> Permissions.can(:edit_job, viewer, project)
      refute ProjectUsers |> Permissions.can(:create_job, viewer, project)
      refute ProjectUsers |> Permissions.can(:delete_job, viewer, project)
      refute ProjectUsers |> Permissions.can(:run_job, viewer, project)
      refute ProjectUsers |> Permissions.can(:rerun_job, viewer, project)

      assert ProjectUsers
             |> Permissions.can(:view_last_job_inputs, viewer, project)

      assert ProjectUsers
             |> Permissions.can(:view_workorder_input, viewer, project)

      assert ProjectUsers
             |> Permissions.can(:view_workorder_run, viewer, project)

      assert ProjectUsers
             |> Permissions.can(:view_workorder_history, viewer, project)

      assert ProjectUsers |> Permissions.can(:view_project_name, viewer, project)

      assert ProjectUsers
             |> Permissions.can(:view_project_description, viewer, project)

      assert ProjectUsers
             |> Permissions.can(:view_project_credentials, viewer, project)

      assert ProjectUsers
             |> Permissions.can(:view_project_collaborators, viewer, project)

      refute ProjectUsers |> Permissions.can(:delete_project, viewer, project)

      assert ProjectUsers
             |> Permissions.can(
               :edit_digest_alerts,
               viewer,
               project.project_users |> Enum.at(0)
             )

      refute ProjectUsers
             |> Permissions.can(
               :edit_digest_alerts,
               viewer,
               project.project_users |> Enum.at(1)
             )

      refute ProjectUsers |> Permissions.can(:edit_project_name, viewer, project)

      refute ProjectUsers
             |> Permissions.can(:edit_project_description, viewer, project)

      refute ProjectUsers
             |> Permissions.can(:add_project_collaborator, viewer, project)

      viewer_project_user = project.project_users |> Enum.at(0)
      editor_project_user = project.project_users |> Enum.at(1)

      assert ProjectUsers
             |> Permissions.can(:edit_project_user, viewer, viewer_project_user)

      refute ProjectUsers
             |> Permissions.can(:edit_project_user, viewer, editor_project_user)
    end

    test "editor permissions", %{project: project, editor: editor} do
      assert ProjectUsers |> Permissions.can(:create_workflow, editor, project)
      assert ProjectUsers |> Permissions.can(:edit_job, editor, project)
      assert ProjectUsers |> Permissions.can(:create_job, editor, project)
      assert ProjectUsers |> Permissions.can(:delete_job, editor, project)
      assert ProjectUsers |> Permissions.can(:run_job, editor, project)
      assert ProjectUsers |> Permissions.can(:rerun_job, editor, project)

      assert ProjectUsers
             |> Permissions.can(:view_last_job_inputs, editor, project)

      assert ProjectUsers
             |> Permissions.can(:view_workorder_input, editor, project)

      assert ProjectUsers
             |> Permissions.can(:view_workorder_run, editor, project)

      assert ProjectUsers
             |> Permissions.can(:view_workorder_history, editor, project)

      assert ProjectUsers |> Permissions.can(:view_project_name, editor, project)

      assert ProjectUsers
             |> Permissions.can(:view_project_description, editor, project)

      assert ProjectUsers
             |> Permissions.can(:view_project_credentials, editor, project)

      assert ProjectUsers
             |> Permissions.can(:view_project_collaborators, editor, project)

      refute ProjectUsers |> Permissions.can(:delete_project, editor, project)

      assert ProjectUsers
             |> Permissions.can(
               :edit_digest_alerts,
               editor,
               project.project_users |> Enum.at(1)
             )

      refute ProjectUsers
             |> Permissions.can(
               :edit_digest_alerts,
               editor,
               project.project_users |> Enum.at(0)
             )

      refute ProjectUsers |> Permissions.can(:edit_project_name, editor, project)

      refute ProjectUsers
             |> Permissions.can(:edit_project_description, editor, project)

      refute ProjectUsers
             |> Permissions.can(:add_project_collaborator, editor, project)

      viewer_project_user = project.project_users |> Enum.at(0)
      editor_project_user = project.project_users |> Enum.at(1)

      assert ProjectUsers
             |> Permissions.can(:edit_project_user, editor, editor_project_user)

      refute ProjectUsers
             |> Permissions.can(:edit_project_user, editor, viewer_project_user)
    end

    test "admin permissions", %{project: project, admin: admin} do
      assert ProjectUsers |> Permissions.can(:create_workflow, admin, project)
      assert ProjectUsers |> Permissions.can(:edit_job, admin, project)
      assert ProjectUsers |> Permissions.can(:create_job, admin, project)
      assert ProjectUsers |> Permissions.can(:delete_job, admin, project)
      assert ProjectUsers |> Permissions.can(:run_job, admin, project)
      assert ProjectUsers |> Permissions.can(:rerun_job, admin, project)

      assert ProjectUsers
             |> Permissions.can(:view_last_job_inputs, admin, project)

      assert ProjectUsers
             |> Permissions.can(:view_workorder_input, admin, project)

      assert ProjectUsers
             |> Permissions.can(:view_workorder_run, admin, project)

      assert ProjectUsers
             |> Permissions.can(:view_workorder_history, admin, project)

      assert ProjectUsers |> Permissions.can(:view_project_name, admin, project)

      assert ProjectUsers
             |> Permissions.can(:view_project_description, admin, project)

      assert ProjectUsers
             |> Permissions.can(:view_project_credentials, admin, project)

      assert ProjectUsers
             |> Permissions.can(:view_project_collaborators, admin, project)

      refute ProjectUsers |> Permissions.can(:delete_project, admin, project)

      assert ProjectUsers
             |> Permissions.can(
               :edit_digest_alerts,
               admin,
               project.project_users |> Enum.at(2)
             )

      refute ProjectUsers
             |> Permissions.can(
               :edit_digest_alerts,
               admin,
               project.project_users |> Enum.at(0)
             )

      assert ProjectUsers |> Permissions.can(:edit_project_name, admin, project)

      assert ProjectUsers
             |> Permissions.can(:edit_project_description, admin, project)

      assert ProjectUsers
             |> Permissions.can(:add_project_collaborator, admin, project)

      viewer_project_user = project.project_users |> Enum.at(0)
      admin_project_user = project.project_users |> Enum.at(2)

      assert ProjectUsers
             |> Permissions.can(:edit_project_user, admin, admin_project_user)

      refute ProjectUsers
             |> Permissions.can(:edit_project_user, admin, viewer_project_user)
    end

    test "owner permissions", %{project: project, owner: owner} do
      assert ProjectUsers |> Permissions.can(:create_workflow, owner, project)
      assert ProjectUsers |> Permissions.can(:edit_job, owner, project)
      assert ProjectUsers |> Permissions.can(:create_job, owner, project)
      assert ProjectUsers |> Permissions.can(:delete_job, owner, project)
      assert ProjectUsers |> Permissions.can(:run_job, owner, project)
      assert ProjectUsers |> Permissions.can(:rerun_job, owner, project)

      assert ProjectUsers
             |> Permissions.can(:view_last_job_inputs, owner, project)

      assert ProjectUsers
             |> Permissions.can(:view_workorder_input, owner, project)

      assert ProjectUsers
             |> Permissions.can(:view_workorder_run, owner, project)

      assert ProjectUsers
             |> Permissions.can(:view_workorder_history, owner, project)

      assert ProjectUsers |> Permissions.can(:view_project_name, owner, project)

      assert ProjectUsers
             |> Permissions.can(:view_project_description, owner, project)

      assert ProjectUsers
             |> Permissions.can(:view_project_credentials, owner, project)

      assert ProjectUsers
             |> Permissions.can(:view_project_collaborators, owner, project)

      assert ProjectUsers |> Permissions.can(:delete_project, owner, project)

      assert ProjectUsers
             |> Permissions.can(
               :edit_digest_alerts,
               owner,
               project.project_users |> Enum.at(3)
             )

      refute ProjectUsers
             |> Permissions.can(
               :edit_digest_alerts,
               owner,
               project.project_users |> Enum.at(0)
             )

      assert ProjectUsers |> Permissions.can(:edit_project_name, owner, project)

      assert ProjectUsers
             |> Permissions.can(:edit_project_description, owner, project)

      assert ProjectUsers
             |> Permissions.can(:add_project_collaborator, owner, project)

      viewer_project_user = project.project_users |> Enum.at(0)
      owner_project_user = project.project_users |> Enum.at(3)

      assert ProjectUsers
             |> Permissions.can(:edit_project_user, owner, owner_project_user)

      refute ProjectUsers
             |> Permissions.can(:edit_project_user, owner, viewer_project_user)
    end

    # For things like :view_job we should be able to show that people who do not
    # have access to a project cannot view the jobs in that project.
    test "thief permissions", %{project: project, thief: thief} do
      refute ProjectUsers |> Permissions.can(:create_workflow, thief, project)
      refute ProjectUsers |> Permissions.can(:create_job, thief, project)
      refute ProjectUsers |> Permissions.can(:delete_job, thief, project)
      refute ProjectUsers |> Permissions.can(:edit_job, thief, project)
      refute ProjectUsers |> Permissions.can(:run_job, thief, project)
      refute ProjectUsers |> Permissions.can(:rerun_job, thief, project)

      refute ProjectUsers
             |> Permissions.can(:view_last_job_inputs, thief, project)

      refute ProjectUsers
             |> Permissions.can(:view_workorder_input, thief, project)

      refute ProjectUsers
             |> Permissions.can(:view_workorder_run, thief, project)

      refute ProjectUsers
             |> Permissions.can(:view_workorder_history, thief, project)

      refute ProjectUsers |> Permissions.can(:view_project_name, thief, project)

      refute ProjectUsers
             |> Permissions.can(:view_project_description, thief, project)

      refute ProjectUsers
             |> Permissions.can(:view_project_credentials, thief, project)

      refute ProjectUsers
             |> Permissions.can(:view_project_collaborators, thief, project)

      refute ProjectUsers |> Permissions.can(:delete_project, thief, project)

      refute ProjectUsers
             |> Permissions.can(
               :edit_digest_alerts,
               thief,
               project.project_users |> Enum.at(3)
             )

      refute ProjectUsers
             |> Permissions.can(
               :edit_digest_alerts,
               thief,
               project.project_users |> Enum.at(0)
             )

      refute ProjectUsers |> Permissions.can(:edit_project_name, thief, project)

      refute ProjectUsers
             |> Permissions.can(:edit_project_description, thief, project)

      refute ProjectUsers
             |> Permissions.can(:add_project_collaborator, thief, project)
    end
  end
end

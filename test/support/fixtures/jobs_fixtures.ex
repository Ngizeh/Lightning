defmodule Lightning.JobsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lightning.Jobs` context.
  """

  import Lightning.ProjectsFixtures
  import Lightning.WorkflowsFixtures

  @doc """
  Generate a job.
  """
  @spec job_fixture(attrs :: Keyword.t()) :: Lightning.Jobs.Job.t()
  def job_fixture(attrs \\ []) when is_list(attrs) do
    attrs =
      attrs
      |> Keyword.put_new_lazy(:project_id, fn -> project_fixture().id end)

    attrs =
      attrs
      |> Keyword.put_new_lazy(:workflow_id, fn ->
        workflow_fixture(project_id: attrs[:project_id]).id
      end)

    {:ok, job} =
      attrs
      |> Enum.into(%{
        body: "fn(state => state)",
        enabled: true,
        name: "some name",
        adaptor: "@openfn/language-common",
        trigger: %{type: "webhook"}
      })
      |> Lightning.Jobs.create_job()

    job
  end

  def workflow_job_fixture(attrs \\ []) do
    workflow =
      Ecto.Changeset.cast(
        %Lightning.Workflows.Workflow{},
        %{
          "name" => attrs[:workflow_name],
          "project_id" => attrs[:project_id] || project_fixture().id,
          "id" => Ecto.UUID.generate()
        },
        [:project_id, :id, :name]
      )

    attrs =
      attrs
      |> Enum.into(%{
        body: "fn(state => state)",
        enabled: true,
        name: "some name",
        adaptor: "@openfn/language-common",
        trigger: %{type: "webhook"}
      })

    %Lightning.Jobs.Job{}
    |> Ecto.Changeset.change()
    |> Lightning.Jobs.Job.put_workflow(workflow)
    |> Lightning.Jobs.Job.changeset(attrs)
    |> Lightning.Repo.insert!()
  end

  def workflow_scenario() do
    project = project_fixture()
    workflow = workflow_fixture(project_id: project.id)

    #       +---+
    #   +---- A ----+
    #   |   +---+   |
    #   |           |
    #   |           |
    #   |           |
    # +-|-+       +-|-+
    # | B |       | E |
    # +-|-+       +-|-+
    #   |           |
    #   |           |
    # +-+-+       +-+-+
    # | C |       | F |
    # +-|-+       +-|-+
    #   |           |
    #   |           |
    # +-+-+       +-+-+
    # | D |       | G |
    # +---+       +---+
    #

    job_a =
      job_fixture(
        name: "job_a",
        workflow_id: workflow.id,
        trigger: %{type: :webhook}
      )

    job_b =
      job_fixture(
        name: "job_b",
        workflow_id: workflow.id,
        trigger: %{type: :on_job_success, upstream_job_id: job_a.id}
      )

    job_c =
      job_fixture(
        name: "job_c",
        workflow_id: workflow.id,
        trigger: %{type: :on_job_success, upstream_job_id: job_b.id}
      )

    job_d =
      job_fixture(
        name: "job_d",
        workflow_id: workflow.id,
        trigger: %{type: :on_job_success, upstream_job_id: job_c.id}
      )

    job_e =
      job_fixture(
        name: "job_e",
        workflow_id: workflow.id,
        trigger: %{type: :on_job_success, upstream_job_id: job_a.id}
      )

    job_f =
      job_fixture(
        name: "job_f",
        workflow_id: workflow.id,
        trigger: %{type: :on_job_success, upstream_job_id: job_e.id}
      )

    job_g =
      job_fixture(
        name: "job_g",
        workflow_id: workflow.id,
        trigger: %{type: :on_job_success, upstream_job_id: job_f.id}
      )

    %{
      workflow: workflow,
      project: project,
      jobs: %{
        a: job_a,
        b: job_b,
        c: job_c,
        d: job_d,
        e: job_e,
        f: job_f,
        g: job_g
      }
    }
  end
end

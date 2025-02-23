defmodule Lightning.Pipeline do
  @moduledoc """
  Service class to coordinate the running of jobs, and their downstream jobs.
  """
  use Oban.Worker,
    queue: :runs,
    priority: 1,
    max_attempts: 1

  require Logger

  alias Lightning.Pipeline.Runner

  alias Lightning.{Jobs, Invocation}
  alias Lightning.Invocation.Run
  alias Lightning.Repo
  alias Lightning.{AttemptService, AttemptRun}
  import Ecto.Query

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"attempt_run_id" => attempt_run_id}}) do
    Repo.get!(AttemptRun, attempt_run_id)
    |> process()
  end

  @spec process(AttemptRun.t()) :: :ok
  def process(%AttemptRun{} = attempt_run) do
    run = Ecto.assoc(attempt_run, :run) |> Repo.one!()
    result = Runner.start(run)

    jobs = get_jobs_for_result(run.job_id, result)

    if length(jobs) > 0 do
      next_dataclip_id = get_next_dataclip_id(result, run)

      jobs
      |> Enum.map(fn %{id: job_id, workflow: %{project_id: project_id}} ->
        # create a new run for the same attempt
        {:ok, attempt_run} =
          AttemptService.append(
            attempt_run,
            Run.changeset(%Run{}, %{
              job_id: job_id,
              input_dataclip_id: next_dataclip_id,
              project_id: project_id
            })
          )

        new(%{"attempt_run_id" => attempt_run.id})
      end)
      |> Enum.each(&Oban.insert/1)
    end

    :ok
  end

  defp result_to_trigger_type(%Lightning.Runtime.Result{exit_reason: reason}) do
    case reason do
      :error -> :on_job_failure
      :ok -> :on_job_success
      _ -> nil
    end
  end

  defp get_jobs_for_result(upstream_job_id, result) do
    Jobs.get_downstream_jobs_for(upstream_job_id, result_to_trigger_type(result))
    |> Enum.filter(& &1.enabled)
  end

  defp get_next_dataclip_id(result, run) do
    case result.exit_reason do
      :error ->
        run.input_dataclip_id

      :ok ->
        from(d in Invocation.Dataclip,
          join: r in assoc(d, :source_run),
          where: r.id == ^run.id,
          select: d.id
        )
        |> Repo.one()
    end
  end
end

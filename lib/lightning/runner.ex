defmodule Lightning.Runner do
  @moduledoc """
  Job running entrypoint
  """
  alias Lightning.Invocation.Run
  import Lightning.Invocation, only: [get_dataclip: 1]

  import Engine.Adaptor.Service, only: [install!: 2, resolve_package_name: 1, find_adaptor: 2]

  defmodule Handler do
    @moduledoc """
    Custom handler callbacks for Lightnings use of Engine to execute runs.
    """
    use Engine.Run.Handler
    import Lightning.Invocation, only: [update_run: 2]

    @impl true
    def on_start(run) do
      update_run(run, %{started_at: DateTime.utc_now()})
    end

    @impl true
    def on_finish(result, run) do
      update_run(run, %{
        finished_at: DateTime.utc_now(),
        exit_code: result.exit_code,
        log: result.log
      })
    end
  end

  @doc """
  Execute a Run.

  Given a valid run:
  - Persist the Dataclip and the Job's body to disk
  - Create a blank output file on disk
  - Build up a `%Engine.Runspec{}` with the paths, and adaptor module name

  And start it via `Handler.start/2`.

  The callbacks implemented on `Handler` (`c:Handler.on_start/1` and `c:Handler.on_finish/2`)
  update the run when a Run is started and when it's finished, attaching
  the `exit_code` and `log` when they are available.
  """
  @spec start(run :: Run.t(), opts :: []) :: :ok
  def start(%Run{} = run, opts \\ []) do
    run = Lightning.Repo.preload(run, :event)

    dataclip = Lightning.Invocation.get_dataclip_body(run)
    %{body: expression, adaptor: adaptor} = Lightning.Jobs.get_job!(run.event.job_id)

    %{local_name: local_name} = find_or_install_adaptor(adaptor)

    # turn run into RunSpec
    {:ok, state_path} =
      Temp.open(
        %{prefix: "state", suffix: ".json"},
        &IO.write(&1, dataclip)
      )

    {:ok, final_state_path} =
      Temp.open(
        %{prefix: "output", suffix: ".json"},
        &IO.write(&1, "")
      )

    {:ok, expression_path} =
      Temp.open(
        %{prefix: "expression", suffix: ".json"},
        &IO.write(&1, expression)
      )

    runspec = %Engine.RunSpec{
      adaptor: local_name,
      state_path: state_path,
      adaptors_path: "./priv/openfn/lib",
      final_state_path: final_state_path,
      expression_path: expression_path,
      env: %{
        "PATH" => "./priv/openfn/bin:#{System.get_env("PATH")}"
      },
      timeout: 60_000
    }

    Handler.start(runspec, Keyword.merge(opts, context: run))

    :ok
  end

  @doc """
  Make sure an adaptor matching the name is available.

  If it is available, return it's `Engine.Adaptor` struct - if not then
  install it.
  """
  @spec find_or_install_adaptor(adaptor :: String.t()) :: Engine.Adaptor.t()
  def find_or_install_adaptor(adaptor) when is_binary(adaptor) do
    package_spec = resolve_package_name(adaptor)
    adaptor = find_adaptor(:adaptor_service, package_spec)

    if is_nil(adaptor) do
      {:ok, adaptor} = install!(:adaptor_service, package_spec)
      adaptor
    else
      adaptor
    end
  end
end

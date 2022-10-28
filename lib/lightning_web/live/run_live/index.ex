defmodule LightningWeb.RunLive.Index do
  @moduledoc """
  Index Liveview for Runs
  """
  use LightningWeb, :live_view

  alias Lightning.Invocation
  alias Lightning.Invocation.Run
  import LightningWeb.RunLive.Components

  on_mount {LightningWeb.Hooks, :project_scope}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       active_menu_item: :runs,
       work_orders: [],
       pagination_path:
         &Routes.project_run_index_path(
           socket,
           :index,
           socket.assigns.project,
           &1
         )
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  # add a last_item key to
  defp lastify_map(%{} = obj, list_key) when is_atom(list_key) do
    Map.merge(obj, %{
      last_item: Enum.at(obj[list_key], 0)
    })
  end

  defp format_wo_list(wo_list) do
    Enum.map(wo_list, fn wo ->
      attempts = Map.get(wo, :attempts)

      formatted_attempts =
        Enum.map(attempts, fn att ->
          runs = Map.get(att, :runs)

          Map.merge(att, %{
            last_run: Enum.at(runs, 0)
          })
        end)

      Map.merge(wo, %{
        attempts: formatted_attempts,
        last_attempt: Enum.at(formatted_attempts, 0)
      })
    end)
  end

  defp apply_action(socket, :index, params) do
    socket
    |> assign(
      page_title: "Runs",
      run: %Run{},
      # page: Invocation.list_runs_for_project(socket.assigns.project, params)
      work_orders:
        Invocation.list_work_orders_for_project(socket.assigns.project, params)
        |> format_wo_list()
    )
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    socket
    |> assign(:page_title, "Run")
    |> assign(:run, Invocation.get_run_with_job!(id))
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    run = Invocation.get_run!(id)
    {:ok, _} = Invocation.delete_run(run)

    {:noreply,
     socket
     |> assign(
       work_orders: Invocation.list_runs_for_project(socket.assigns.project, %{})
     )}
  end

  def show_run(assigns) do
    ~H"""
    <.card>
      <.card_content
        heading={"Run #{@run.id}"}
        category={"Run exited with code #{@run.exit_code}"}
      >
        <.p>
          <b>Started:</b> <%= @run.started_at %>
        </.p>
        <.p>
          <b>Finished:</b> <%= @run.finished_at %>
        </.p>
        <.p>
          <b>Job:</b> <%= @run.job.name %>
        </.p>
        <br />
        <.p>
          <b>Logs</b>
        </.p>
        <div class="font-mono text-sm">
          <%= for line <- @run.log || [] do %>
            <li class="list-none">
              <%= raw(line |> String.replace(" ", "&nbsp;")) %>
            </li>
          <% end %>
        </div>
      </.card_content>
      <.card_footer>
        <.link
          navigate={Routes.project_run_index_path(@socket, :index, @project.id)}
          class="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-secondary-700 hover:bg-secondary-800 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-secondary-500"
        >
          Back
        </.link>
      </.card_footer>
    </.card>
    """
  end

  defp format_time(time) when is_nil(time) do
    ""
  end

  defp format_time(time) do
    time |> Timex.from_now(Timex.now(), "en")
  end

  def run_time(assigns) do
    run = assigns[:run]

    if run.finished_at do
      time_taken = Timex.diff(run.finished_at, run.started_at, :milliseconds)

      assigns =
        assigns
        |> assign(
          time_since: run.started_at |> format_time(),
          time_taken: time_taken
        )

      ~H"""
      <%= @time_since %> (<%= @time_taken %> ms)
      """
    else
      ~H"""

      """
    end
  end
end

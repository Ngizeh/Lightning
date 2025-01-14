defmodule LightningWeb.CredentialLive.Edit do
  @moduledoc """
  LiveView for editing a single Credential, which inturn uses
  `LightningWeb.CredentialLive.FormComponent` for common functionality.
  """
  use LightningWeb, :live_view

  alias Lightning.Credentials
  alias Lightning.Credentials.Credential
  alias Lightning.Projects
  alias Lightning.Policies.{Users, Permissions}

  @impl true
  def render(assigns) do
    ~H"""
    <LayoutComponents.page_content>
      <:header>
        <LayoutComponents.header socket={@socket}>
          <:title><%= @credential.name || @page_title %></:title>
        </LayoutComponents.header>
      </:header>
      <LayoutComponents.centered>
        <.live_component
          module={LightningWeb.CredentialLive.FormComponent}
          id={@credential.id || :new}
          title={@page_title}
          action={@live_action}
          credential={@credential}
          projects={@projects}
          return_to={Routes.credential_index_path(@socket, :index)}
        >
          <:button>
            <.link
              navigate={Routes.credential_index_path(@socket, :index)}
              class="inline-flex justify-center py-2 px-4 border border-transparent
                     shadow-sm text-sm font-medium rounded-md text-white
                     bg-secondary-700 hover:bg-secondary-800
                     focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-secondary-500"
            >
              Cancel
            </.link>
          </:button>

          <:button :let={valid?} class="text-right grow">
            <LightningWeb.Components.Form.submit_button
              phx-disable-with="Saving..."
              disabled={!valid?}
            >
              Save
            </LightningWeb.Components.Form.submit_button>
          </:button>
        </.live_component>
      </LayoutComponents.centered>
    </LayoutComponents.page_content>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    can_access_own_credentials =
      Users
      |> Permissions.can(
        :access_own_credentials,
        socket.assigns.current_user,
        socket.assigns.current_user
      )

    if can_access_own_credentials do
      {:ok, socket}
    else
      {:ok,
       put_flash(socket, :error, "You can't access that page")
       |> push_redirect(to: "/")}
    end
  end

  @doc """
  A generic handler for forwarding updates from PubSub
  """
  @impl true
  def handle_info({:forward, mod, opts}, socket) do
    send_update(mod, opts)
    {:noreply, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Credential")
    |> assign(
      credential:
        Credentials.get_credential!(id)
        |> Lightning.Repo.preload(:project_credentials),
      projects: list_projects(socket),
      users: list_users()
    )
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Credential")
    |> assign(
      credential: %Credential{user_id: socket.assigns.current_user.id},
      projects: list_projects(socket)
    )
  end

  defp apply_action(socket, :transfer_ownership, %{"id" => id}) do
    socket
    |> assign(:page_title, "Transfer Credential Ownership")
    |> assign(
      credential:
        Credentials.get_credential!(id)
        |> Lightning.Repo.preload(:project_credentials),
      projects: list_projects(socket)
    )
  end

  defp list_projects(socket) do
    Projects.get_projects_for_user(socket.assigns.current_user)
  end

  defp list_users() do
    Lightning.Accounts.list_users()
  end
end

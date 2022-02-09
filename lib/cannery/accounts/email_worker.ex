defmodule Cannery.EmailWorker do
  @moduledoc """
  Oban worker that dispatches emails
  """

  use Oban.Worker, queue: :mailers
  alias Cannery.Mailer

  @impl Oban.Worker
  def perform(%Oban.Job{args: email}) do
    email |> Mailer.deliver()
  end
end

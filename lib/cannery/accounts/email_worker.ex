defmodule Cannery.EmailWorker do
  use Oban.Worker, queue: :mailers
  alias Cannery.Mailer

  @impl Oban.Worker
  def perform(%Oban.Job{args: email}) do
    email |> Mailer.deliver()
  end
end

defmodule Cannery.Accounts.UserToken do
  @moduledoc """
  Schema for serialized user session and authentication tokens
  """

  use Ecto.Schema
  import Ecto.Query
  alias Ecto.{Query, UUID}
  alias Cannery.{Accounts.User, Accounts.UserToken}

  @hash_algorithm :sha256
  @rand_size 32

  # It is very important to keep the reset password token expiry short,
  # since someone with access to the email may take over the account.
  @reset_password_validity_in_days 1
  @confirm_validity_in_days 7
  @change_email_validity_in_days 7
  @session_validity_in_days 60

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users_tokens" do
    field :token, :binary
    field :context, :string
    field :sent_to, :string

    belongs_to :user, User

    timestamps(updated_at: false)
  end

  @type t :: %UserToken{
          id: id(),
          token: String.t(),
          context: String.t(),
          sent_to: String.t(),
          user: User.t(),
          user_id: User.id(),
          inserted_at: NaiveDateTime.t()
        }
  @type new_token :: %UserToken{}
  @type id :: UUID.t()

  @doc """
  Generates a token that will be stored in a signed place,
  such as session or cookie. As they are signed, those
  tokens do not need to be hashed.
  """
  @spec build_session_token(User.t()) :: {token :: String.t(), new_token()}
  def build_session_token(%{id: user_id}) do
    token = :crypto.strong_rand_bytes(@rand_size)
    {token, %UserToken{token: token, context: "session", user_id: user_id}}
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the user found by the token.
  """
  @spec verify_session_token_query(token :: String.t()) :: {:ok, Query.t()}
  def verify_session_token_query(token) do
    query =
      from token in token_and_context_query(token, "session"),
        join: user in assoc(token, :user),
        where: token.inserted_at > ago(@session_validity_in_days, "day"),
        select: user

    {:ok, query}
  end

  @doc """
  Builds a token with a hashed counter part.

  The non-hashed token is sent to the user email while the
  hashed part is stored in the database, to avoid reconstruction.
  The token is valid for a week as long as users don't change
  their email.
  """
  @spec build_email_token(User.t(), context :: String.t()) :: {token :: String.t(), new_token()}
  def build_email_token(user, context) do
    build_hashed_token(user, context, user.email)
  end

  @spec build_hashed_token(User.t(), String.t(), String.t()) ::
          {String.t(), new_token()}
  defp build_hashed_token(user, context, sent_to) do
    token = :crypto.strong_rand_bytes(@rand_size)
    hashed_token = :crypto.hash(@hash_algorithm, token)

    {Base.url_encode64(token, padding: false),
     %UserToken{
       token: hashed_token,
       context: context,
       sent_to: sent_to,
       user_id: user.id
     }}
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the user found by the token.
  """
  @spec verify_email_token_query(token :: String.t(), context :: String.t()) ::
          {:ok, Query.t()} | :error
  def verify_email_token_query(token, context) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)
        days = days_for_context(context)

        query =
          from token in token_and_context_query(hashed_token, context),
            join: user in assoc(token, :user),
            where: token.inserted_at > ago(^days, "day") and token.sent_to == user.email,
            select: user

        {:ok, query}

      :error ->
        :error
    end
  end

  @spec days_for_context(context :: <<_::56>>) :: non_neg_integer()
  defp days_for_context("confirm"), do: @confirm_validity_in_days
  defp days_for_context("reset_password"), do: @reset_password_validity_in_days

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the user token record.
  """
  @spec verify_change_email_token_query(token :: String.t(), context :: String.t()) ::
          {:ok, Query.t()} | :error
  def verify_change_email_token_query(token, context) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)

        query =
          from token in token_and_context_query(hashed_token, context),
            where: token.inserted_at > ago(@change_email_validity_in_days, "day")

        {:ok, query}

      :error ->
        :error
    end
  end

  @doc """
  Returns the given token with the given context.
  """
  @spec token_and_context_query(token :: String.t(), context :: String.t()) :: Query.t()
  def token_and_context_query(token, context) do
    from UserToken, where: [token: ^token, context: ^context]
  end

  @doc """
  Gets all tokens for the given user for the given contexts.
  """
  @spec user_and_contexts_query(User.t(), contexts :: :all | nonempty_maybe_improper_list()) ::
          Query.t()
  def user_and_contexts_query(%{id: user_id}, :all) do
    from t in UserToken, where: t.user_id == ^user_id
  end

  def user_and_contexts_query(%{id: user_id}, [_ | _] = contexts) do
    from t in UserToken, where: t.user_id == ^user_id and t.context in ^contexts
  end
end

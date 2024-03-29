defmodule Cannery.Accounts.User do
  @moduledoc """
  A Cannery user
  """

  use Ecto.Schema
  import Ecto.Changeset
  import CanneryWeb.Gettext
  alias Ecto.{Association, Changeset, UUID}
  alias Cannery.Accounts.{Invite, User}

  @derive {Jason.Encoder,
           only: [
             :id,
             :email,
             :confirmed_at,
             :role,
             :locale,
             :inserted_at,
             :updated_at
           ]}
  @derive {Inspect, except: [:password]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :email, :string
    field :password, :string, virtual: true
    field :hashed_password, :string
    field :confirmed_at, :naive_datetime
    field :role, Ecto.Enum, values: [:admin, :user], default: :user
    field :locale, :string

    has_many :created_invites, Invite, foreign_key: :created_by_id

    belongs_to :invite, Invite

    timestamps()
  end

  @type t :: %User{
          id: id(),
          email: String.t(),
          password: String.t(),
          hashed_password: String.t(),
          confirmed_at: NaiveDateTime.t(),
          role: role(),
          locale: String.t() | nil,
          created_invites: [Invite.t()] | Association.NotLoaded.t(),
          invite: Invite.t() | nil | Association.NotLoaded.t(),
          invite_id: Invite.id() | nil,
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }
  @type new_user :: %User{}
  @type id :: UUID.t()
  @type changeset :: Changeset.t(t() | new_user())
  @type role :: :admin | :user

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  @spec registration_changeset(attrs :: map(), Invite.t() | nil) :: changeset()
  @spec registration_changeset(attrs :: map(), Invite.t() | nil, opts :: keyword()) :: changeset()
  def registration_changeset(attrs, invite, opts \\ []) do
    %User{}
    |> cast(attrs, [:email, :password, :locale])
    |> put_change(:invite_id, if(invite, do: invite.id))
    |> validate_length(:locale, max: 255)
    |> validate_email()
    |> validate_password(opts)
  end

  @doc """
  A user changeset for role.
  """
  @spec role_changeset(t() | new_user() | changeset(), role()) :: changeset()
  def role_changeset(user, role) do
    user |> change(role: role)
  end

  @spec validate_email(changeset()) :: changeset()
  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/,
      message: dgettext("errors", "must have the @ sign and no spaces")
    )
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, Cannery.Repo)
    |> unique_constraint(:email)
  end

  @spec validate_password(changeset(), opts :: keyword()) ::
          changeset()
  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 80)
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  @spec maybe_hash_password(changeset(), opts :: keyword()) :: changeset()
  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  @spec email_changeset(t(), attrs :: map()) :: changeset()
  def email_changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> validate_email()
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, dgettext("errors", "did not change"))
    end
  end

  @doc """
  A user changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  @spec password_changeset(t(), attrs :: map()) :: changeset()
  @spec password_changeset(t(), attrs :: map(), opts :: keyword()) :: changeset()
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: dgettext("errors", "does not match password"))
    |> validate_password(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  @spec confirm_changeset(t() | changeset()) :: changeset()
  def confirm_changeset(user_or_changeset) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    user_or_changeset |> change(confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  @spec valid_password?(t(), String.t()) :: boolean()
  def valid_password?(%User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_invalid_user, _invalid_password) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  @spec validate_current_password(changeset(), String.t()) :: changeset()
  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password),
      do: changeset,
      else: changeset |> add_error(:current_password, dgettext("errors", "is not valid"))
  end

  @doc """
  A changeset for changing the user's locale
  """
  @spec locale_changeset(t() | changeset(), locale :: String.t() | nil) :: changeset()
  def locale_changeset(user_or_changeset, locale) do
    user_or_changeset
    |> cast(%{"locale" => locale}, [:locale])
    |> validate_length(:locale, max: 255)
    |> validate_required(:locale)
  end
end

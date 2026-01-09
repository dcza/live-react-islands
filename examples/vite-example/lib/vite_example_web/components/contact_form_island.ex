defmodule ViteExampleWeb.Components.ContactFormIsland do
  use LiveReactIslands.Component,
    component: "ContactForm",
    props: %{form: %{}}

  alias ViteExample.Contact

  def init(_assigns, socket) do
    changeset = Contact.changeset(%Contact{}, %{})

    socket
    |> assign(:changeset, changeset)
    |> init_form(:form, changeset)
  end

  def handle_form(:validate, :form, attrs, socket) do
    changeset =
      %Contact{}
      |> Contact.changeset(attrs)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> update_form(:form, changeset)}
  end

  def handle_form(:submit, :form, attrs, socket) do
    changeset =
      %Contact{}
      |> Contact.changeset(attrs)
      |> Map.put(:action, :validate)

    if changeset.valid? do
      # In a real app, you'd save to database here
      # For demo, we just reset the form
      new_changeset = Contact.changeset(%Contact{}, %{})

      {:noreply,
       socket
       |> assign(:changeset, new_changeset)
       |> assign(:submitted, true)
       |> init_form(:form, new_changeset)}
    else
      {:noreply,
       socket
       |> assign(:changeset, changeset)
       |> update_form(:form, changeset)}
    end
  end
end

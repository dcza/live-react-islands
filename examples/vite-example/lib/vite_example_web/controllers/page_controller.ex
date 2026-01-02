defmodule ViteExampleWeb.PageController do
  use ViteExampleWeb, :controller

  def index(conn, _params) do
    redirect(conn, to: "/navigation")
  end

  def ignore(conn, _params) do
    conn
    |> put_status(:not_found)
    |> json(%{error: "Not found"})
  end
end

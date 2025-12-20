defmodule ViteExampleWeb.PageController do
  use ViteExampleWeb, :controller

  def index(conn, _params) do
    redirect(conn, to: "/navigation")
  end
end

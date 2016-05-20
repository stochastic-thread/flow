defmodule Flow do
  use GenServer
  alias Flow.Listener

  def start_link do
    url =   "ws.pusherapp.com"
    path = "/app/de504dc5763aeef9ff52?client=js&version=3.0&protocol=5"
    Socket.Web.connect!(url, path: path)
  end

  defp get_socket_id(data) do
    data = JSX.decode!(data["data"])
    data["socket_id"]
  end

  defp create_payload(socket_id) do
    %{"socket_id" => socket_id,
      "channel" => "order_book"}
  end

  defp encode_payload(payload) do
    %{"data" => payload,
      "event" => "pusher:subscribe"}
      |> JSX.encode!
  end

  defp assemble_payload(data) do
      data
      |> JSX.decode!
      |> get_socket_id
      |> create_payload
      |> encode_payload
  end

  defp send_msg(msg, socket) do
    Socket.Web.send!(socket, {:text, msg})
  end

  def run(socket) do
    case Socket.Web.recv!(socket) do
      {:text, data} ->
        assemble_payload(data)
        |> send_msg(socket)
      {_idk, idk} -> IO.inspect idk
    end
    socket
  end

  def setup do
    socket =
      Flow.start_link
      |> Flow.run
    Flow.Listener.start_link(socket: socket)
  end

end

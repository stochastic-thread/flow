defmodule Flow do
  use GenServer
  alias Flow.Listener

  def start_link do
    url =   "ws.pusherapp.com"
    path = "/app/de504dc5763aeef9ff52?client=js&version=3.0&protocol=5"
    Socket.Web.connect!(url, path: path)
    #
    # Agent.start_link(fn() -> s end, name: __MODULE__)
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

  # def get_socket do
  #   Agent.get(__MODULE__, fn x -> x end)
  # end

  def run(socket) do
    case socket |> Socket.Web.recv! do
      {:text, data} ->
        assemble_payload(data)
        |> send_msg(socket)
        Flow.Listener.start_link(socket: socket)
    end

    # Agent.get(__MODULE__, fn socket ->
    #
    # end)
  end

  def setup do
    socket = Flow.start_link
    case Flow.run(socket) do
      :ok -> Flow.get_socket
      _ -> IO.puts "thinking..."
    end
  end

end

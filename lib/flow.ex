defmodule Flow do
  def start_link do
    url =   "ws.pusherapp.com"
    path = "/app/de504dc5763aeef9ff52?client=js&version=3.0&protocol=5"
    s = Socket.Web.connect!(url, path: path)
    Agent.start_link(fn() -> s end, name: __MODULE__)
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

  def get_socket do
    Agent.get(__MODULE__, fn x -> x end)
  end

  def run do
    Agent.get(__MODULE__, fn socket ->
      case socket |> Socket.Web.recv! do
        {:text, data} ->
          assemble_payload(data)
          |> send_msg(socket)
          start_loop(socket)
        {:ping, _ping} -> IO.puts "..."
      end
    end)
  end

  defp start_loop(s) do
    pid = spawn(fn -> loop(s) end)
  end

  defp loop(s) do
    case Socket.Web.recv!(s) do
      {:text, txt} ->
        IO.puts {Time.txt
        loop(s)
    end
  end

  def setup do
    Flow.start_link
    case Flow.run do
      :ok -> Flow.get_socket
      _ -> IO.puts "working"
    end
  end

end

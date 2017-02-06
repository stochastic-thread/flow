defmodule Flow do
  use GenServer
  alias Flow.Listener
  # import_config "config.exs"

  @doc """
    starts the Flow process
  """
  def init do
    Flow.start_link
    Agent.get(__MODULE__, fn map ->
      Flow.Listener.start_link(socket: Map.get(map, :socket))
    end)
  end

  def start_link do
    # move url + path to config file
    url =   Application.get_env(:flow, :service_url)
    path = Application.get_env(:flow, :path)

    # holds the Flow state, specifically a %Map{} with a single key, :socket
    Agent.start(fn ->
      Map.put(Map.new, :socket, Socket.Web.connect!(url, path: path))
    end, name: __MODULE__)

    # get the socket
    Agent.get(__MODULE__, fn state ->
      socket = Map.get(state, :socket)
      # receive initial subscription message
      response = Socket.Web.recv!(socket)
      IO.puts "Inspecting response..."
      IO.inspect response
      case response do
        {:text, response_payload} ->
          response_payload
          |> assemble_payload
          |> send_msg(socket)
      end
    end)
  end

  # returns socket_id, needed in order to send events
  defp get_socket_id(package) do
    package
    |> Map.get("data")
    |> JSX.decode!
    |> Map.get("socket_id")
  end

  defp create_payload(socket_id) do
    %{ "socket_id" => socket_id,
       "channel"   => "diff_order_book" }
  end

  defp encode_payload(payload) do
    %{ "data" => payload,
       "event" => "pusher:subscribe" }
    |> JSX.encode!
  end

  defp assemble_payload(package) do
      package
      |> JSX.decode!
      |> get_socket_id
      |> create_payload
      |> encode_payload
  end

  defp send_msg(msg, socket) do
    Socket.Web.send!(socket, {:text, msg})
  end
end

require IEx;

defmodule Flow.Listener do
  require Tirexs
  use GenServer

  def start_link(options) do
    {:ok, pid} = GenServer.start_link(__MODULE__, options[:socket], name: __MODULE__)
    # spawn(fn -> loop(opts[:socket]) end)
    pid
  end

  defp valid?(data) do
    # checking existence of "bids" and "asks" keys in Map
    data["bids"] && data["asks"]
  end

  def send(pid, {:send, msg}), do: GenServer.call(pid, {:send, msg, socket})
  def handle_call({:send, msg, socket}) do

  end

  def subscribe(pid, :subscribe), do: GenServer.call(pid, :subscribe)
  def handle_call(:subscribe) do
    url = Application.get_env(:flow, :service_url)
    path = Application.get_env(:flow, :path)
    socket = Socket.Web.connect!(url, path: path)

    # receive initial subscription message
    case Socket.Web.recv!( socket ) do
      {:text, response_payload} ->
        response_payload
        |> assemble_payload
        |> send_msg(socket)
    end

    {:reply, :subscribed, socket}
  end

  def listen(pid, {:listen, socket}), do: GenServer.cast(pid, {:listen, socket})
  def handle_cast({:listen, s}) do
    case Socket.Web.recv!(s) do
      {:text, txt} ->
        IO.inspect("Printing socket receive for (:text):\n#{txt}")
        decode_response(txt)
      {:ping, _ } ->
        Socket.Web.send!(s, {:pong, ""})
      {hey, idk} ->
        IO.puts("Printing socket receive for (:#{hey})")
        IO.puts "IDK????"
        IO.inspect idk
    end
  end

  defp convert(price, quantity) do
    {p, _} = Float.parse( price )
    {q, _} = Float.parse( quantity )
    [ p, q ]
  end

  defp get_and_convert(data, side) do
    type =
      case side do
        :bids -> "bids"
        :asks -> "asks"
      end
    Enum.map(data[type], fn( [p, q] ) -> convert(p, q) end)
  end

  defp store_data(data) do
    if valid?(data) do
      bids =  get_and_convert(data, :bids)
      asks =  get_and_convert(data, :asks)

      ts = Flow.Utilities.format_utc_timestamp( [newline?: false] )
      ts = String.replace(ts, " ", "");
      elastic_ip = Application.get_env(:flow, :elastic_ip)
      elastic_port = Application.get_env(:flow, :elastic_port)
      index_name = Application.get_env(:flow, :index_name)
      type_name = Application.get_env(:flow, :type_name)
      elastic_info = elastic_ip <> ":" <> elastic_port
      document_info = index_name <> "/" <> type_name <> "/" <> ts
      url = "http://" <> elastic_info <> "/" <> document_info
      logfile = Application.get_env(:flow, :log_name)
      File.open(logfile, [:append], fn(file) ->
        IO.write(file, ts <> "\n")
      end)
      package =
        %{ :bids => bids,
           :asks => asks }
      json = JSX.encode!(package)
      IO.puts("\n" <> url <> "\n")
      IO.inspect Tirexs.HTTP.post!(url, json)
      package
    end
  end

  defp decode_response(txt) do
    case JSX.decode(txt) do
      {:ok, data} ->
        IO.puts ":ok!"
        IO.inspect data
        IO.inspect "you got to decode_response/1"
        IO.inspect data

        data
        |> Map.get("data")
        |> JSX.decode!
        |> store_data
        |> IO.inspect
      {:error, idk} ->
        IO.puts "~~ERROR~~"
        IO.inspect( idk )
    end
  end
end

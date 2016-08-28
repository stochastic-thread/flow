require IEx;

defmodule Flow.Listener do
  require Tirexs

  def start_link(opts) do
    spawn(fn -> loop(opts[:socket]) end)
  end

  defp valid?(data) do
    # checking existence of "bids" and "asks" keys in Map
    data["bids"] && data["asks"]
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
      json = JSX.encode!(%{:bids => bids, :asks => asks})
      IO.puts("\n"<>url<>"\n")
      IO.inspect Tirexs.HTTP.post!(url, json)

      %{ :bids => bids,
         :asks => asks }
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

  defp loop(s) do
    IO.inspect("Printing socket")
    IO.inspect(s)
    case Socket.Web.recv!(s) do
      {:text, txt} ->
        IO.inspect("Printing socket receive for (:text):\n#{txt}")
        decode_response(txt)
        loop(s)
      {:ping, _ } ->
        s |> Socket.Web.send!({:pong, ""})
        loop(s)
      {hey, idk} ->
        IO.puts("Printing socket receive for (:#{hey})")
        IO.puts "IDK????"
        IO.inspect idk
    end
  end
end

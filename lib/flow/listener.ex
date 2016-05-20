require IEx;

defmodule Flow.Listener do
  require Tirexs
  def start_link(opts), do: spawn(fn -> loop(opts[:socket]) end)

  defp valid?(data) do
    (data["bids"] != nil) and (data["asks"] != nil)
  end

  defp convert(price, quantity) do
    [ String.to_float( price ), String.to_float( quantity ) ]
  end

  defp get_and_convert(data, side) do
    type =
      case side do
        :bids -> "bids"
        :asks -> "asks"
      end
    Enum.map(data[type], fn( [p, q] ) -> convert(p, q) end)
  end

  defp store_data(data, time) do
    if valid?(data) do
      bids =  get_and_convert(data, :bids)
      asks =  get_and_convert(data, :asks)
      url = "http://127.0.0.1:9200/bs/ob/"<>Integer.to_string(time)
      json = JSX.encode!(%{:bids => bids, :asks => asks})
      IO.puts("\n"<>url<>"\n")
      IO.inspect Tirexs.HTTP.post!(url, json)
      %{:bids => bids, :asks => asks}
    end
  end

  defp decode_response(txt) do
    IO.puts "HELP!\n"
    IO.inspect txt
    case JSX.decode(txt) do
      {:ok, data} ->
        IO.puts ":ok!"
        IO.inspect data
        IO.inspect "you got to decode_response/1"
        IO.inspect data
        data
        |> Map.get("data")
        |> JSX.decode!
        |> store_data(:os.system_time)
        |> IO.inspect
      {_else, idk} ->
        IO.puts "????"
        IO.puts(idk)
    end
  end

# # iex(103)>
# 00:28:06.792 [error] Process #PID<0.293.0> raised an exception
# ** (RuntimeError) protocol error
#     lib/socket/web.ex:707: Socket.Web.recv!/2
#     (flow) lib/flow/listener.ex:57: Flow.Listener.loop/1
#
# nil
  defp loop(s) do
    case Socket.Web.recv!(s) do # this is Flow.Listener.loop/1 lib/flow/listener.ex:57 per above error msg
      {:text, txt} ->
        decode_response(txt)
        loop(s)
      {:ping, _ } ->
          Flow.setup
      {_else, idk} -> IO.inspect idk
    end
  end
end

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
      File.open("log.txt", [:append], fn(file) -> 
        IO.write(file, Integer.to_string(time)<>"\n")
      end)
      json = JSX.encode!(%{:bids => bids, :asks => asks})
      IO.puts("\n"<>url<>"\n")
      IO.inspect Tirexs.HTTP.post!(url, json)
      %{:bids => bids, :asks => asks}
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
        |> store_data(:os.system_time)
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
        IO.inspect("Printing socket receive for (:text)")
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

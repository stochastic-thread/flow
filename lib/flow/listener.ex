require IEx;

defmodule Flow.Listener do
  def start_link(opts), do: spawn(fn -> loop(opts[:socket]) end)

  defp decode_response(txt) do
    case JSX.decode(txt) do
      {:ok, data} ->
        data
        |> Map.get("data")
        |> JSX.decode!
        |> IO.inspect
      {_else, idk} ->
        IO.puts(idk)
    end
  end

  defp loop(s) do
    case Socket.Web.recv!(s) do
      {:text, txt} ->
        decode_response(txt)
        loop(s)
      {:ping, _ } ->
          Flow.setup
    end
  end
end

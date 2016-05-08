defmodule Flow.Listener do
  def start_link(opts), do: spawn(fn -> loop(opts[:socket]) end)

  defp loop(s) do
    case Socket.Web.recv!(s) do
      {:text, txt} ->
        IO.puts "#{txt}"
        loop(s)
      {:ping, _ } ->
          Flow.setup
    end
  end
end

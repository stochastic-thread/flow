# Flow

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `flow` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:flow, "~> 0.0.1"}]
    end
    ```

  2. Ensure `flow` is started before your application:

    ```elixir
    def application do
      [applications: [:flow]]
    end
    ```



    00:15:28.726 [error] Process #PID<0.164.0> raised an exception
    ** (FunctionClauseError) no function clause matching in Tirexs.HTTP.ok!/1
        (tirexs) lib/tirexs/http.ex:319: Tirexs.HTTP.ok!(:error)
        (flow) lib/flow/listener.ex:45: Flow.Listener.store_data/1
        (flow) lib/flow/listener.ex:61: Flow.Listener.decode_response/1
        (flow) lib/flow/listener.ex:75: Flow.Listener.loop/1

    nil

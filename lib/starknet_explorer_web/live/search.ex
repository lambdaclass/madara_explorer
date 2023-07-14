defmodule StarknetExplorerWeb.SearchLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorer.Rpc

  def render(assigns) do
    ~H"""
    <form phx-change="update-input" phx-submit="search">
      <.input
        phx-change="update-input"
        type="text"
        name="search-input"
        value={@query}
        placeholder="Search Blocks, Transactions, Classes, Messages, Contracts or Events"
      />
      <button class="absolute top-1/2 right-2 transform -translate-y-1/2" type="submit">
        <img src={~p"/images/search.svg"} />
      </button>
    </form>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, query: "", loading: false, matches: [], errors: [])}
  end

  def handle_event("update-input", %{"search-input" => query}, socket) do
    {:noreply, assign(socket, :query, query)}
  end

  def handle_event("search", %{"search-input" => query}, socket) when byte_size(query) <= 100 do
    send(self(), {:search, query})
    {:noreply, assign(socket, query: query, result: "Searching...", loading: true, matches: [])}
  end

  def handle_info({:search, query}, socket) do
    query = String.trim(query)

    navigate_fun =
      case try_search(query) do
        {:tx, _tx} ->
          fn -> push_navigate(socket, to: ~p"/transactions/#{query}") end

        {:block, _block} ->
          fn -> push_navigate(socket, to: ~p"/block/#{query}") end

        :noquery ->
          fn ->
            socket
            |> put_flash(:error, "No results found")
            |> push_navigate(to: "/")
          end
      end

    {:noreply, navigate_fun.()}
  end

  defp try_search(query) do
    case infer_query(query) do
      :hex -> try_by_hash(query)
      {:number, number} -> try_by_number(number)
      :noquery -> :noquery
    end
  end

  def try_by_number(number) do
    case Rpc.get_block_by_number(number) do
      {:ok, _block} -> {:block, number}
      {:error, :not_found} -> :noquery
    end
  end

  def try_by_hash(hash) do
    case Rpc.get_transaction(hash) do
      {:ok, _transaction} ->
        {:tx, hash}

      {:error, _} ->
        case Rpc.get_block_by_hash(hash) do
          {:ok, block} -> {:block, block}
          {:error, _} -> :noquery
        end
    end
  end

  defp infer_query(_query = <<"0x", _rest::binary>>), do: :hex

  defp infer_query(query) do
    case Integer.parse(query) do
      {parsed, ""} -> {:number, parsed}
      _ -> :noquery
    end
  end
end

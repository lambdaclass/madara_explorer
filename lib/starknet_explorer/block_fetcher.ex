defmodule StarknetExplorer.BlockFetcher do
  use GenServer
  require Logger
  alias StarknetExplorer.{Rpc, BlockFetcher, Block}
  defstruct [:block_height, :latest_block_fetched]
  @fetch_interval 300
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl true
  def init(_opts) do
    state = %BlockFetcher{
      # The actual chain block-height
      block_height: fetch_block_height(),
      # Highest block number stored on the DB
      latest_block_fetched: StarknetExplorer.Block.highest_fetched_block_number()
    }

    Process.send_after(self(), :fetch_and_store, @fetch_interval)
    {:ok, state}
  end

  @impl true
  def handle_info(:fetch_and_store, state = %BlockFetcher{}) do
    # Try to fetch the new height, else keep the current one.
    curr_height =
      case fetch_block_height() do
        height when is_integer(height) -> height
        _ -> state.block_height
      end

    # If the db is 10 blocks behind,
    # fetch a new block, else do nothing.
    if curr_height + 10 >= state.latest_block_fetched do
      case fetch_block(state.latest_block_fetched + 1) do
        {:ok, block = %{"block_number" => new_block_number, "transactions" => transactions}} ->
          receipts =
            transactions
            |> Map.new(fn %{"transaction_hash" => tx_hash} ->
              {:ok, receipt} = Rpc.get_transaction_receipt(tx_hash)
              {tx_hash, receipt}
            end)

          :ok = Block.insert_from_rpc_response(block, receipts)
          Logger.info("Inserted new block: #{new_block_number}")
          Process.send_after(self(), :fetch_and_store, @fetch_interval)
          {:noreply, %{state | block_height: curr_height, latest_block_fetched: new_block_number}}

        :error ->
          {:noreply, state}
      end
    end
  end

  @impl true
  def handle_info(:stop, _) do
    Logger.info("Stopping BlockFetcher")
    {:stop, :normal, :ok}
  end

  defp fetch_block_height() do
    case Rpc.get_block_height() do
      {:ok, height} ->
        height

      {:error, _} ->
        Logger.error("[#{DateTime.utc_now()}] Could not update block height from RPC module")
    end
  end

  defp fetch_block(number) when is_integer(number) do
    case Rpc.get_block_by_number(number) do
      {:ok, block} ->
        {:ok, block}

      {:error, _} ->
        Logger.error("Could not fetch block #{number} from RPC module")
        :error
    end
  end
end

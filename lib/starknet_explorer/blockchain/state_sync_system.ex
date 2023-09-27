defmodule StarknetExplorer.Blockchain.StateSyncSystem do
  @moduledoc """
  State Sync System.
  """
  alias StarknetExplorer.{Block, BlockUtils, Rpc, Blockchain.StateSyncSystem, Counts}
  defstruct [:current_block_number, :network, :next_to_fetch, :updater_block_number]
  use GenServer
  require Logger
  @fetch_timer :timer.seconds(5)

  def start_link([network: _network, name: name] = arg) do
    GenServer.start_link(__MODULE__, arg, name: name)
  end

  ## Callbacks
  @impl true
  def init([network: network, name: _name] = _args) do
    {:ok, block_height} = BlockUtils.block_height(network)
    {:ok, lowest_block_number} = BlockUtils.get_lowest_block_number(network)

    {:ok, lowest_not_finished_block_number} =
      BlockUtils.get_lowest_not_completed_block(network)

    state = %StateSyncSystem{
      current_block_number: block_height,
      next_to_fetch: lowest_block_number,
      updater_block_number: lowest_not_finished_block_number,
      network: network
    }

    Process.send_after(self(), :listener, @fetch_timer)
    Process.send_after(self(), :fetcher, @fetch_timer)
    Process.send_after(self(), :updater, @fetch_timer)
    Logger.info("State Sync System enabled for network #{network}.")
    {:ok, state}
  end

  @impl true
  def handle_info(
        :updater,
        state = %StateSyncSystem{network: network, updater_block_number: nil}
      ) do
    {:ok, lowest_not_completed_block} = Block.get_lowest_not_completed_block(network)
    state = %{state | updater_block_number: lowest_not_completed_block}

    Process.send_after(self(), :updater, @fetch_timer)
    {:noreply, state}
  end

  @impl true
  def handle_info(
        :updater,
        state = %StateSyncSystem{network: network, updater_block_number: updater_block_number}
      ) do
    {:ok, _} = BlockUtils.fetch_and_update(updater_block_number, network)
    {:ok, lowest_not_completed_block} = BlockUtils.get_lowest_not_completed_block(network)

    state = %{
      state
      | updater_block_number: lowest_not_completed_block
    }

    Process.send_after(self(), :updater, @fetch_timer)
    {:noreply, state}
  end

  @impl true
  def handle_info(
        :listener,
        state = %StateSyncSystem{network: network, current_block_number: current_block_number}
      ) do
    {:ok, new_block_height} = Rpc.get_block_height_no_cache(network)
    new_blocks? = new_block_height > current_block_number

    state =
      try_fetch(new_blocks?, state)

    Process.send_after(self(), :listener, @fetch_timer)
    {:noreply, state}
  end

  @impl true
  def handle_info(
        :fetcher,
        state = %StateSyncSystem{network: network, next_to_fetch: next_to_fetch}
      ) do
    {:ok, _} = BlockUtils.fetch_and_store(next_to_fetch, network)
    state = %{state | next_to_fetch: next_to_fetch - 1}

    Counts.insert_or_update(network)

    maybe_fetch_another(state)

    {:noreply, state}
  end

  defp try_fetch(true, state = %StateSyncSystem{network: network}) do
    next_to_fetch = state.current_block_number + 1

    {:ok, _} = BlockUtils.fetch_and_store(next_to_fetch, network)

    Counts.insert_or_update(network)

    %{state | current_block_number: next_to_fetch}
  end

  defp try_fetch(_new_blocks?, state), do: state

  # This means that we are fully syncd.
  defp maybe_fetch_another(%StateSyncSystem{next_to_fetch: -1} = _args), do: :ok

  defp maybe_fetch_another(_),
    do: Process.send_after(self(), :fetcher, @fetch_timer)
end

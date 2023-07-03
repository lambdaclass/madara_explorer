defmodule StarknetExplorerWeb.Utils do
  alias StarknetExplorer.Rpc
  alias StarknetExplorer.DateUtils

  def shorten_block_hash(block_hash) do
    "#{String.slice(block_hash, 0, 6)}...#{String.slice(block_hash, -4, 4)}"
  end

  def get_latest_block_with_transactions() do
    {:ok, block} = Rpc.get_block_by_number(get_latest_block_number())
    [block]
  end

  def get_latest_block_number() do
    {:ok, latest_block} = Rpc.get_latest_block()
    latest_block["block_number"]
  end

  def list_blocks() do
    Enum.reverse(list_blocks(get_latest_block_number(), 15, []))
  end

  def list_blocks(_block_number, 0, acc) do
    acc
  end

  def list_blocks(block_number, remaining, acc) do
    {:ok, block} = Rpc.get_block_by_number(block_number)
    prev_block_number = block_number - 1
    list_blocks(prev_block_number, remaining - 1, [block | acc])
  end

  def get_block_age(block) do
    %{minutes: minutes, hours: hours, days: days} =
      DateUtils.calculate_time_difference(block["timestamp"])

    case days do
      0 ->
        case hours do
          0 -> "#{minutes} min"
          _ -> "#{hours} h"
        end

      _ ->
        "#{days} d"
    end
  end
end

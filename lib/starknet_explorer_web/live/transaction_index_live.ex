defmodule StarknetExplorerWeb.TransactionIndexLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.Utils

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto">
      <div class="table-header">
        <h2>Transactions</h2>
      </div>
      <div class="table-block">
        <div class="transactions-grid table-th">
          <div class="col-span-2" scope="col">Transaction Hash</div>
          <div class="col-span-2" scope="col">Type</div>
          <div class="col-span-2" scope="col">Status</div>
          <div scope="col">Age</div>
        </div>
        <div id="transactions">
          <%= for block <- @latest_block do %>
            <%= for {transaction, idx} <- Enum.with_index(block["transactions"]) do %>
              <div
                id={"transaction-#{idx}"}
                class="transactions-grid border-t first-of-type:border-t-0 md:first-of-type:border-t border-gray-600"
              >
                <div class="col-span-2" scope="row">
                  <div class="list-h">Transaction Hash</div>
                  <%= live_redirect(Utils.shorten_block_hash(transaction["transaction_hash"]),
                    to: "/transactions/#{transaction["transaction_hash"]}",
                    class: "text-se-blue hover:text-se-hover-blue underline-none"
                  ) %>
                </div>
                <div class="col-span-2" scope="row">
                  <div class="list-h">Type</div>
                  <%= transaction["type"] %>
                </div>
                <div class="col-span-2" scope="row">
                  <div class="list-h">Status</div>
                  <%= block["status"] %>
                </div>
                <div scope="row">
                  <div class="list-h">Age</div>
                  <%= Utils.get_block_age(block) %>
                </div>
              </div>
            <% end %>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    Process.send(self(), :load_blocks, [])

    {:ok,
     assign(socket,
       blocks: [],
       latest_block: []
     )}
  end

  @impl true
  def handle_info(:load_blocks, socket) do
    {:noreply,
     assign(socket,
       blocks: Utils.list_blocks(),
       latest_block: Utils.get_latest_block_with_transactions()
     )}
  end
end

defmodule StarknetExplorerWeb.TransactionIndexLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.CoreComponents
  alias StarknetExplorerWeb.Utils
  alias StarknetExplorer.Data
  alias StarknetExplorer.Transaction

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto">
      <div class="table-header">
        <h2>Transactions</h2>
        <CoreComponents.pagination_links id="transactions" page={@page} prev="dec_txs" next="inc_txs" />
      </div>
      <div class="table-block">
        <div class="grid-7 table-th">
          <div class="col-span-2">Transaction Hash</div>
          <div class="col-span-2">Type</div>
          <div class="col-span-2">Status</div>
          <div>Age</div>
        </div>
        <div id="transactions">
          <%= for {transaction, idx} <- Enum.with_index(@page.entries) do %>
            <div id={"transaction-#{idx}"} class="grid-7 custom-list-item">
              <div class="col-span-2">
                <div class="list-h">Transaction Hash</div>
                <div class="block-data">
                  <div class="hash flex">
                    <a
                      href={
                        Utils.network_path(
                          @network,
                          "transactions/#{transaction.hash}"
                        )
                      }
                      class="text-hover-link"
                    >
                      <%= Utils.shorten_block_hash(transaction.hash) %>
                    </a>
                    <CoreComponents.copy_button text={transaction.hash} />
                  </div>
                </div>
              </div>
              <div class="col-span-2">
                <div class="list-h">Type</div>
                <div>
                  <span class={"type #{String.downcase(transaction.type)}"}>
                    <%= transaction.type %>
                  </span>
                </div>
              </div>
              <div class="col-span-2">
                <div class="list-h">Status</div>
                <div>
                  <span class={"info-label #{String.downcase(transaction.status)}"}>
                    <%= transaction.status %>
                  </span>
                </div>
              </div>
              <div>
                <div class="list-h">Age</div>
                <%= Utils.get_block_age_from_timestamp(transaction.timestamp) %>
              </div>
            </div>
          <% end %>
        </div>
      </div>
      <div class="mt-2">
        <CoreComponents.pagination_links id="events" page={@page} prev="dec_txs" next="inc_txs" />
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    page = Transaction.paginate_transactions_for_index(%{}, socket.assigns.network)

    {:ok,
     assign(socket,
       page: page
     )}
  end

  @impl true
  def handle_info(:load_blocks, socket) do
    {:noreply,
     assign(socket,
       latest_block: Data.latest_block_with_transactions(socket.assigns.network)
     )}
  end

  @impl true
  def handle_event("inc_txs", _value, socket) do
    new_page_number = socket.assigns.page.page_number + 1
    pagination(socket, new_page_number)
  end

  def handle_event("dec_txs", _value, socket) do
    new_page_number = socket.assigns.page.page_number - 1
    pagination(socket, new_page_number)
  end

  @impl true
  def handle_event(
        "change-page",
        %{"page-number-input" => page_number},
        socket
      ) do
    new_page_number = String.to_integer(page_number)
    pagination(socket, new_page_number)
  end

  def pagination(socket, new_page_number) do
    page =
      Transaction.paginate_transactions_for_index(
        %{page: new_page_number},
        socket.assigns.network
      )

    {:noreply, assign(socket, page: page)}
  end
end

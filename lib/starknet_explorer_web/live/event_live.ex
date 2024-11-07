defmodule StarknetExplorerWeb.EventDetailLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.CoreComponents
  alias StarknetExplorer.{Events, Block}
  alias StarknetExplorerWeb.Utils
  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto bg-container p-4 md:p-6 rounded-md">
      <div class="flex flex-col md:flex-row justify-between mb-5 lg:mb-0">
        <h2>Event</h2>
        <div class="font-normal text-gray-400 mt-2 lg:mt-0">
          <%= @block.timestamp
          |> DateTime.from_unix()
          |> then(fn {:ok, time} -> time end)
          |> Calendar.strftime("%c") %> UTC
        </div>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Event ID</div>
        <div class="block-data">
          <div class="hash flex">
            <%= @event.id %>
            <CoreComponents.copy_button text={@event.id} />
          </div>
        </div>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Block Hash</div>
        <div class="block-data">
          <div class="hash flex">
            <a
              href={
                Utils.network_path(
                  @network,
                  "blocks/#{@block.hash}"
                )
              }
              class="text-hover-link break-all"
            >
              <span><%= @block.hash %></span>
            </a>
            <CoreComponents.copy_button text={@block.hash} />
          </div>
        </div>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Block Number</div>
        <a
          href={
            Utils.network_path(
              @network,
              "blocks/#{@event.block_number}"
            )
          }
          class="w-fit type"
        >
          <div><%= @event.block_number %></div>
        </a>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Transaction Hash</div>
        <div class="block-data">
          <div class="hash flex">
            <a
              href={
                Utils.network_path(
                  @network,
                  "transactions/#{@event.transaction_hash}"
                )
              }
              class="text-hover-link break-all"
            >
              <%= @event.transaction_hash %>
            </a>
            <CoreComponents.copy_button text={@event.transaction_hash} />
          </div>
        </div>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Contract Address</div>
        <div class="block-data">
          <div class="hash flex">
            <a
              href={Utils.network_path(@network, "contracts/#{@event.from_address}")}
              class="text-hover-link"
            >
              <%= @event.from_address %>
            </a>
            <CoreComponents.copy_button text={@event.from_address} />
          </div>
        </div>
      </div>
      <div class="custom-list-item">
        <div class="block-label !mt-0 lg:pb-5">Event Data</div>
        <div class="bg-black/10 p-5">
          <div class="grid-3 w-full table-th">
            <div>Input</div>
            <div>Value</div>
          </div>
          <%= for {payload, index} <- Enum.with_index(@event.data) do %>
            <div class="grid-3 w-full custom-list-item">
              <div>
                <div class="list-h">Index</div>
                <div><%= index %></div>
              </div>
              <div>
                <div class="list-h">Value</div>
                <div class="block-data">
                  <div class="hash flex">
                    <%= payload %>
                    <CoreComponents.copy_button text={payload} />
                  </div>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params = %{"identifier" => identifier}, _session, socket) do
    event = Events.get_by_id(identifier, socket.assigns.network)

    assigns = [
      event: event,
      block: Block.get_by_num(event.block_number, socket.assigns.network)
    ]

    {:ok, assign(socket, assigns)}
  end
end

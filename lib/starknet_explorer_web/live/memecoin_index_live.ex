defmodule StarknetExplorerWeb.MemecoinIndexLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.CoreComponents
  alias StarknetExplorerWeb.Utils

  # {symbol, name, address, pool_address}
  @meme_coins [
    {"STRAK", "STRAK", "0x55c3868c743e92c470701799388cb3fb1d922dcec271150d10462c6948e3cf4",
     "0x38c02022ec31c3a523870a9130bb5d4c50ca7021f8d0b0e333554908b9ce8df"},
    {"Tony", "Tony", "0x6e93bee3b8fe29713292a0d137af8d1ba0f0751573a6663f84c4c620ee5c66c",
     "0x12aeaf068f07d7c590e45229e2b270129b5cade8cef8213f1d1da8bd9467c5b"},
    {"cro", "BabyCario", "0x4ee423b1f89f1ac011d6f2f05c1eb35d61594b801122771cce7747718aa416f",
     "0x7102f945472a1298c851d73f961a017b2a09f08af649036015476231a3fd701"},
    {"SONIC", "Sonic on Starknet",
     "0xaeb19c543d233bfd4abdf99c74bda39ca32a5c8b428744adcbb4b519ec5c81",
     "0x12eb684d2b18071ea8e001279b0d5aeffef945f760d4b9918bf4f48726c3dd4"},
    {"PEPE", "Pepestark.net", "0x5ae8ef41fe47d392c235aff1175feceb28c1430f80bf9515dca979402c13063",
     "0x1470ee377df73ef93417d97711cf42f5019941c8702e2f9e3df14e31286b021"}
  ]
  def mount(_params, _session, socket) do
    {:ok, assign(socket, meme_coins: @meme_coins)}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto">
      <div class="table-header">
        <h2>Memecoins</h2>
      </div>
      <div class="table-block">
        <div class="grid-6 table-th">
          <div>Symbol</div>
          <div>Name</div>
          <div class="col-span-2">Address</div>
          <div class="col-span-2">Pool Address</div>
        </div>
        <%= for {symbol, name, address, pool_address} <- @meme_coins do %>
          <div class="custom-list-item grid-6">
            <div>
              <div class="list-h">Symbol</div>
              <div>
              <span class="type">
                <%= symbol %>
              </span>
              </div>
            </div>
            <div>
              <div class="list-h">Name</div>
              <div>
                <%= name %>
              </div>
            </div>
            <div class="col-span-2">
              <div class="list-h">Address</div>
              <div class="block-data">
                <div class="hash flex">
                  <a
                    href={Utils.network_path(@network, "contracts/#{address}")}
                    class="text-hover-link"
                  >
                    <%= address |> Utils.shorten_block_hash() %>
                  </a>
                  <CoreComponents.copy_button text={address} />
                </div>
              </div>
            </div>
            <div class="col-span-2">
              <div class="list-h">Pool Address</div>
              <div class="block-data">
                <div class="hash flex">
                  <a
                    href={Utils.network_path(@network, "contracts/#{pool_address}")}
                    class="text-hover-link"
                  >
                    <%= pool_address |> Utils.shorten_block_hash() %>
                  </a>
                  <CoreComponents.copy_button text={pool_address} />
                </div>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end

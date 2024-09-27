window.App.Inventory.url = => "/manage/#{App.InventoryPool.current.id}/inventory"

window.App.Inventory.findByInventoryCode = (inventory_code) =>
  params = { inventory_code: inventory_code }
  $.get "/manage/#{App.InventoryPool.current.id}/inventory/find?#{$.param params}"

window.App.Inventory.fetch = (params) => $.get App.Inventory.url() + ".json", params

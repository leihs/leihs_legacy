## Global

window.App.Contract.url = => "#{App.InventoryPool.url}/#{App.InventoryPool.current.id}/contracts"

## Prototype

window.App.Contract.create = (data)-> $.post "#{App.InventoryPool.url}/#{App.InventoryPool.current.id}/contracts", data

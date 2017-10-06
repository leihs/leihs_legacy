## Global

window.App.Order.url = => "#{App.InventoryPool.url}/#{App.InventoryPool.current.id}/orders"

## Prototype

window.App.Order::approve = (comment)-> $.post "/manage/#{App.InventoryPool.current.id}/orders/#{@id}/approve", {comment: comment}

window.App.Order::approve_anyway = (comment)-> $.post "/manage/#{App.InventoryPool.current.id}/orders/#{@id}/approve", {force: true, comment: comment}

window.App.Order::reject = (comment)-> $.post "/manage/#{App.InventoryPool.current.id}/orders/#{@id}/reject", {comment: comment}

window.App.Order::swapUser = (user_id, delegated_user_id)-> $.post "/manage/#{App.InventoryPool.current.id}/orders/#{@id}/swap_user", {user_id: user_id, delegated_user_id: delegated_user_id}

window.App.Order::sign = (data)-> $.post "#{App.InventoryPool.url}/#{App.InventoryPool.current.id}/orders/#{@id}/sign", data

window.App.Order::editPath = -> "#{App.Order.url()}/#{@id}/edit"

window.App.Order::handOverPath = -> "#{App.Order.url()}/#{@id}/hand_over"

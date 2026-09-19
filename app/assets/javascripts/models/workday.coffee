###
  
  Workday

###

class window.App.Workday extends Spine.Model

  @configure "Workday"
  
  @belongsTo "inventory_pool", "App.InventoryPool", "inventory_pool_id"

  @extend Spine.Model.Ajax

  closedDays: =>
    days = []
    days.push 0 unless @sunday
    days.push 1 unless @monday
    days.push 2 unless @tuesday
    days.push 3 unless @wednesday
    days.push 4 unless @thursday
    days.push 5 unless @friday
    days.push 6 unless @saturday
    days

  # mirrors Workday#orders_processing_day? (Ruby)
  ordersProcessingDay: (date)=>
    switch date.day()
      when 1 then @monday_orders_processing
      when 2 then @tuesday_orders_processing
      when 3 then @wednesday_orders_processing
      when 4 then @thursday_orders_processing
      when 5 then @friday_orders_processing
      when 6 then @saturday_orders_processing
      when 0 then @sunday_orders_processing
      else false
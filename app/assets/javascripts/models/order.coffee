class window.App.Order extends Spine.Model

  @configure "Order", "id", "user_id", "inventory_pool_id", "state", "purpose", "delegated_user_id", "to_be_verified?"

  @extend Spine.Model.Ajax
  @extend App.Modules.FindOrBuild
  @include App.Modules.HasLines

  @belongsTo "user", "App.User", "user_id"
  @belongsTo "delegatedUser", "App.User", "delegated_user_id"
  @hasMany "reservations", "App.Reservation", "order_id"

  @url: => "/orders"

  to_be_verified: => this['to_be_verified?'] # hack around coffeescript's existantial operator

  isAvailable: => _.all @.reservations().all(), (line) -> line["available?"]

  quantity: =>
    _.reduce @.reservations().all(), ((mem, line) -> mem + line["quantity"]), 0

  concatenatedPurposes: => @purpose

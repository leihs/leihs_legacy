###

  Category

###

class window.App.Category extends Spine.Model

  @configure "Category", "id", "name", "used?"

  @extend Spine.Model.Ajax
  @extend App.Modules.FindOrBuild

  @hasMany "plinks", "App.CategoryLink", "child_id"
  @hasMany "clinks", "App.CategoryLink", "parent_id"
  @hasMany "models", "App.ModelLink", "model_id"

  @url: => "/categories"

  is_used: => this['used?'] # hack around coffeescript's existantial operator

  children: =>
    # filter out undefined records, they are coming from the inconsistent database: in some cases model group links reference not existing records!!!
    _.filter _.map(@clinks().all(), (l) -> l.child()), (c) -> c?

  parents: =>
    # filter out undefined records, they are coming from the inconsistent database: in some cases model group links reference not existing records!!!
    _filter _.map(@plinks().all(), (l) -> l.parent()), (c) -> c?

  @roots: =>
    _.filter App.Category.all(), (c)->
      not _.any c.plinks().all(), (l)-> l.parent_id?

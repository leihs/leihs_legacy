###

  CategoryLink

###

class window.App.CategoryLink extends Spine.Model

  @configure "CategoryLink", "id", "parent_id", "child_id"

  @extend Spine.Model.Ajax

  @belongsTo "parent", "App.Category", "parent_id"
  @belongsTo "child", "App.Category", "child_id"

  @url: => "/category_links"

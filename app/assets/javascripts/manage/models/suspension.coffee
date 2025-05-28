class window.App.Suspension extends Spine.Model

  @configure "Suspension", "id", "suspended_until", "suspended_reason"

  @extend Spine.Model.Ajax

  @url: => "/manage/#{App.InventoryPool.current.id}/suspensions"

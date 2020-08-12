# NOTE: this is only for editing reservation-(line-)specific purposes, not ones set on Orders.

class window.App.HandOversEditPurposeController extends Spine.Controller

  elements:
    "textarea": "textarea"
    "#errors": "errorsContainer"

  events:
    "submit form": "submit"

  constructor: (data) ->
    @reservations = data.reservations
    currentReservationPurps = _.uniq(data.reservations.map((r) => r.line_purpose).filter(Boolean).map((s) => _.string.clean(s)))
    initialPurpose = currentReservationPurps.join('; ') or ''
    @modal = new App.Modal(
      App.Render "manage/views/hand_overs/purpose_modal", {description: initialPurpose})
    @el = @modal.el
    super

  delegateEvents: =>
    super

  submit: (e)->
    e.preventDefault()

    newPurpose = _.string.clean(@textarea.val())
    _.each(@reservations, (r) => r.updateAttributes("line_purpose": newPurpose))

    @errorsContainer.addClass "hidden"
    $.ajax
      url: "/manage/#{App.InventoryPool.current.id}/reservations/edit_purpose"
      type: "POST"
      data: {
        line_ids: _.map(@reservations, (r) => r.id),
        purpose: newPurpose
      }
      success: (data) =>
        App.Reservation.trigger "refresh"
        @modal.destroy true
        @callback?()
      error: (e) =>
        @errorsContainer.removeClass "hidden"
        @errorsContainer.find("strong").text e.responseText

class window.App.SwapUsersController extends Spine.Controller

  events:
    "submit form": "submit"

  elements:
    "form": "form"
    "#errors": "errorsContainer"
    "button[type='submit']": "submitButton"

  constructor: (data)->
    @order = if data.reservations?
      data.reservations[0].order()
    else
      data.order
    @user = data.user
    @modal = new App.Modal App.Render "manage/views/orders/edit/swap_user_modal", @user
    @el = @modal.el
    super

    @disableForm()

    @searchSetUserController = new App.SearchSetUserController
      el: @el.find("#user #swapped-person")
      selectCallback: =>
        @enableForm()
        @setupContactPerson() if @manageContactPerson
      removeCallback: =>
        @disableForm()

    @setupContactPerson() if @manageContactPerson

  delegateEvents: =>
    super

  disableForm: -> @submitButton.attr('disabled', true)
  enableForm: -> @submitButton.attr('disabled', false)
  isDisabledForm: -> !!@submitButton.attr('disabled')

  submit: (e)->
    e.preventDefault()

    # NOTE: Needed for Safari wich does implicit submit even when disabled!
    return if @isDisabledForm()

    @errorsContainer.addClass "hidden"
    App.Button.disable @submitButton
    if @reservations?
      do @swapReservations
    else
      do @swapOrder

  swapOrder: =>
    userId = @searchSetUserController.selectedUserId ? @order.user().id
    @order.swapUser(userId, @searchSetContactPersonController?.selectedUserId)
    .done =>
      window.location = @order.editPath()
    .fail (e) =>
      @errorsContainer.removeClass "hidden"
      App.Button.enable @submitButton
      @errorsContainer.find("strong").text e.responseText

  swapReservations: =>
    App.Reservation.swapUser(@reservations, @searchSetUserController.selectedUserId)
    .done =>
      window.location = App.User.find(@searchSetUserController.selectedUserId).url("hand_over")
    .fail (e) =>
      @errorsContainer.removeClass "hidden"
      App.Button.enable @submitButton
      @errorsContainer.find("strong").text e.responseText

  renderContactPerson: => @form.append App.Render "manage/views/orders/edit/contact_person", @order

  setupContactPerson: =>
    @el.find("#contact-person").remove()
    @searchSetContactPersonController = null
    user_id = @searchSetUserController.selectedUserId ? @order.user().id
    if App.User.find(user_id).isDelegation()
      @renderContactPerson()
      App.User.ajaxFetch
        data: $.param
          delegation_id: user_id
      .done (data) =>
        @searchSetContactPersonController = new App.SearchSetUserController
          el: @el.find("#contact-person #swapped-person")
          localSearch: true
          customAutocompleteOptions:
            source: ( $.extend App.User.find(datum.id), { label: datum.name } for datum in data )
            minLength: 0
          selectCallback: =>
            @enableForm()
          removeCallback: =>
            @disableForm()

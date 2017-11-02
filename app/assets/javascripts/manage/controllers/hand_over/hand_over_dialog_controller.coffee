class window.App.HandOverDialogController extends Spine.Controller

  events:
    "click [data-hand-over]": "handOver"

  elements:
    "#purpose": "purposeTextArea"
    "#note": "noteTextArea"
    "#error": "errorContainer"

  constructor: (reservations, user, purpose)->
    @reservations = reservations
    @user = user
    @purpose = purpose

    do @setupModal
    super
    @delegatedUser = null # reset delegated user in order to force the user to set him explicitly
    do @autoFocus

  autoFocus: =>
    if @purposeTextArea.length
      @purposeTextArea.focus()
    else
      @noteTextArea.focus()

  setupModal: =>
    reservations = _.map @reservations, (line)->
      line.start_date = moment().format("YYYY-MM-DD")
      line
    @itemsCount = _.reduce reservations, ((mem,l)-> l.quantity + mem), 0
    data =
      groupedLines: App.Modules.HasLines.groupByDateRange reservations, true
      user: @user
      itemsCount: @itemsCount
      purpose: @purpose

    jModal = $("<div class='modal ui-modal medium' role='dialog' tabIndex='-1' />")
    @modal = new App.Modal(
      jModal,
      () =>
        ReactDOM.unmountComponentAtNode(jModal.get()[0])
    )
    @handOverDialog = ReactDOM.render(
      React.createElement(HandOverDialog, {
          data: data,
          other: {
            showAddPurpose: _.any(@reservations, (l)-> not l.purpose_id?),
            currentInventoryPool: App.InventoryPool.current
          },
          onDelegatedUser: (delegatedUser) =>
            @delegatedUser = delegatedUser
      }),
      @modal.el.get()[0]
    )
    @el = @modal.el


  handOver: =>
    if @purpose.length
      if @purposeTextArea.val()
        @purpose = "#{@purpose}; #{@purposeTextArea.val()}"
    else
      @purpose = @purposeTextArea.val()

    if @validatePurpose() and @validateDelegatedUser()
      App.Contract.create
        user_id: @user.id
        line_ids: _.map(@reservations, (l)->l.id)
        purpose: @purpose
        note: @noteTextArea.val()
        delegated_user_id: @delegatedUser?.id
      .fail (e)=>
        @errorContainer.find("strong").html(e.responseText)
        @errorContainer.removeClass("hidden")
      .done (data)=>
        @modal.undestroyable()
        @modal.el.detach()
        new App.DocumentsAfterHandOverController
          contract: new App.Contract data
          itemsCount: @itemsCount

  validatePurpose: =>
    if App.InventoryPool.current.required_purpose and not @purpose.length
      @errorContainer.find("strong").html(_jed("Specification of the purpose is required"))
      @errorContainer.removeClass("hidden")
      @purposeTextArea.focus()
      return false
    return true

  toggleAddPurpose: =>

  validateDelegatedUser: =>
    if @user.isDelegation() and not @delegatedUser
      @errorContainer.find("strong").html(_jed("Specification of the contact person is required"))
      @errorContainer.removeClass("hidden")
      false
    else
      true

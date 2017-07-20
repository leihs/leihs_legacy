class window.App.ItemEditController extends App.FormWithUploadController

  elements:
    "#flexible-fields": "flexibleFields"
    "#form": "itemForm"
    "input[name='copy']": "copyInput"

  events:
    "click #item-save-and-copy": "submitCopy"
    "click #show-all-fields": "showAllFields"
    "click [data-type='remove-field']": "removeField"

  constructor:->
    super
    @flexibleFieldsController = new App.ItemFlexibleFieldsController
      el: @flexibleFields
      itemData: @itemData
      itemType: @itemType
      writeable: true
      hideable: true
      callback: =>
        @attachmentsController = new App.ItemAttachmentsController {el: @el.find("#attachments")}

  save: ({skipSerialNumberValidation = false} = {}) =>
    if @flexibleFieldsController.validate()
      $.ajax
        url: @url
        data: @prepareRequestData(skipSerialNumberValidation)
        type: @method
    else
      do @hideLoading
      false

  prepareRequestData: (skipSerialNumberValidation = false) =>
    serial = @itemForm.serializeArray()
    for field in _.filter(App.Field.all(), (f) -> f.exclude_from_submit)
      serial = _.reject(serial, (s) -> s.name == field.getFormName())
    serial.concat \
      [{name: "item[skip_serial_number_validation]", value: skipSerialNumberValidation}]

  done: (data) =>
    # depending if used in new or edit template
    # item is available from start or is created on save thus
    # have to be set and the upload url with the item id too
    @item ?= new App.Item(id: data.id) # using only id, as some other attribute makes problem
    @attachmentsController.setUrl(@item)

    @attachmentsController.upload =>
      @finish(data.redirect_url)

  finish: (redirectUrl = null) =>
    if @attachmentsController.uploadErrors.length
      @setupErrorModal(@item)
    else
      url = redirectUrl ? App.Inventory.url()
      window.location = "#{url}?flash[success]=#{_jed('Item saved')}"

  errorHandler: (e) =>
    if e.responseJSON.can_bypass_unique_serial_number_validation
      saveAnyway = confirm("#{e.responseJSON.message} #{_jed('Save anyway')}?")
      if saveAnyway
        @submit e, => @save(skipSerialNumberValidation: true)
      else
        @hideLoading()
    else
      @showError e.responseJSON.message
      do @hideLoading

  submit: (event, saveAction = @save, errorHandler = @errorHandler) =>
    super(event, saveAction, errorHandler)

  submitCopy: (event) => @submit(event, @saveAndCopy)

  saveAndCopy: =>
    if @flexibleFieldsController.validate()
      @copyInput.prop "disabled", false
      $.ajax
        url: @url
        data: @prepareRequestData()
        type: @method
    else
      do @hideLoading

  showAllFields: ->
    $.ajax
      url: "/manage/#{App.InventoryPool.current.id}/fields"
      type: "post"
      data:
        _method: "delete"
      success: (response) =>
        $(".hidden.field").removeClass("hidden")
        $("#show-all-fields").hide()

  removeField: (e)=>
    target = $(e.currentTarget).closest("[data-type='field']")
    $.ajax
      url: "/manage/#{App.InventoryPool.current.id}/fields/#{target.data("id")}"
      type: "post"
      success: (response) =>
        field = App.Field.find target.data("id")
        for child in field.children()
          target.closest("form").find("[name='#{child.getFormName()}']").closest("[data-type='field']").addClass("hidden")
        target.addClass("hidden")
        $("#show-all-fields").show()

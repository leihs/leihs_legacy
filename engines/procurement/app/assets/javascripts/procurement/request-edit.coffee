RequestEditFormBehaviour =
  formValidations: ->
    # requireInspectionCommentIfQuantityDecreased
    $("input[name*='[approved_quantity]']").on 'change', ->
      parent_el = $(this).closest('.request')
      inspection_comment_el = parent_el.find("textarea[name*='[inspection_comment]']")
      order_quantity_el = parent_el.find("input[name*='[order_quantity]']")
      new_val = $(this).val()

      if (not order_quantity_el.val()) or Number(order_quantity_el.val()) > Number(new_val)
        order_quantity_el.val(new_val)

      requested_quantity_el = parent_el.find("input[name*='[requested_quantity]']")
      requested_quantity = if requested_quantity_el.length
                             requested_quantity_el.val()
                           else
                             parent_el.find('.requested_quantity').text()

      if Number(new_val) < Number(requested_quantity)
        inspection_comment_el.attr('required', 'true')
      else
        inspection_comment_el.removeAttr('required')

  autocompleteInputs: ->

    # form constraint validation additions
    $('input[type="number"][step="1"][data-customValidity]').each(->
      $elm = $(this)
      $elm.on('input', ->
        $elm[0]?.setCustomValidity?("") # reset first or it will seem invalid!
        if $elm.is(':invalid') then $elm[0]?.setCustomValidity?($elm.data('customvalidity'))
      )
    )

    $("#request_edit_select_inspection_comment_templates").on('change', ->
      $select = $(this)
      $textarea = $('[name="' + $select.data('target') + '"]')
      throw new Error unless $textarea.length
      templateText = $select.prop('value')
      currentText = $textarea.val()
      combinedText = if currentText and currentText.length
        templateText + '; ' + $textarea.val()
      else
        templateText
      $select.val('')
      $textarea.val(combinedText)
    )

    # accounting types
    do () ->
      $typeToggle = $('select[name*="[accounting_type]"]')
      return if !$typeToggle[0]
      $typeToggled = $('[data-toggledBy="accounting_type"]')
      setupFieldState = ((selected) ->
        if selected == 'aquisition'
          $typeToggled.filter('[data-toggleValue="aquisition"]').removeClass('hidden')
          $typeToggled.filter('[data-toggleValue="investment"]')
            .addClass('hidden')
            .find('input[name*="[internal_order_number]"]').removeAttr('required')
        else
          $typeToggled.filter('[data-toggleValue="aquisition"]').addClass('hidden')
          $typeToggled.filter('[data-toggleValue="investment"]')
            .removeClass('hidden')
            .find('input[name*="[internal_order_number]"]').attr('required', 'true')
      )
      setupFieldState($typeToggle.prop('value')) # initial state
      $typeToggle.on('change', -> setupFieldState($(this).prop('value')))

    $("input[name*='[article_name]']").on('keypress', ->
      $(this).closest('.form-group').find("input[name*='[model_id]']").val('')
    ).autocomplete
      minLength: 3
      source: ( request, response )->
        $.ajax
          url: "/procurement/models.json"
          dataType: "json"
          data:
            search_term: request.term
          success: ( data )->
            response( data )
      select: ( event, ui )->
        $(this).closest('.form-group').find("input[name*='[model_id]']").val( ui.item.id )
        $(this).val( ui.item.name ).change()
        false
    .each ->
      $(this).data('ui-autocomplete')._renderItem = ( ul, item )->
        $( "<li>" ).append( "<a>" + item.name + "</a>" ).appendTo( ul )

    $("input[name*='[supplier_name]']").on('keypress', ->
      $(this).closest('.form-group').find("input[name*='[supplier_id]']").val('')
    ).autocomplete
      minLength: 3
      source: ( request, response )->
        $.ajax
          url: '/procurement/suppliers.json'
          dataType: "json"
          data:
            search_term: request.term
          success: ( data )->
            response( data )
      select: ( event, ui )->
        $(this).closest('.form-group').find("input[name*='[supplier_id]']").val( ui.item.id )
        $(this).val( ui.item.name ).change()
        false
    .each ->
      $(this).data('ui-autocomplete')._renderItem = ( ul, item )->
        $( "<li>" ).append( "<a>" + item.name + "</a>" ).appendTo( ul )

    $("input[name*='[receiver]']").autocomplete
      minLength: 3
      source: ( request, response )->
        $.ajax
          url: '/procurement/users.json'
          dataType: "json"
          data:
            search_term: request.term
          success: ( data )->
            response( data )
            #response($.map data, (item)->
            #  {label: item.firstname + ' ' + item.lastname, value: item.id})
      select: ( event, ui )->
        $(this).val( ui.item.firstname + " " + ui.item.lastname ).change()
        false
    .each ->
      $(this).data('ui-autocomplete')._renderItem = ( ul, item )->
        $( "<li>" ).append( "<a>" + item.firstname + " " + item.lastname + "</a>" ).appendTo( ul )

  disableSubmitOnEnter: ->
    $('form input').keypress (e)->
      charCode = e.charCode || e.keyCode || e.which
      if charCode  == 13
        return false

  handleDeletingAttachments: ->
    $('.attachments a.delete').on 'click', ->
      li = $(this).closest('li')
      if li.find("input[name*='[attachments_delete]']").val() == '1'
        li.css('text-decoration', 'none').find("input[name*='[attachments_delete]']").val('')
      else
        li.css('text-decoration', 'line-through').find("input[name*='[attachments_delete]']").val('1')
      li.closest('form').change()
      false

  updateTotalSumOnChanges: (update_parents = false) ->
    $("input[name*='_quantity]'], input[name*='[price]']").on 'keyup change', ->
      order_quantity = $(this).closest('.request').find("input[name*='[order_quantity]']").val()
      approved_quantity = $(this).closest('.request').find("input[name*='[approved_quantity]']").val()
      requested_quantity = $(this).closest('.request').find("input[name*='[requested_quantity]']").val()
      quantity = order_quantity or approved_quantity or requested_quantity
      price_el = $(this).closest('.request').find("input[name*='[price]']")
      total = quantity * price_el.val()
      formatted_total = accounting.formatMoney(total, {symbol: 'CHF', format: "%s %v", precision: 0, thousand: "'"})
      $(this).closest('.request').find(".total_price").data('total', total).html(formatted_total)
      return unless update_parents
      big_total = 0
      $(".total_price").each ->
        if Number($(this).data('total'))
          big_total += Number($(this).data('total'))
      formatted_big_total = accounting.formatMoney(big_total, {symbol: 'CHF', format: "%s %v", precision: 0, thousand: "'"})
      $(".big_total_price").html(formatted_big_total)


  formChangeListener: ($form, {isSame, hasChanged})->
    initial_form_data = $form.serialize()
    $form.on('change keyup', ->
      attachments = $form.find("input[type='file']").map(-> $(this).val() ).get().join('')
      if initial_form_data != $form.serialize() or attachments != ''
        hasChanged?($form)
      else
        isSame?($form)
    )

  unsavedChangesConfirmation: ->
    return "#{_('You have unsaved data. Would you like to delete the data?')}"


window.App = {}
window.App.RequestEditFormBehaviour = RequestEditFormBehaviour

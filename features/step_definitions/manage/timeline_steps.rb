# -*- encoding : utf-8 -*-

Then /^for each visible model I can see the Timeline$/ do

  line_selector = nil
  parent_id = nil

  if not all('#edit-contract-view').empty?
    line_selector = '.order-line'
    parent_id = '#edit-contract-view'
  elsif not all('#hand-over-view').empty?
    line_selector = ".line[data-line-type='item_line']"
    parent_id = '#hand-over-view'
  elsif not all('#take-back-view').empty?
    line_selector = ".line[data-line-type='item_line']"
    parent_id = '#take-back-view'
  elsif not all('#search-overview').empty?
    line_selector = ".line[data-type='model']"
    parent_id = '#search-overview'
  elsif not all('#inventory').empty?
    line_selector = ".line[data-type='model']"
    parent_id = '#inventory'
  else
    raise 'unknown page'
  end

  find('.line', match: :first)

  current_role = @current_user.access_right_for(@current_inventory_pool).role

  line_texts = find(parent_id).all(line_selector, visible: true).map do |line_element|
    line_element.find('.test-fix-timeline').text
  end


  line_texts[0..5].each do |line_text|
    line = find(line_selector, text: line_text)
    if current_role == :group_manager and (@contract.nil? or [:signed].include? @contract.state)
      line.find('.line-actions > a', text: _('Timeline')).click
    else
      within line.find('.line-actions .multibutton') do
        find('.dropdown-toggle').click
        find('.dropdown-item', text: _('Timeline')).click
      end
    end
    find('.modal iframe')
    evaluate_script %Q{ $(".modal iframe").contents().first("#my_timeline").length; }
    find('.modal .button', text: _('Close')).click
    step 'the modal is closed'
  end
end

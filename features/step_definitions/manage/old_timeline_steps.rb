# -*- encoding : utf-8 -*-


def for_each_visible_model_I_can_see_the_Timeline(in_new_window)
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
    timeline_button = nil
    if current_role == :group_manager and (@contract.nil? or [:signed].include? @contract.state)
      timeline_button = line.find('.line-actions > a', text: _('Timeline'))
    else
      within line.find('.line-actions .multibutton') do
        find('.dropdown-toggle').click
        timeline_button = find('.dropdown-item', text: _('Timeline'))
      end
    end
    if in_new_window
      new_window =  window_opened_by { timeline_button.click }
      within_window new_window do
        find('div.row > div > div > div', text: 'Total')
        new_window.close
      end
    else
      timeline_button.click
      find('.modal iframe')
      evaluate_script %Q{ $(".modal iframe").contents().first("#my_timeline").length; }
      find('.modal .button', text: _('Close')).click
      step 'the modal is closed'
    end
  end
end

Then /^for each visible model I can see the Timeline$/ do
  for_each_visible_model_I_can_see_the_Timeline(false)
end

Then /^for each visible model I can see the Timeline in new window$/ do
  for_each_visible_model_I_can_see_the_Timeline(true)
end

# -*- encoding : utf-8 -*-

Angenommen /^ich öffne die Tagesansicht$/ do
  @current_inventory_pool = @user.managed_inventory_pools.first
  visit backend_inventory_pool_path(@current_inventory_pool)
  wait_until(10){ find("#daily") }
end

Wenn /^ich kehre zur Tagesansicht zurück$/ do
  step 'ich öffne die Tagesansicht'
end

Wenn /^ich öffnet eine Bestellung von "(.*?)"$/ do |arg1|
  el = find("#daily .order.line", :text => arg1)
  page.execute_script '$(":hidden").show();'
  el.find(".actions .alternatives .button .icon.edit").click
end

Dann /^sehe ich die letzten Besucher$/ do
  find("#daily .subtitle", :text => "Last Visitors")
end

Dann /^ich sehe "(.*?)" als letzten Besucher$/ do |arg1|
  find("#daily .subtitle", :text => arg1)
end

Wenn /^ich auf "(.*?)" klicke$/ do |arg1|
  find("#daily .subtitle a", :text => arg1).click
end

Dann /^wird mir ich ein Suchresultat nach "(.*?)" angezeigt/ do |arg1|
  find("#search_results h1", :text => "Search Results for \"#{arg1}\"")
end

Wenn /^ich eine Rücknahme mache$/ do
  step 'I open a take back'
end

Wenn /^etwas in das Feld "(.*?)" schreibe$/ do |field_label|
  if field_label == "Inventarcode/Name"
    find("#code").set(" ")
    page.execute_script('$("#code").trigger("focus")')
  end
end

Dann /^werden mir diejenigen Gegenstände vorgeschlagen, die in den dargestellten Rücknahmen vorkommen$/ do
  @customer.visits.take_back.first.lines.all do |line|
    find(".ui-autocomplete").should have_content line.item.inventory_code
  end
end

Wenn /^ich etwas zuweise, das nicht in den Rücknahmen vorkommt$/ do
  find("#code").set("_for_sure_this_is_not_part_of_the_take_back")
  page.execute_script('$("#process_helper").submit()')
end

Dann /^sehe ich eine Fehlermeldung$/ do
  wait_until{ @notification = find(".notification") }
end

Dann /^die Fehlermeldung lautet "(.*?)"$/ do |text|
  # default language is english, so its not so easy to test german here
end

Wenn /^einem Gegenstand einen Inventarcode manuell zuweise$/ do
  step 'I click an inventory code input field of an item line'
  step 'I select one of those'
end

Dann /^wird der Gegenstand ausgewählt und der Haken gesetzt$/ do
  wait_until { find(".line.assigned", :text => @item.model.name).find(".select input").checked? }
  step 'the count matches the amount of selected lines'
end

Wenn /^ich eine Rücknahme mache die Optionen beinhaltet$/ do
  @ip = @user.managed_inventory_pools.first
  @customer = @ip.users.all.select {|x| x.contracts.signed.size > 0 && !x.contracts.signed.detect{|c| c.options.size > 0}.nil? }.first
  visit backend_inventory_pool_user_take_back_path(@ip, @customer)
  page.has_css?("#take_back", :visible => true)
end

Wenn /^die Anzahl einer zurückzugebenden Option manuell ändere$/ do
  @option_line = find(".option_line")
  @option_line.find(".quantity input").set 1
end

Dann /^wird die Option ausgewählt und der Haken gesetzt$/ do
  @option_line.find(".select input").checked?.should be_true
  step 'the count matches the amount of selected lines'
end

Wenn /^ich eine Aushändigung mache die ein Model enthält dessen Gegenstände ein nicht ausleihbares enthält$/ do
  @ip = @user.managed_inventory_pools.first
  @contract = nil
  @ip.items.unborrowable.each do |item|
    @contract = @ip.contracts.unsigned.detect{|c| c.models.include?(item.model)}
  end
  @customer = @contract.user
  visit backend_inventory_pool_user_hand_over_path(@ip, @customer)
  page.has_css?("#take_back", :visible => true)
end

Wenn /^diesem Model ein Inventarcode zuweisen möchte$/ do
  @model = @contract.models.detect{|m| m.items.unborrowable.count > 0}
  @item_line_element = find(".item_line", :text => @model.name)
  @contract_line = ContractLine.find @item_line_element["data-id"]
  @item_line_element.find(".inventory_code input").click
  page.execute_script('$(".line[data-id=#{@contract_line.id}] .inventory_code input").focus()')
end

Dann /^schlägt mir das System eine Liste von Gegenständen vor$/ do
  wait_until { find(".ui-autocomplete") }
end

Dann /^diejenigen Gegenstände sind gekennzeichnet, welche als nicht ausleihbar markiert sind$/ do
  @model.items.unborrowable.in_stock.each do |item|
    find(".ui-autocomplete .ui-menu-item a.unborrowable", :text => item.inventory_code)
  end
end

Wenn /^die ausgewählten Gegenstände auch solche beinhalten, die in einer zukünftige Aushändigung enthalten sind$/ do
  find("#add_start_date").set (Date.today+2.days).strftime("%d.%m.%Y")
  step 'I add an item to the hand over by providing an inventory code and a date range'
end

Wenn /^ich versuche, die Gegenstände auszuhändigen$/ do
  step 'I click hand over'
end

Dann /^ich kann die Gegenstände nicht aushändigen$/ do
  all(".hand_over .summary").size.should == 0
end

Angenommen /^der Kunde ist in mehreren Gruppen$/ do
  @ip = @user.managed_inventory_pools.first
  @customer = @ip.users.detect{|u| u.groups.size > 0}
  @customer.should_not be_nil
end

Wenn /^ich eine Aushändigung an diesen Kunden mache$/ do
  visit backend_inventory_pool_user_hand_over_path(@ip, @customer)
end

Wenn /^eine Zeile mit Gruppen-Partitionen editiere$/ do
  @inventory_code = @ip.models.detect {|m| m.partitions.size > 1}.items.in_stock.borrowable.first.inventory_code
  @model = Item.find_by_inventory_code(@inventory_code).model
  step 'I assign an item to the hand over by providing an inventory code and a date range'
  find(".line.assigned .button", :text => "Edit").click
end

Wenn /^die Gruppenauswahl aufklappe$/ do
  wait_until {find(".partition.container")}
end

Dann /^erkenne ich, in welchen Gruppen der Kunde ist$/ do
  @customer_group_ids = @customer.groups.map(&:id)
  @model.partitions.each do |partition|
    next if partition.group_id.nil?
    if @customer_group_ids.include? partition.group_id
      find(".partition.container optgroup.customer_groups").should have_content partition.group.name
    end
  end
end

Dann /^dann erkennen ich, in welchen Gruppen der Kunde nicht ist$/ do
  @model.partitions.each do |partition|
    next if partition.group_id.nil?
    unless @customer_group_ids.include?(partition.group_id)
      find(".partition.container optgroup.other_groups").should have_content partition.group.name
    end
  end
end

Wenn /^ich eine Aushändigung mache mit einem Kunden der sowohl am heutigen Tag sowie in der Zukunft Abholungen hat$/ do
  @ip = @user.managed_inventory_pools.first
  @customer = @ip.users.detect{|u| u.visits.hand_over.size > 1}
  visit backend_inventory_pool_user_hand_over_path(@ip, @customer)
  page.has_css?("#take_back", :visible => true)
end

Wenn /^ich etwas scanne \(per Inventarcode zuweise\) und es in irgendeinem zukünftigen Vertrag existiert$/ do
  @model = @customer.contracts.unsigned.first.models.first
  @item = @model.items.borrowable.in_stock.first
  find("#code").set @item.inventory_code
  find("#process_helper .button").click
  wait_until { find(".line.assigned") }
end

Dann /^wird es zugewiesen \(unabhängig ob es ausgewählt ist\)$/ do
  find(".line.assigned .select input").checked?.should be_true
end

Wenn /^es in keinem zukünftigen Vertrag existiert$/ do
  @model_not_in_contract = (@ip.items.flat_map(&:model).uniq.delete_if{|m| m.items.borrowable.in_stock == 0} - @customer.contracts.unsigned.flat_map(&:models)).first
  @item = @model_not_in_contract.items.borrowable.in_stock.first
  find("#add_start_date").set (Date.today+7.days).strftime("%d.%m.%Y")
  find("#add_end_date").set (Date.today+8.days).strftime("%d.%m.%Y")
  find("#code").set @item.inventory_code
  @amount_lines_before = all(".line").size
  find("#process_helper .button").click
end

Dann /^wird es für die ausgewählte Zeitspanne hinzugefügt$/ do
  wait_until { @amount_lines_before < all(".line").size }
end

Angenommen /^ich mache eine Rücknahme$/ do
  step 'I open a take back'
end

Dann /^habe ich für jeden Gegenstand die Möglichkeit, eine Inspektion auszulösen$/ do
  page.execute_script '$(":hidden").show();'
  all(".item_line").all? {|x| x.find(".actions .alternatives .button", :text => /Inspect/) }
end

Wenn /^ich bei einem Gegenstand eine Inspektion durchführen$/ do
  find(".item_line .actions .alternatives .button", :text => /Inspect/).click
  wait_until { find(".dialog") }
end

Dann /^die Inspektion erlaubt es, den Status von "(.*?)" auf "(.*?)" oder "(.*?)" zu setzen$/ do |arg1, arg2, arg3|
  within("form#inspection span.select > span.name", :text => arg1) do
    within(:xpath, './/../select') do
      find("option", :text => arg2)
      find("option", :text => arg3)
    end
  end
end

Wenn /^ich Werte der Inspektion ändere$/ do
  @line_id = find("form#inspection input[name='line_id']")[:value]
  all("form#inspection select").each do |s|
    s.all("option").each do |o|
      o.select_option unless o.selected?
    end
  end  
end

Dann /^wenn ich die Inspektion speichere$/ do
  find("form#inspection .button.green").click
end

Dann /^wird der Gegenstand mit den aktuell gesetzten Status gespeichert$/ do
  wait_until { find(".notification.success")}
end

Angenommen /^man fährt über die Anzahl von Gegenständen in einer Zeile$/ do
  @lines = all(".line")
end

Dann /^werden alle diese Gegenstände aufgelistet$/ do
  @lines.each_with_index do |line, i|
    page.execute_script("$($('.line .items')[#{i}]).trigger('mouseenter')")
    find(".tip")
  end
end

Dann /^man sieht pro Modell eine Zeile$/ do
  @lines.each_with_index do |line, i|
    page.execute_script("$($('.line .items')[#{i}]).trigger('mouseenter')")
    sleep(1)
    model_names = find(".tip", :visible => true).all(".model_name").map{|x| x.text}
    model_names.size.should == model_names.uniq.size
  end
end

Dann /^man sieht auf jeder Zeile die Summe der Gegenstände des jeweiligen Modells$/ do
  @lines.each_with_index do |line, i|
    page.execute_script("$($('.line .items')[#{i}]).trigger('mouseenter')")
    sleep(1)
    quantities = find(".tip", :visible => true).all(".quantity").map{|x| x.text.to_i}
    quantities.sum.should >= quantities.size
  end
end

Angenommen /^ich suche$/ do
  @search_term = "a"
  find("#search").set(@search_term)
  find("#topbar .search.item input[type=submit]").click
end

Dann /^erhalte ich Suchresultate in den Kategorien Benutzer, Modelle, Gegenstände, Verträge und Bestellungen$/ do
  find(".user .list .line")
  find(".model .list .line")
  find(".item .list .line")
  find(".contract .list .line")
  find(".order .list .line")
end

Dann /^ich sehe aus jeder Kategorie maximal die (\d+) ersten Resultate$/ do |amount|
  amount = (amount.to_i+2)
  all(".user .list .line:not(.toggle)", :visible => true).size.should <= amount
  all(".model .list .line:not(.toggle)", :visible => true).size.should <= amount
  all(".item .list .line:not(.toggle)", :visible => true).size.should <= amount
  all(".contract .list .line:not(.toggle)", :visible => true).size.should <= amount
  all(".order .list .line:not(.toggle)", :visible => true).size.should <= amount 
end

Wenn /^eine Kategorie mehr als (\d+) Resultate bringt$/ do |amount|
  @lists = []
  all(".list").each do |list|
    @lists.push(list) if list.find(".hidden .line")
  end
end

Dann /^kann ich wählen, ob ich aus einer Kategorie mehr Resultate sehen will$/ do
  @lists.each do |list|
    list.find(".toggle")
  end
end

Wenn /^ich mehr Resultate wähle$/ do
  @lists.each do |list|
    list.find(".toggle .text").click
  end
end

Dann /^sehe ich die ersten (\d+) Resultate$/ do |amount|
  amount = amount.to_i + 2
  @lists.each do |list|
    list.all(".line").size.should == amount
  end
end

Wenn /^die Kategorie mehr als (\d+) Resultate bringt$/ do |amount|
  amount = amount.to_i
  @list_with_more_matches = []
  all(".inlinetabs .badge").each do |badge|
    @list_with_more_matches.push badge.find(:xpath, "../../..").find(".list") if badge.text.to_i > amount
  end
end

Dann /^kann ich wählen, ob ich alle Resultate sehen will$/ do
  @links_of_more_results = []
  @list_with_more_matches.each do |list|
    @links_of_more_results.push list.find(".line.show-all a")[:href]
  end
end

Wenn /^ich alle Resultate wähle erhalte ich eine separate Liste aller Resultate dieser Kategorie$/ do
  @links_of_more_results.each do |link|
    visit link
    wait_until { find("#search_results.focused") }
  end
end

Angenommen /^ich sehe Probleme auf einer Zeile, die durch die Verfügbarkeit bedingt sind$/ do
  step 'I open a hand over'
  step 'I add so many lines that I break the maximal quantity of an model'
  @line_el = find(".line.error")
  @line = ContractLine.find page.evaluate_script %Q{ $(".line.error:first-child").tmplItem().data.id; }
end

Angenommen /^ich fahre über das Problem$/ do
  page.execute_script %Q{ $(".line.error:first-child .problems").trigger("mouseenter"); }
  wait_until { find(".tip") }
end

Angenommen /^ich sehe die Anzahl der total ausleihbaren Modelle$/ do
  @model = Model.find_by_name @line_el.find(".name").text
  find(".tip").should have_content @model.total_borrowable_items_for_user(@customer, @ip)
end

Angenommen /^ich sehe die Anzahl der bereits reservierten Modelle$/ do
  find(".tip").should have_content (@model.total_borrowable_items_for_user(@customer, @ip)-(1 + @model.availability_in(@ip).maximum_available_in_period_for_groups(@customer.groups, @line.start_date, @line.end_date)))
end

Angenommen /^ich sehe die Anzahl der verfügbaren Modelle$/ do
  find(".tip").should have_content (1 + @model.availability_in(@ip).maximum_available_in_period_for_groups(@customer.groups, @line.start_date, @line.end_date))
end


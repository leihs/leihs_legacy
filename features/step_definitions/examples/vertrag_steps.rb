# -*- encoding : utf-8 -*-

Angenommen /^man öffnet einen Vertrag bei der Aushändigung$/ do
  step %Q{I open a hand over}
  step %Q{I select an item line and assign an inventory code}
  step %Q{I select an item line and assign an inventory code}
  step %Q{I select an item line and assign an inventory code}
  step %Q{I click hand over}
  step %Q{I see a summary of the things I selected for hand over}
  step %Q{I click hand over inside the dialog}
  step %Q{the contract is signed for the selected items}
  @contract_element = first("#print section.contract")
  @contract = @customer.contracts.signed.sort_by(&:updated_at).last
end

Angenommen /^man öffnet einen Vertrag bei der Rücknahme/ do
  step %Q{I open a take back}
  step %Q{I select all lines of an open contract}
  step %Q{I click take back}
  step %Q{I click take back inside the dialog}
end

Dann /^möchte ich die folgenden Bereiche sehen:$/ do |table|
  table.hashes.each do |area|
    case area["Bereich"]
       when "Datum"
         @contract_element.first(".date").should have_content Date.today.year
         @contract_element.first(".date").should have_content Date.today.month
         @contract_element.first(".date").should have_content Date.today.day
       when "Titel"
         @contract_element.first("h1").should have_content @contract.id
       when "Ausleihender"
         @contract_element.first(".customer")
       when "Verleier"
         @contract_element.first(".inventory_pool")
       when "Liste 1"
         # this list is not always there
       when "Liste 2"
         # this list is not always there
       when "Liste der Zwecke"
         @contract_element.first("section.purposes").should have_content @contract.purpose
       when "Zusätzliche Notiz"
         @contract_element.first("section.note")
       when "Hinweis auf AGB"
         @contract_element.first(".terms")
       when "Unterschrift des Ausleihenden"
         @contract_element.first(".terms_and_signature")
       when "Seitennummer"
         # depends on browser settings
       when "Barcode"
         @contract_element.first(".barcode")
       when "Vertragsnummer"
         @contract_element.first("h1").should have_content @contract.id
     end
   end
end

Dann /^seh ich den Hinweis auf AGB "(.*?)"$/ do |note|
  @contract_element.first(".terms").should_not be_nil
end

Dann /^beinhalten Liste (\d+) und Liste (\d+) folgende Spalten:$/ do |arg1, arg2, table|
  @list = @contract_element.find("section.list", :match => :first)
  
  table.hashes.each do |area|
    case area["Spaltenname"]
      when "Anzahl"
        @contract.lines.each {|line| @list.first("tr", :text=> line.item.inventory_code).first(".quantity", :text=> line.quantity.to_s) }
      when "Inventarcode"
        @contract.lines.each {|line| @list.first("tr", :text=> line.item.inventory_code) }
      when "Modellname"
        @contract.lines.each {|line| @list.first("tr", :text=> line.item.inventory_code).first(".model_name", :text=> line.item.model.name) }
      when "Startdatum"
        @contract.lines.each {|line| 
          line_element = @list.first("tr", :text=> line.item.inventory_code)
          line_element.first(".start_date").should have_content line.start_date.year
          line_element.first(".start_date").should have_content line.start_date.month
          line_element.first(".start_date").should have_content line.start_date.day
        } 
      when "Enddatum"
        @contract.lines.each {|line| 
          line_element = @list.first("tr", :text=> line.item.inventory_code)
          line_element.first(".end_date").should have_content line.end_date.year
          line_element.first(".end_date").should have_content line.end_date.month
          line_element.first(".end_date").should have_content line.end_date.day
        }
      when "Rückgabedatum"
        @contract.lines.each {|line|
          unless line.returned_date.blank? 
            line_element = @list.first("tr", :text=> line.item.inventory_code)
            line_element.first(".returning_date").should have_content line.returned_date.year
            line_element.first(".returning_date").should have_content line.returned_date.month
            line_element.first(".returning_date").should have_content line.returned_date.day
          end
        }
    end
  end
end

Dann /^sehe ich eine Liste Zwecken, getrennt durch Kommas$/ do
  @contract.lines.each {|line| @contract_element.first(".purposes").should have_content line.purpose.to_s }
end

Dann /^jeder identische Zweck ist maximal einmal aufgelistet$/ do
  purposes = @contract.lines.sort.map{|l| l.purpose.to_s }.uniq.join('; ')
  @contract_element.first(".purposes > p").text.should == purposes
end

Dann /^sehe ich das heutige Datum oben rechts$/ do
  @contract_element.first(".date").should have_content Date.today.year
  @contract_element.first(".date").should have_content Date.today.month
  @contract_element.first(".date").should have_content Date.today.day
end

Dann /^sehe ich den Titel im Format "(.*?)"$/ do |format|
  @contract_element.first("h1").text.match Regexp.new(format.gsub("#", "\\d"))
end

Dann /^sehe ich den Barcode oben links$/ do
  @contract_element.first(".barcode")
end

Dann /^sehe ich den Ausleihenden oben links$/ do
  @contract_element.first(".parties .customer")
end

Dann /^sehe ich den Verleiher neben dem Ausleihenden$/ do
  @contract_element.first(".parties .inventory_pool")
end

Dann /^möchte ich im Feld des Ausleihenden die folgenden Bereiche sehen:$/ do |table|
  @customer_element = find(".parties .customer")
  @customer = @contract.user
  table.hashes.each do |area|
    case area["Bereich"]
       when "Vorname"
         @customer_element.should have_content @customer.firstname
       when "Nachname"
         @customer_element.should have_content @customer.lastname
       when "Strasse"
         @customer_element.should have_content @customer.address
       when "Hausnummer"
         @customer_element.should have_content @customer.address
       when "Länderkürzel"
         @customer_element.should have_content @customer.zip
       when "PLZ"
         @customer_element.should have_content @customer.zip
       when "Stadt"
         @customer_element.should have_content @customer.city
     end
   end
end

Wenn /^es Gegenstände gibt, die zurückgegeben wurden$/ do
  visit backend_inventory_pool_user_take_back_path(@contract.inventory_pool, @customer)
  step %Q{I select all lines of an open contract}
  step %Q{I click take back}
  step %Q{I see a summary of the things I selected for take back}
  step %Q{I click take back inside the dialog}
  visit backend_inventory_pool_contracts_path(@contract.inventory_pool)
  first(".button", :text => /(Contract|Vertrag)/).click
end

Dann /^sehe ich die Liste (\d+) mit dem Titel "(.*?)"$/ do |arg1, titel|
  first(".dialog .contract")

  if titel == "Zurückgegebene Gegenstände"
    find_titel = /(Returned Items|Zurückgegebene Gegenstände)/
  elsif titel == "Ausgeliehene Gegenstände"
    find_titel = /(Borrowed Items|Geliehene Gegenstände)/
  end

  first(".dialog .contract", :text => find_titel)
end

Dann /^diese Liste enthält Gegenstände die ausgeliehen und zurückgegeben wurden$/ do
  all(".dialog .contract .returning_date").each do |date|
    date.should_not == ""
  end
end

Wenn /^es Gegenstände gibt, die noch nicht zurückgegeben wurden$/ do
  @not_returned = @contract.lines.select{|lines| lines.returned_date.nil?}
end

Dann /^diese Liste enthält Gegenstände, die ausgeliehen und noch nicht zurückgegeben wurden$/ do
  @not_returned.each do |line|
    @contract_element.first(".not_returned_items").should have_content line.model.name
    @contract_element.first(".not_returned_items").should have_content line.item.inventory_code
  end
end

When(/^die Modelle sind innerhalb ihrer Gruppe alphabetisch sortiert$/) do
  not_returned_lines, returned_lines = @contract.lines.partition {|line| line.returned_date.blank? }

  unless returned_lines.empty?
    names = all(".contract .returned_items tbody .model_name").map{|name| name.text}
    names.empty?.should be_false
    expect(names.sort == names).to be_true
  end

  unless not_returned_lines.empty?
    names = all(".contract .not_returned_items tbody .model_name").map{|name| name.text}
    names.empty?.should be_false
    expect(names.sort == names).to be_true
  end
end

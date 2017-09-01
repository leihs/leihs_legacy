
placeholder :string_with_spaces do
  match /.*/ do |s|
    s
  end
end

placeholder :boolean do
  match /(is not|do not see|a non existing|have not|can not)/ do
    false
  end

  match /(is|see|an existing|have|can)/ do
    true
  end
end

placeholder :confirm do
  match ', confirming to leave the page' do
    true
  end

  match '' do
    false
  end
end

# Given a foo exists
# Given a 2. foo exists
# Then I see the foo
# Then I see the 2. foo
placeholder :nth do
  match(/(a|the) (\d*)\./) { |_a, num| (num.to_i < 2) ? '' : num }
  match(/a|the|this/) { '' }
end

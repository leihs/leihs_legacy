if ApplicationRecord.connection.tables.include?("languages") and not Rails.env.test?

  unless Language.exists?

    [['English (UK)', 'en-GB', true, true],
     ['English (US)', 'en-US', false, true],
     ['Deutsch', 'de-CH', false, true],
     ['Züritüütsch','gsw-CH', false, true]].each do |lang|
       Language.create!(name: lang[0],
                        locale_name: lang[1],
                        default: lang[2],
                        active: lang[3])
     end

     if Language.exists?
       puts "Languages created: %s" % Language.all.map(&:name).join(', ')
     end

  end

end

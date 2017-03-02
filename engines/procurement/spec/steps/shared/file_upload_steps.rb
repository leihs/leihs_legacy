module FileUploadSteps
  step 'I upload a file' do
    field = find "input[name*='[attachments_attributes][][file]']"
    attach_file(field[:name], # _('Attachments'),
                "#{Rails.root}/features/data/images/image1.jpg")
  end
end

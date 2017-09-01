module FileUploadSteps
  UPLOADED_FILE = "#{Rails.root}/features/data/images/image1.jpg"
  step 'I upload a file' do
    field = find "input[name*='[attachments_attributes][][file]']"
    attach_file(field[:name], # _('Attachments'),
                UPLOADED_FILE)
  end

  step 'the uploaded file is now an attachment of the request' do
    @request.reload
    expect(@request.attachments.length).to be 1
    attachment = @request.attachments.first
    expect(attachment.filename).to eq File.basename(UPLOADED_FILE)
    expect(attachment.size).to be File.size(UPLOADED_FILE)
  end
end

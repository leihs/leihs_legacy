require_relative '../shared/common_steps'
require_relative '../shared/login_steps'
require_relative '../shared/personas_dump_steps'

module Manage
  module Spec
    module ModelCrudSteps
      include ::Spec::CommonSteps
      include ::Spec::LoginSteps
      include ::Spec::PersonasDumpSteps

      step 'there is a model without image' do
        @model = FactoryGirl.create(:model)
      end

      step 'there is a model with image' do
        @model = FactoryGirl.create(:model)
        @image = FactoryGirl.create(:image, target: @model)
        @filename = @image.filename
      end
     
      step 'I set the image as cover' do
        find('#images .row.line', text: @filename)
          .find("input[type='radio']")
          .click
      end

      step 'the image is set as cover' do
        expect(
          find('#images .row.line', text: @filename).find("input[type='radio']")
        ).to be_checked
        expect(@model.reload.cover_image.filename).to eq @filename
      end

      step 'I open the edit page of the model' do
        visit manage_edit_model_path(@current_inventory_pool, @model)
      end

      step 'I add an image' do
        @filename = 'image1.jpg'
        add_image(@filename)
      end

      step 'the model has been saved successfully' do
        step 'I see a success message'
      end

      step 'the model has the chosen image' do
        within '#images' do
          expect(all("[data-type='inline-entry']").count).to be == 1
          expect(current_scope).to have_content @filename
        end
      end

      step 'I remove the image' do
        within '#images' do
          find("[data-type='inline-entry'] [data-remove]").click
        end
      end

      step 'I add another image' do
        @filename = 'image2.jpg'
        add_image(@filename)
      end

      step 'the model does not have any image' do
        within '#images' do
          expect(current_scope).not_to have_selector("[data-type='inline-entry']")
        end
      end

      private

      def add_image(image)
        find("input[type='file']", match: :first, visible: false)
        page.execute_script("$('input:file').attr('class', 'visible');")
        image_field_id = find('.visible', match: :first)
        image_field_id.set Rails.root.join('features', 'data', 'images', image)
      end
    end
  end
end

RSpec.configure do |config|
  config.include Manage::Spec::ModelCrudSteps,
                 manage_model_crud: true
end

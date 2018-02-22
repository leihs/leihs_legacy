module LeihsAdmin
  class FieldsEditorController < AdminController

    def edit_react
      @props = {
        all_fields_path: fields_editor_all_fields_path,
        single_field_path: fields_editor_single_field_path,
        new_path: fields_editor_new_react_path,
        update_path: fields_editor_update_react_path,
        fields_path: fields_editor_path,
        groups_path: fields_editor_groups_path
      }
    end

    def destroy
      Field.unscoped.find(params[:id]).destroy!
      respond_to do |format|
        format.json do
          render(status: :ok, json: {})
        end
      end
    end

    def groups
      props = {
        groups: Field.unscoped.all.map { |f| f.data['group'] }.uniq
      }
      respond_to do |format|
        format.json do
          render(status: :ok, json: props)
        end
      end
    end

    def single_field
      field = Field.unscoped.where(id: params[:id]).first
      attribute = field.data['attribute']
      property = attribute[1]

      items_count = Item.where(
        "items.properties::json->>'#{property}' is not null"
      ).count

      props = {
        field: presenterify_field(field),
        items_count: items_count,
        groups: Field.unscoped.all.map { |f| f.data['group'] }.uniq
      }
      respond_to do |format|
        format.json do
          render(status: :ok, json: props)
        end
      end
    end

    def all_fields
      fields = Field.unscoped.all.map { |f| presenterify_field(f) }
      props = {
        fields: fields
      }
      respond_to do |format|
        format.json do
          render(status: :ok, json: props)
        end
      end
    end

    def new_react
      if Field.unscoped.where(id: params[:field][:id]).first
        respond_to do |format|
          format.json do
            render(status: :ok, json: { result: 'field-exists-already' })
          end
        end
        return
      end

      field = Field.new
      field.id = params[:field][:id]
      field.data = params[:field][:data].to_h
      field.position = 0
      field.dynamic = true
      field.active = params[:field][:active]
      field.save!
      respond_to do |format|
        format.json do
          render(status: :ok, json: { result: 'field-saved' })
        end
      end
    end

    def update_react
      field_id = params[:field][:id]
      field = Field.unscoped.find(field_id)
      field.data = params[:field][:data].to_h
      field.position = params[:field][:position]
      field.active = params[:field][:active]
      field.save!
      respond_to do |format|
        format.json do
          render(status: :ok, json: { result: 'field-saved' })
        end
      end
    end

    private

    def presenterify_field(field)
      {
        id: field.id,
        active: field.active,
        position: field.position,
        data: field.data,
        dynamic: field.dynamic
      }
    end
  end
end

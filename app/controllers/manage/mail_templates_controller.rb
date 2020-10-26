class Manage::MailTemplatesController < Manage::ApplicationController

  private

  # NOTE overriding super controller
  def required_manager_role
    require_role :inventory_manager, current_inventory_pool
  end

  public

  def index
    @template_types = \
      MailTemplate::TEMPLATE_TYPES
      .to_a
      .sort { |x, y| "#{x.second}#{x.first}" <=> "#{y.second}#{y.first}" }
  end

  def edit
    @mail_templates = []

    Language.unscoped.each do |language|
      ['text'].each do |format|
        mt = MailTemplate.find_by!(inventory_pool_id: current_inventory_pool.id,
                                   name: params[:name],
                                   language_locale: language.locale,
                                   format: format)
        @mail_templates << mt
      end
    end
  end

  def update
    @mail_templates = []
    errors = []

    params[:mail_templates].each do |p|
      mt = MailTemplate.find_by!(
        inventory_pool_id: current_inventory_pool.id,
        name: p[:name],
        language: Language.find_by(locale: p[:language]),
        format: p[:format])
      @mail_templates << mt
      unless mt.update_attributes(body: p[:body])
        errors << mt.errors.full_messages
      end
    end

    if errors.empty?
      redirect_to "/manage/#{current_inventory_pool.id}/mail_templates"
    else
      flash.now[:error] = errors.uniq.join(', ')
      render :edit
    end
  end

end

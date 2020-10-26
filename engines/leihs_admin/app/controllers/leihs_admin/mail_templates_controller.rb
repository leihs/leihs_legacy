module LeihsAdmin
  class MailTemplatesController < AdminController

    def index
      @template_templates = \
        MailTemplate::TEMPLATE_TYPES
        .to_a
        .sort { |x, y| "#{x.second}#{x.first}" <=> "#{y.second}#{y.first}" }
    end

    def edit
      @mail_templates = MailTemplate.where(name: params[:name],
                                           is_template_template: true)
    end

    def update
      @mail_templates = []
      @errors = []

      params[:mail_templates].each do |p|
        get_and_update_and_validate p
      end

      if @errors.empty?
        redirect_to '/admin/mail_templates'
      else
        flash.now[:error] = @errors.uniq.join(', ')
        render :edit
      end
    end

    private

    def get_and_update_and_validate(p)
      mt = \
        MailTemplate \
          .find_or_initialize_by(
            inventory_pool_id: nil,
            name: p[:name],
            language: Language.find_by(locale: p[:language]),
            format: p[:format])

      @mail_templates << mt

      unless mt.update_attributes(body: p[:body])
        @errors << mt.errors.full_messages
      end
    end
  end
end

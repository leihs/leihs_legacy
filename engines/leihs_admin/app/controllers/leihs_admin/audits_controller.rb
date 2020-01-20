module LeihsAdmin
  class AuditsController < AdminController
    PER_PAGE = 10

    def index
      @audits = audits

      respond_to do |format|
        format.html do
          @start_date = start_date_param
          @end_date = end_date_param
          @search_term = search_term_param
        end
        format.js do
          render partial: 'leihs_admin/audits/audits', collection: @audits
        end
      end
    end

    private

    def audits
      Audit
        .filter(start_date: Date.parse(start_date_param),
                end_date: Date.parse(end_date_param),
                auditable_id: id_param,
                auditable_type: type_param,
                user_id: user_id_param,
                search_term: search_term_param)
        .select(<<-SQL)
          audits.request_uuid,
          audits.user_id,
          array_agg(row_to_json(audits.*)) AS rows,
          MAX(audits.created_at) AS created_at
        SQL
        .group(<<-SQL)
          audits.request_uuid,
          audits.user_id,
          audits.created_at::date
        SQL
        .reorder('created_at DESC')
        .offset(PER_PAGE * page_param)
        .limit(PER_PAGE)
    end

    def start_date_param
      params[:start_date].presence or I18n.l(30.days.ago.to_date)
    end

    def end_date_param
      params[:end_date].presence or I18n.l(Time.zone.today)
    end

    def page_param
      Integer(params[:page].presence || 0)
    end

    def user_id_param
      params[:user_id].presence
    end

    def search_term_param
      params[:search_term].presence
    end

    def type_param
      params[:type].presence.try(&:camelize)
    end

    def id_param
      params[:id].presence
    end
  end
end

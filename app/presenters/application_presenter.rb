class ApplicationPresenter < Presentoir::Presenter
  include Rails.application.routes.url_helpers
  private :default_url_options, :default_url_options?

  def _presenter
    return if Rails.env != 'development' # Only for debugging etc
    self.class.name
  end

  private

  def prepend_url_context(url = '')
    # FIXME: RAILS BUG https://github.com/rails/rails/pull/17724
    context = Rails.application.routes.relative_url_root
    context.present? ? context + url : url
  end
end

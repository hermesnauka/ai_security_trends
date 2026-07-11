# frozen_string_literal: true

require "csv"

module RubyGuard
  module API
    class ExportAPI < Grape::API
      # PLAN.md §3: generated synchronously in-request — no async job/polling
      # endpoint, unlike app09_php_WORDPRESS's WP-Cron-based export. This
      # app's seeded data volume doesn't justify the added complexity.
      resource :export do
        params do
          optional :frameworkCode, type: String
          optional :severity, type: String, values: %w[critical high medium low info]
        end
        get "csv" do
          dataset = Threat.dataset
          dataset = dataset.where(framework_code: params[:frameworkCode]) if params[:frameworkCode]
          dataset = dataset.where(severity: params[:severity]) if params[:severity]

          content_type "text/csv"
          header["Content-Disposition"] = 'attachment; filename="threats.csv"'

          CSV.generate do |csv|
            csv << %w[code frameworkCode title severity category]
            dataset.order(:code).each do |t|
              csv << [t.code, t.framework_code, t.title, t.severity, t.category]
            end
          end
        end
      end
    end
  end
end

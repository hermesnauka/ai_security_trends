# frozen_string_literal: true

module RubyGuard
  module API
    class ThreatsAPI < Grape::API
      # D-02: Grape's `params` block is this app's runtime-checked validation
      # boundary — the closest Ruby analogue to FastAPI's Pydantic-model
      # request validation (PLAN.md §0). An invalid `severity` value here is
      # rejected with a 400 before a single line of endpoint logic runs.
      resource :threats do
        desc "Filterable, paginated threat list — matches app01_react's Page<T> envelope"
        params do
          optional :frameworkCode, type: String
          optional :severity, type: String, values: %w[critical high medium low info]
          optional :stride, type: String, values: %w[S T R I D E]
          optional :tag, type: String
          optional :q, type: String
          optional :page, type: Integer, default: 0, values: ->(v) { v >= 0 }
          optional :size, type: Integer, default: 20, values: ->(v) { v.positive? && v <= 100 }
          optional :sort, type: String, default: "code"
        end
        get do
          dataset = Threat.dataset
          dataset = dataset.where(framework_code: params[:frameworkCode]) if params[:frameworkCode]
          dataset = dataset.where(severity: params[:severity]) if params[:severity]
          dataset = dataset.where(Sequel.pg_array(:stride).op.contains([params[:stride]])) if params[:stride]
          dataset = dataset.where(Sequel.pg_array(:tags).op.contains([params[:tag]])) if params[:tag]
          if params[:q]
            like = "%#{params[:q]}%"
            dataset = dataset.where(Sequel.ilike(:title, like) | Sequel.ilike(:description_en, like))
          end

          total = dataset.count
          content = dataset.order(Sequel.lit(params[:sort])).limit(params[:size]).offset(params[:page] * params[:size]).all

          {
            content: content.map { |t| ThreatSummaryEntity.represent(t).as_json },
            totalElements: total,
            totalPages: (total.to_f / params[:size]).ceil,
            number: params[:page],
            size: params[:size]
          }
        end

        desc "A single threat's full detail: overview, mitigations, cross-references"
        params do
          requires :id, type: String
        end
        get ":id" do
          threat = Threat[params[:id]]
          error!({ timestamp: Time.now.iso8601, status: 404, error: "Not Found", message: "No such threat" }, 404) unless threat

          present threat, with: ThreatDetailEntity
        end
      end
    end
  end
end

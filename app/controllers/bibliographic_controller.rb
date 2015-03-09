class BibliographicController < ApplicationController
  include FormattingConcern

  def index
    if params[:bib_id]
      redirect_to action: :bib, bib_id: params[:bib_id], status: :moved_permanently
    else
      render plain: "Record please supply a bib id", status: 404
    end
  end

  def bib
    opts = {
      holdings: params.fetch('holdings', 'true') == 'true',
      holdings_in_bib: params.fetch('holdings_in_bib', 'true') == 'true'
    }

    records = VoyagerHelpers::Liberator.get_bib_record(params[:bib_id], nil, opts)


    if records.nil?
      render plain: "Record #{params[:bib_id]} not found or suppressed", status: 404
    else
      respond_to do |wants|
        wants.json  {
          json = MultiJson.dump(pass_records_through_xml_parser(records))
          render json: json
        }
        wants.xml {
          xml = records_to_xml_string(records)
          render xml: xml
        }
      end
    end
  end

  def bib_holdings
    records = VoyagerHelpers::Liberator.get_holding_records(params[:bib_id])
    if records.nil?
      render plain: "Record #{params[:bib_id]} not found or suppressed", status: 404
    else
      respond_to do |wants|
        wants.json  {
          json = MultiJson.dump(pass_records_through_xml_parser(records))
          render json: json
        }
        wants.xml {
          xml = records_to_xml_string(records)
          render xml: xml
        }
      end
    end
  end

  def bib_items
    records = VoyagerHelpers::Liberator.get_items_for_bib(params[:bib_id])
    if records.nil?
      render plain: "Record #{params[:bib_id]} not found or suppressed", status: 404
    else
      respond_to do |wants|
        wants.json  { render json: MultiJson.dump(records) }
        wants.xml { render xml: '<todo but="You probably want JSON anyway" />' }
      end
    end
  end

end

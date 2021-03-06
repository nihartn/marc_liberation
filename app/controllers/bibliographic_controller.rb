class BibliographicController < ApplicationController
  include FormattingConcern

  def index
    if params[:bib_id]
      if params.fetch(:holdings_only, '0') == '1'
        redirect_to action: :bib_holdings, bib_id: params[:bib_id], status: :moved_permanently
      elsif params.fetch(:items_only, '0') == '1'
        redirect_to action: :bib_items, bib_id: params[:bib_id], status: :moved_permanently
      else
        redirect_to action: :bib, bib_id: params[:bib_id], status: :moved_permanently
      end
    else
      render plain: "Record please supply a bib id", status: 404
    end
  end

  def bib
    opts = {
      holdings: params.fetch('holdings', 'true') == 'true',
      holdings_in_bib: params.fetch('holdings_in_bib', 'true') == 'true'
    }

    records = VoyagerHelpers::Liberator.get_bib_record(sanitize(params[:bib_id]), nil, opts)


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

  def bib_solr(format: nil)
    opts = {
      holdings: params.fetch('holdings', 'true') == 'true',
      holdings_in_bib: params.fetch('holdings_in_bib', 'true') == 'true'
    }

    records = VoyagerHelpers::Liberator.get_bib_record(sanitize(params[:bib_id]), nil, opts)

    if records.nil?
      render plain: "Record #{params[:bib_id]} not found or suppressed", status: 404
    else
      solr_doc = indexer.map_record(records)
      if format == :jsonld
        render json: solr_to_jsonld(solr_doc), content_type: 'application/ld+json'
      else
        render json: solr_doc
      end
    end
  end

  def context_urls
    root_url + 'context.json'
  end

  def root_url
    url_helpers.root_url(host: request.host_with_port)
  end

  def bib_jsonld
    bib_solr format: :jsonld
  end

  def bib_id_url
    url_helpers.show_bib_url(params[:bib_id], host: request.host_with_port)
  end

  def solr_to_jsonld(solr_doc=nil)
    { '@context': context_urls, '@id': bib_id_url }.merge(JSONLDRecord.new(solr_doc).to_h)
  end

  def url_helpers
    Rails.application.routes.url_helpers
  end

  def indexer
    TRAJECT_INDEXER
  end

  def bib_holdings
    records = VoyagerHelpers::Liberator.get_holding_records(sanitize(params[:bib_id]))
    if records.empty?
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
    records = VoyagerHelpers::Liberator.get_items_for_bib(sanitize(params[:bib_id]))
    if records.empty?
      render plain: "Record #{params[:bib_id]} not found or suppressed", status: 404
    else
      respond_to do |wants|
        wants.json  { render json: MultiJson.dump(records) }
        wants.xml { render xml: '<todo but="You probably want JSON anyway" />' }
      end
    end
  end

end

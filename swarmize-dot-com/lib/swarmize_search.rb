require 'elasticsearch'
require 'jbuilder'
require 'hashie'

class SwarmizeSearch
  include SwarmizeSearch::Queries
  attr_reader :token

  def initialize(token)
    @token = token
    @client = SwarmizeSearch.client
  end

  def self.client
    Elasticsearch::Client.new log: true, 
      host: ENV['ELASTICSEARCH_HOST'],
      transport_options: {
        request: { timeout: 5 }
      }
  end

  def search(index, query)
    search_results = @client.search(index: index, body: query)
    Hashie::Mash.new(search_results)
  end

  def total_pages_for_results(results, per_page)
    total_hits = results.hits.total
    (total_hits.to_f/per_page).ceil
  end

  def count_all
    query = all_query(1, 10)
    search_results_hash = search(token,query)
    search_results_hash['hits']['total']
  end

  def all(page=1, per_page=10)
    query = all_query(page, per_page)
    
    search_results_hash = search(token,query)

    rows = search_results_hash.hits.hits.map {|h| h._source}

    total_pages = total_pages_for_results(search_results_hash, per_page)

    [rows, total_pages]
  end

  def entirety
    results = []
    # scan and scroll
    # Open the "view" of the index with the `scan` search_type
    r = @client.search index: 'rycadjgp', 
                      search_type: 'scan', 
                      scroll: '5m', 
                      size: 100
    while r = @client.scroll(scroll_id: r['_scroll_id'], scroll: '5m') and not r['hits']['hits'].empty? do
      results += r['hits']['hits'].map {|h| Hashie::Mash.new(h['_source'])}
    end
    results
  end

  def aggregate_count(field)
    query = aggregate_count_query(field)
    
    search_results_hash = search(token,query)

    buckets = search_results_hash.aggregations.field_count.buckets

    buckets.map {|b| {b['key'] => b.doc_count} }
  end

  def cardinal_count(field, unique_field)
    query = cardinal_count_query(field, unique_field)
    
    search_results_hash = search(token,query)

    buckets = search_results_hash.aggregations.field_count.buckets

    buckets.map {|b| {b['key'] => b.unique_field.value} }
  end


end

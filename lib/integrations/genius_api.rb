# This class encapsulate low-level access to the Genius API. The idea is to hide as much 
# of the details and intricacies of the API as possible and to expose a simple interface
# for our purposes.

class GeniusApi
  # This is the maximum page size allowed by Genius (June 2023).
  # NOTE: Although the API says the max is 50, it only returns a maximum of 20 records.
  MAX_PER_PAGE = 50
  # API_TOKEN = 'pdeU5uylYO5pFEsb1O6JPR5Q0W8XTco6WodO2JZUvUSKhLMynBTk6kBZfYjF3XRK'

  def self.search(q:, per_page: MAX_PER_PAGE, max_results: nil)
    # NOTE: For now, we're not using the max_results parameter to limit the number of items
    # returned; we return all available results.

    url = "#{Rails.application.credentials.genius[:endpoint]}/search"

    params = {
      q: q,
      page: 0,
      per_page: per_page
    }

    results = []

    begin
      params[:page] += 1
      response = get(url, params)
      results += response['hits']
    end until response['hits'].size == 0

    results
  end

  private

  def self.default_headers
    {
      :authorization => "Bearer #{Rails.application.credentials.genius[:access_token]}",
      :content_type => :json,
      :accept => :json,
    }
  end

  def self.get(url, params)
    # This method makes the low-level GET call, checks for errors, and returns the portion of the
    # response that contains the actual data being returned.
    response = HTTP.headers(default_headers).get(url, params: params)
    results = ActiveSupport::JSON.decode(response.body)

    puts url, params
    puts response.status
    puts "#{results['response']['hits'].size} hits"

    raise StandardError, results['meta']['message'] if results['meta']['status'] != 200

    results['response']
  end

end

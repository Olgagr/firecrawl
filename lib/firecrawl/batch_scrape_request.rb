module Firecrawl 

  ##
  # The +BatchScrapeRequest+ class encapsulates a batch scrape request to the Firecrawl API. 
  # After creating a new +BatchScrapeRequest+ instance you can begin batch scraping by calling 
  # the +scrape+ method and then subsequently retrieve the results by calling the 
  # +retrieve_scrape_results' method.
  #
  # === examples
  # 
  # require 'firecrawl'
  #
  # request = Firecrawl::BatchScrapeRequest.new( api_key: ENV[ 'FIRECRAWL_API_KEY' )
  #
  # urls = [ 'https://example.com', 'https://icann.org' ]
  # options = Firecrawl::ScrapeOptions.build do 
  #   format                [ :markdown, 'screenshot@full_page' ]
  #   only_main_content     true
  # end
  # 
  # batch_response = request.scrape( urls, options )
  # while response.success?
  #   batch_result = batch_response.result 
  #   if batch_result.success?
  #     batch_result.scrape_results.each do | result |
  #       puts response.metadata[ 'title ] 
  #       puts '---'
  #       puts response.markdown
  #       puts "\n\n"
  #     end
  #   end
  #   break unless batch_result.status?( :scraping )
  #   batch_response = request.retrieve_scrape_results( batch_result )
  # end
  #
  # unless batch_response.success? 
  #   puts batch_response.result.error_description 
  # end 
  # 
  class BatchScrapeRequest < Request 

    ## 
    # The +scrape+ method makes a Firecrawl '/batch/scrape/{id}' POST request which will initiate 
    # batch scraping of the given urls. 
    # 
    # The response is always an instance of +Faraday::Response+. If +response.success?+ is true,
    # then +response.result+ will be an instance +BatchScrapeResult+. If the request is not 
    # successful then +response.result+ will be an instance of +ErrorResult+.
    #
    # Remember that you should call +response.success?+ to valida that the call to the API was
    # successful and then +response.result.success?+ to validate that the API processed the
    # request successfuly. 
    #
    def scrape( urls, options = nil, &block )        
      if options
        options = options.is_a?( ScrapeOptions ) ? options : ScrapeOptions.build( options.to_h ) 
        options = options.to_h
      else 
        options = {}
      end
      options[ :urls ] = [ urls ].flatten
      response = post( "#{BASE_URI}/batch/scrape", options, &block )
      result = nil 
      if response.success?
        attributes = ( JSON.parse( response.body, symbolize_names: true ) rescue nil )
        attributes ||= { success: false, status: :failed  }
        result = BatchScrapeResult.new( attributes[ :success ], attributes )
      else 
        result = ErrorResult.new( response.status, attributes )
      end

      ResponseMethods.install( response, result )  
    end 

    ## 
    # The +retrieve_scrape_results+ method makes a Firecrawl '/batch/scrape' GET request which 
    # will return the scrape results that were completed since the previous call to this method
    # ( or, if this is the first call to this method, since the batch scrape was started ). Note 
    # that there is no guarantee that there are any new batch scrape results at the time you make 
    # this call ( scrape_results may be empty ).
    # 
    # The response is always an instance of +Faraday::Response+. If +response.success?+ is +true+, 
    # then +response.result+ will be an instance +BatchScrapeResult+. If the request is not 
    # successful then +response.result+ will be an instance of +ErrorResult+.
    #
    # Remember that you should call +response.success?+ to valida that the call to the API was
    # successful and then +response.result.success?+ to validate that the API processed the
    # request successfuly. 
    #
    def retrieve_scrape_results( batch_result, &block )
      raise ArgumentError, "The first argument must be an instance of BatchScrapeResult." \
        unless batch_result.is_a?( BatchScrapeResult )
      response = get( batch_result.url, &block )  
      result = nil 
      if response.success? 
        attributes = ( JSON.parse( response.body, symbolize_names: true ) rescue nil )
        attributes ||= { success: false, status: :failed  }
        result = batch_result.merge( attributes  )
      else 
        result = ErrorResult.new( response.status, attributes )
      end 

      ResponseMethods.install( response, result )     
    end

  end 
end

# encoding: utf-8
require 'net/http'
require 'htmlentities'

module Cite
  class ISBN

    def initialize(isbn)
      @isbn=isbn.gsub(/-/,'')
    end

    def get_nlc()
      uri = URI.parse('http://opac.nlc.gov.cn/F')
      params = {'func'=>'find-m','request'=>@isbn,'find_code'=>'ISB'}
      http = Net::HTTP.new(uri.host, uri.port) 
      request = Net::HTTP::Get.new(uri.path) 
      request.set_form_data( params )
      request = Net::HTTP::Get.new( uri.path+ '?' + request.body ) 

      response = http.request(request)
      content=HTMLEntities.new.decode( response.body.force_encoding("UTF-8"))
      #content=HTMLEntities.new.decode(File.read('example').force_encoding("UTF-8"))
      ta=/题名与责任.+?<\/td>.+?<td.+?>.+?>.+?>[[:blank:]]*(?<t>.+?)[[:blank:]]*\[.+?\].+?\/[[:blank:]]*(?<a>.+?)[[:blank:]]*[著编]*<.+?<\/td>/m.match(content)
      pub=/出版项.+?<\/td>.+?<td.+?>.+?>.+?>[[:blank:]]*(?<l>.+?)[[:blank:]]*:[[:blank:]]*(?<p>.+?)[[:blank:]]*,[[:blank:]]*(?<y>.+?)[[:blank:]]*<.+?<\/td>/m.match(content)
      isbn=/Z13_ISBN_ISSN.+?value=\"(.+?)[[:blank:]]+/.match(content)
      @param = {'title'=>ta[:t],'author'=>ta[:a],'location'=>pub[:l],'publisher'=>pub[:p],'year'=>pub[:y],'isbn'=>isbn[1]}
    end
  end
end

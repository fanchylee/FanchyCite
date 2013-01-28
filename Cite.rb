# encoding: utf-8
require 'net/http'
require 'htmlentities'

module Cite
  class ISBN

    def initialize(isbn)
      @isbn=isbn.gsub(/-/,'')
    end

    def get_nlc()
      params = {:func=>'find-m',:request=>@isbn,:find_code=>'ISB'}
      uri = URI.parse('http://opac.nlc.gov.cn/F')
      uri.query=URI.encode_www_form(params)
      response =  Net::HTTP.get_response(uri)

      content=HTMLEntities.new.decode( response.body.force_encoding("UTF-8"))
      #content=HTMLEntities.new.decode(File.read('example').force_encoding("UTF-8"))
      ta=/题名与责任.+?<\/td>.+?<td.+?>.+?>.+?>[[:blank:]]*(?<t>.+?)[[:blank:]]*\[.+?\].+?\/[[:blank:]]*(?<a>.+?)[[:blank:]]*[著编]*<.+?<\/td>/m.match(content)
      pub=/出版项.+?<\/td>.+?<td.+?>.+?>.+?>[[:blank:]]*(?<l>.+?)[[:blank:]]*:[[:blank:]]*(?<p>.+?)[[:blank:]]*,[[:blank:]]*(?<y>.+?)[[:blank:]]*<.+?<\/td>/m.match(content)
      isbn=/Z13_ISBN_ISSN.+?value=\"(.+?)[[:blank:]]+/.match(content)
      @param = {'title'=>ta[:t],'author'=>ta[:a],'location'=>pub[:l],'publisher'=>pub[:p],'year'=>pub[:y],'isbn'=>isbn[1]}
    end
  end
end

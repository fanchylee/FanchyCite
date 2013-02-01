# encoding: utf-8
require 'net/http'
require 'htmlentities'

module Cite
	class ISBN

		def initialize(isbn)
			@isbn=isbn.gsub(/-/,'')
		end

		def get
			params = {:func=>'find-m',:request=>@isbn,:find_code=>'ISB'}
			uri = URI.parse('http://opac.nlc.gov.cn/F')
			uri.query=URI.encode_www_form(params)
			response=Net::HTTP.get_response(uri)

			content=HTMLEntities.new.decode( response.body.force_encoding("UTF-8"))
			#content=HTMLEntities.new.decode(File.read('example').force_encoding("UTF-8"))
			ta=/题名与责任.+?<\/td>.+?<td.+?>.+?>.+?>[[:blank:]]*(?<t>.+?)[[:blank:]]*\[.+?\].+?\/[[:blank:]]*(?<a>.+?)[[:blank:]]*[著编]*<.+?<\/td>/m.match(content)
			pub=/出版项.+?<\/td>.+?<td.+?>.+?>.+?>[[:blank:]]*(?<l>.+?)[[:blank:]]*:[[:blank:]]*(?<p>.+?)[[:blank:]]*,[[:blank:]]*(?<y>.+?)[[:blank:]]*<.+?<\/td>/m.match(content)
			isbn=/Z13_ISBN_ISSN.+?value=\"(.+?)[[:blank:]]+/.match(content)
			@param = {'title'=>ta[:t],'author'=>ta[:a],'location'=>pub[:l],'publisher'=>pub[:p],'year'=>pub[:y],'isbn'=>isbn[1]}
		end
	end
	class CNKI
		def initialize(id, prefix)
			@hash={"CCND"=>"newspaper", "CDFD"=>"thesis_D", "CMFD"=>"thesis_M", "IPFD"=>"conference_I", "CJFQ"=>"journal", "CPFD"=>"conference_C", "CYFD"=>"annual"}
			@thesis_type={"thesis_M"=>"硕士论文", "thesis_D"=>"博士论文"}
			@id=id
			case prefix
				when nil
				@db_prefix=nil
				@type='preprint'
				else
				@db_prefix=prefix
				@type=@hash[prefix]
			end
		end
		def get
			case @type
				when 'preprint'
				uri=URI.parse('http://www.cnki.net/kcms/detail/'+@id)
				else
				uri = URI.parse('http://www.cnki.net/kcms/detail/detail.aspx')
				uri.query=URI.encode_www_form({:FileName=>@id, :DbCode=>@db_prefix})
			end	
			response=Net::HTTP::get_response(uri)
			content=HTMLEntities.new.decode( response.body.force_encoding("UTF-8"))
			##
			#title entry
			title=/<span id="chTitle">(?<title>.+?)<\/span>/.match(content)[:title]
			##
			#author entry
			case @type
				when 'journal', 'newspaper', 'conference_C', 'thesis_M', 'thesis_D', 'conference_I'
				author=/【作者】.*?<a .+?>(?<author>.+?)<\/a>/m.match(content)[:author]
				when 'annual'
				author=/<div class="authorc"><a .+?>(?<author>.+?)<\/a>/m.match(content)[:author]
			end
			##
			#date year publisher journal issue type entry
			case @type
				when 'journal'
				detail=/GetInfo\(.+?,\'(?<year>.+?)\',\'(?<issue>.+?)\',\'(?<journal>.+?)\'\)/.match(content)
				year=detail[:year]
				issue=detail[:issue]
				journal=detail[:journal]
				@params={'title'=>title, 'author'=>author, 'year'=>detail[:year], 'issue'=>detail[:issue], 'journal'=>detail[:journal]}
				when 'newspaper'
				date=/【报纸日期】(?<date>[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2})/.match(content)[:date]
				publisher=/【报纸名称】.*?<a .+?>(?<publisher>.+?)<\/a>/m.match(content)[:publisher]
				@params={'title'=>title, 'date'=>date, 'publisher'=>publisher, 'author'=>author}
				when 'thesis_M', 'thesis_D'
				publisher=/【网络出版投稿人】.*?<a .+?>(?<publisher>.+?)<\/a>/m.match(content)[:publisher]
				year=/【网络出版投稿时间】(?<yaer>[[:digit:]]{4})/.match(content)[:year]
				type=@thesis_type[@type]
			end
		end
	end
end

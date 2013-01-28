#! /usr/bin/ruby -I.
# encoding: utf-8
require 'media_wiki'
require 'net/http'
require 'net/https'
require 'Cite'

#$https_char='s'#if https NOT to be used, just comment this line OR change it to be nil
zhwikiurl = URI.parse("http#{$https_char}://zh.wikipedia.org/wiki")
zhwikihttp = Net::HTTP.new(zhwikiurl.host, zhwikiurl.port)
$https_char=='s'? zhwikihttp.use_ssl=true : zhwikihttp.use_ssl=false

mw = MediaWiki::Gateway.new("http#{$https_char}://zh.wikipedia.org/w/api.php")
mw.login('Fanchy-bot','bot/1991')
mem=mw.category_members('分类:含未完成ISBN标签的页面')

mem.each{|i|
	content=zhwikihttp.request(Net::HTTP::Get.new((zhwikiurl.path+'/'+i).gsub(/ /,'_'))).body.force_encoding("UTF-8")
	isbn=/ISBN ([[:digit:]]{10,13}).+?单击这里.+?添加你的引用。.+?如果你仍在编辑主页面文章，你可能需要在一个新窗口打开。/m.match(content)
	next if isbn == nil
	isbn=isbn[1]
	isbn_nocheck=isbn[0..-2]
	if mw.get(i) != nil
		c=Cite::ISBN.new(isbn)
		data=c.get_nlc()
		next if data == nil
		wikicontent="{{Cite book\n"
		data.each{|key,value|
			wikicontent=wikicontent+"|#{key} = #{value}\n"
		}
		wikicontent=wikicontent+"|url=    <!--书籍链接-->\n|language=     <!--如果是简体中文请改为zh-hans，繁体中文为zh-hant-->\n|quote={{{quote|}}}<!--不要更改-->\n|page={{{page|}}}<!--不要更改-->\n|pages={{{pages|}}}<!--不要更改-->\n|ref={{{ref|}}}<!--不要更改-->\n}}"
	end
	wikititle=(isbn_nocheck.length == 9 ? "Template:Cite_isbn/978#{isbn_nocheck}" : "Template:Cite_isbn/#{isbn_nocheck}")
	mw.create(wikititle, wikicontent)
}

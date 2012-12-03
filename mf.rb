require 'sinatra'
require 'fileutils'


get '/' do
	erb :index
end

post '/upload' do
	FileUtils.move(params['file'][:tempfile].path,'uploads/')
	erb :meme
end


post '/meme' do
	"Your top text is " + params['top'] + ", and your bottom text is " + params['bottom']
end

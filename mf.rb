require 'sinatra'
require 'fileutils'
require_relative "mxit.rb"

get '/' do
	erb :index
end

post '/upload' do
	@mxit = Mxit.new(request.env)
	#@filename = Time.now.hour.to_s + '.jpg' #not yet unique
	@filename = 'file.jpg'	
	FileUtils.mkdir_p('public/uploads/' + @mxit.user_id)
	FileUtils.move(params['file'][:tempfile].path,'public/uploads/' + @mxit.user_id + '/' + @filename)
	@path = 'uploads/' + @mxit.user_id + '/' + @filename
	@top = params['top']
	@bottom = params['bottom']
	erb :meme
end

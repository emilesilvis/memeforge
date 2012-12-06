require 'sinatra'
require 'fileutils'
require_relative "mxit.rb"


get '/' do
	erb :index
end

post '/upload' do
	@mxit = Mxit.new(request.env)
	@filename = Time.now.to_s
	FileUtils.mkdir_p('uploads/' + @mxit.user_id)
	FileUtils.move(params['file'][:tempfile].path,'uploads/' + @mxit.user_id + '/' + @filename)
	@path = 'uploads/' + @mxit.user_id + '/' + @filename
	erb :meme
end

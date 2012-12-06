require 'sinatra'
require 'fileutils'
require_relative "mxit.rb"

get '/' do
	erb :index
end

post '/upload' do
	@mxit = Mxit.new(request.env)
	@filename = Time.now.year.to_s + '-' + Time.now.month.to_s + '-' + Time.now.day.to_s + '-' + Time.now.hour.to_s + '-' + Time.now.min.to_s + '-' + Time.now.sec.to_s + '.jpg' #not yet unique	
	FileUtils.mkdir_p('public/uploads/' + @mxit.user_id)
	FileUtils.move(params['file'][:tempfile].path,'public/uploads/' + @mxit.user_id + '/' + @filename, :force => true)
	@path = 'uploads/' + @mxit.user_id + '/' + @filename
	@top = params['top']
	@bottom = params['bottom']
	erb :meme
end

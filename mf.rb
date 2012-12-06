require 'sinatra'
require 'fileutils'
require_relative "mxit.rb"

enable :sessions

get '/' do
	erb :image
end

post '/image' do
	@mxit = Mxit.new(request.env)
	@filename = Time.now.year.to_s + '-' + Time.now.month.to_s + '-' + Time.now.day.to_s + '-' + Time.now.hour.to_s + '-' + Time.now.min.to_s + '-' + Time.now.sec.to_s + '-' + params['file'][:filename]	
	FileUtils.mkdir_p('public/uploads/' + @mxit.user_id)
	FileUtils.move(params['file'][:tempfile].path,'public/uploads/' + @mxit.user_id + '/' + @filename, :force => true)
	session[:path] = 'uploads/' + @mxit.user_id + '/' + @filename
	erb :top

end

post '/top' do
	session[:top] = params['top']
	erb :bottom
end

post '/bottom' do
	session[:bottom] = params['bottom']
	erb :meme
end

error do
  	''+ env['sinatra.error'].name
end

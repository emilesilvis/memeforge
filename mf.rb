require 'sinatra'
require 'fileutils'
require_relative "mxit.rb" #Toby's Mxit library
require 'gabba' #gem used to track Google Analytics page views
require 'net/http'
require 'aws-sdk'

enable :sessions

configure do
	GoogleAnalyticsTracker = Gabba::Gabba.new("UA-35092077-4","http://safe-wildwood-3459.herokuapp.com")

	AWS.config(
	  :access_key_id => 'AKIAJ47AJAI7J7EGRDAQ',
	  :secret_access_key => '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')
end

get '/' do
	GoogleAnalyticsTracker.page_view("Home","/")
	erb :home
end

get '/image' do
	GoogleAnalyticsTracker.page_view("Image","/image")
	erb  :image
end

post '/image' do

	session[:temp_file_name] = Random.rand(1000).to_s

	FileUtils.move(params['file'][:tempfile].path,'public/' + session[:temp_file_name], :force => true)

	erb :top
end

post '/top' do
	GoogleAnalyticsTracker.page_view("Top","/top")
	session[:top] = params['top'] #Save value of 'top' input to session object
	erb :bottom
end

post '/bottom' do
	GoogleAnalyticsTracker.page_view("Bottom","/bottom")
	session[:bottom] = params['bottom'] #Save value of 'bottom' input to session object

	Net::HTTP.start("memecaptain.com") do |http|
		resp = http.get("http://memecaptain.com/i?u=http://safe-wildwood-3459.herokuapp.com/" + session[:temp_file_name] + "&t1=" + session[:top] + "&t2=" + session[:bottom])
		open('public/' + session[:temp_file_name], "wb") do |file|
			file.write(resp.body)
	    end
	end

	s3 = AWS::S3.new
	bucket = s3.buckets['emilesilvis']
	@mxit = Mxit.new(request.env)
	object = bucket.objects['memeforge/' + @mxit.user_id + '/' + session[:temp_file_name]]
	object.write(Pathname.new('public/' + session[:temp_file_name]))		

	erb :meme
end

get '/mymemes' do
	a = []
	@mxit = Mxit.new(request.env)
	s3 = AWS::S3.new
	bucket = s3.buckets['emilesilvis']
	bucket.objects.with_prefix('memeforge/' + @mxit.user_id).each do |obj|
		a.push(obj.key)
	end
	a.inspect
end
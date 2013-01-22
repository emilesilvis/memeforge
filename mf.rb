#need to move stuff to helpers
#display bucket
#use AWS SES for feedback form
#display banner and cache for a minute

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

	session[:file_name] = Time.now.year.to_s + '-' + Time.now.month.to_s + '-' + Time.now.day.to_s + '-' + Time.now.hour.to_s + '-' + Time.now.min.to_s + '-' + Time.now.sec.to_s + '.jpg'

	FileUtils.move(params['file'][:tempfile].path,'public/temp-' + session[:file_name], :force => true)

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
		resp = http.get("http://memecaptain.com/i?u=http://safe-wildwood-3459.herokuapp.com/temp-" + session[:file_name] + "&t1=" + session[:top] + "&t2=" + session[:bottom])
		open('public/meme-' + session[:file_name], "wb") do |file|
			file.write(resp.body)
	    end
	end

	FileUtils.remove('public/temp-' + session[:file_name])

	s3 = AWS::S3.new
	bucket = s3.buckets['emilesilvis']
	@mxit = Mxit.new(request.env)
	object = bucket.objects['memeforge/' + @mxit.user_id + '/' + session[:file_name]]
	object.write(Pathname.new('public/meme-' + session[:file_name]))

	#FileUtils.remove('public/meme-' + session[:file_name])
			
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

get '/feedback' do
	erb :feedback
end

post '/feedback' do
	ses = AWS::SimpleEmailService.new
	ses.send_email(
	  :subject => 'MemeForge feedback',
	  :from => 'emile@silvis.co.za',
	  :to => 'emile@silvis.co.za',
	  :body_text => params['feedback'])
	erb "</br>Thanks for the feedback! </br> <a href='/'>Home</a>"
end
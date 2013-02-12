require 'sinatra'
require 'fileutils'
require_relative "mxit.rb" #Toby's Mxit library
require 'gabba' #gem used to track Google Analytics page views
require 'net/http'
require 'aws-sdk'
require 'rest_client'
require 'json'

enable :sessions

configure do
	GoogleAnalyticsTracker = Gabba::Gabba.new("UA-35092077-4","http://safe-wildwood-3459.herokuapp.com")
	AWS.config(
	  :access_key_id => ENV['AWS_KEY'],
	  :secret_access_key => ENV['AWS_SECRET']
	)
end

get '/' do
	GoogleAnalyticsTracker.page_view("Home","/")
	erb :home, :layout => false
end

get '/image' do
	GoogleAnalyticsTracker.page_view("Image","/image")
	erb  :image
end

post '/image' do
	session[:file_name] = Time.now.day.to_s + '-' + Time.now.month.to_s + '-' + Time.now.year.to_s + '-' + Time.now.hour.to_s + '-' + Time.now.min.to_s + '-' + Time.now.sec.to_s + '.jpg'
	FileUtils.move(params['file'][:tempfile].path,'public/temp-' + session[:file_name], :force => true)
	erb :top
end

post '/top' do
	GoogleAnalyticsTracker.page_view("Top","/top")
	session[:top] = URI.escape(params['top']) 
	erb :bottom
end

post '/bottom' do
	GoogleAnalyticsTracker.page_view("Bottom","/bottom")
	session[:bottom] = URI.escape(params['bottom'])
	Net::HTTP.start("memecaptain.com") do |http|
		response = http.get("http://memecaptain.com/i?u=http://safe-wildwood-3459.herokuapp.com/temp-" + session[:file_name] + "&t1=" + session[:top] + "&t2=" + session[:bottom])
		open('public/meme-' + session[:file_name], "wb") do |file|
			file.write(response.body)
	    end
	end
	FileUtils.remove('public/temp-' + session[:file_name])
	s3 = AWS::S3.new
	bucket = s3.buckets['emilesilvis']
	@mxit = Mxit.new(request.env)
	object = bucket.objects['memeforge/' + @mxit.user_id + '/' + session[:file_name]]
	object.write(Pathname.new('public/meme-' + session[:file_name]))
	
	erb :meme
end

get '/mymemes' do
	@memes = []
	@mxit = Mxit.new(request.env)
	s3 = AWS::S3.new
	bucket = s3.buckets['emilesilvis']
	bucket.objects.with_prefix('memeforge/' + @mxit.user_id).each do |object|
		@memes.push(object.key)
	end
	@memes.delete('memeforge/' + @mxit.user_id + '/')
	erb :mymemes
end

get '/allmemes' do
	protected!
	@memes = []
	s3 = AWS::S3.new
	bucket = s3.buckets['emilesilvis']
	bucket.objects.each do |object|
		@memes.push(object.key)
	end
	erb :mymemes
end

get '/feedback' do
	erb :feedback
end

post '/feedback' do
	@mxit = Mxit.new(request.env)
	ses = AWS::SimpleEmailService.new
	ses.send_email(
	  :subject => 'MemeForge feedback',
	  :from => 'emile@silvis.co.za',
	  :to => 'emile@silvis.co.za',
	  :body_text => params['feedback'] + ' - ' + @mxit.user_id)
	erb "Thanks! :) <br /><a href='/'>Home</a>"
end

get '/stats' do

	@memes = []
	s3 = AWS::S3.new
	bucket = s3.buckets['emilesilvis']
	bucket.objects.each do |object|
		@memes.push(object.key)
	end
	@memes.map! do |meme|
		meme.delete('memeforge/').slice(0,12)
	end
	
	erb 'Number of memes: ' + @memes.count.to_s + ' <br />Number of users: ' + @memes.uniq.count.to_s + '<br />Average memes per user: ' + format('%.2f', @memes.count.to_f/@memes.uniq.count.to_f)

end

helpers do
	def get_ad
		Net::HTTP.start("serve.mixup.hapnic.com") do |http|
			response = http.get("http://serve.mixup.hapnic.com/8215822")
			return response.body
		end
	end

	def protected!
    unless authorized?
      response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
      throw(:halt, [401, "Not authorized\n"])
    end
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == ['admin', ENV['MEME_SECRET']]
  end	
end

get '/auth' do
	redirect to('https://auth.mxit.com/authorize?response_type=code&client_id=c162a96bca7e4892acf52904ebc339ab&redirect_uri=http://safe-wildwood-3459.herokuapp.com/allow&scope=content/write&state=your_state')
end

get '/allow' do

	response = RestClient.post 'https://c162a96bca7e4892acf52904ebc339ab:050833abcd074cae810d4feb88c61ebc@auth.mxit.com/token','grant_type=authorization_code&code=' + params[:code] + '&redirect_uri=http://safe-wildwood-3459.herokuapp.com/allow', :content_type => 'application/x-www-form-urlencoded' 

	File.open('public/meme-' + session[:file_name], "rb") do |file|
		RestClient.post 'http://api.mxit.com/user/media/file/' + 'MemeForge' + '?fileName=' + 'meme-' + session[:file_name], file, :authorization => 'Bearer ' + JSON.load(response)['access_token']
    end

    FileUtils.remove('public/meme-' + session[:file_name])

    erb "Meme saved! <br /><a href='/'>Home</a>"

end

get '/users' do

	@memes = []
	s3 = AWS::S3.new
	bucket = s3.buckets['emilesilvis']
	bucket.objects.each do |object|
		@memes.push(object.key)
	end
	@memes.map! do |meme|
		meme.slice(10,12)
	end
	
	erb @memes.uniq.to_s

end
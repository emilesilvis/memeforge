require 'sinatra'
require 'fileutils'
require_relative "mxit.rb" #Toby's Mxit library
require 'gabba' #gem used to track Google Analytics page views
require 'net/http'

enable :sessions

before do
	GoogleAnalyticsTracker = Gabba::Gabba.new("UA-35092077-4","http://safe-wildwood-3459.herokuapp.com")
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
	erb :meme
end

get '/foo' do
	Net::HTTP.start("printmatic.net") do |http|
	resp = http.get("http://printmatic.net/wp-content/uploads/2012/12/Bird.jpg")		
	    open("foo.jpg", "wb") do |file|
		file.write(resp.body)
	    end
	end
end

get '/send' do
	send_file 'monkey.jpg'
end

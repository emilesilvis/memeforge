require 'sinatra'
require 'fileutils'
require_relative "mxit.rb" #Toby's Mxit library
require 'gabba' #gem used to track Google Analytics page views

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
	@mxit = Mxit.new(request.env) #Initailise Mxit object. This object is used to access a range of Mxit-specfic data, such as the user's ID.
	@filename = Time.now.year.to_s + '-' + Time.now.month.to_s + '-' + Time.now.day.to_s + '-' + Time.now.hour.to_s + '-' + Time.now.min.to_s + '-' + Time.now.sec.to_s + '-' + params['file'][:filename] #Creates a unique filename by concatenating a timestamp and the filename	
	FileUtils.mkdir_p('public/uploads/' + @mxit.user_id) #Creates or moves to a directory with the same name as the current user
	FileUtils.move(params['file'][:tempfile].path,'public/uploads/' + @mxit.user_id + '/' + @filename, :force => true) #Move the file from the temporary location to the newly created directory
	session[:path] = 'uploads/' + @mxit.user_id + '/' + @filename #Saves the path of the image to the path session object
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
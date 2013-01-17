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


	Net::HTTP.start("memecaptain.com") do |http|
	resp = http.get("http://memecaptain.com/i?u=http://safe-wildwood-3459.herokuapp.com/" + session[:temp_file_name] + "&t1=" + session[:top] + "&t2=" + session[:bottom])
	#resp = http.get('http://memecaptain.com/i?u=http://safe-wildwood-3459.herokuapp.com/793&t1=d&t2=f')		
	    open(session[:temp_file_name], "wb") do |file|
		file.write(resp.body)
		#http://memecaptain.com/i?u=http://safe-wildwood-3459.herokuapp.com/793&t1=d&t2=f
	    end
	end

	erb :meme

end

get '/send' do
	send_file 'monkey.jpg'
end

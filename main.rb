=begin
new_game- get, with post
bet- get, with post, redirect if no name, start over buttton link
gameplay- hit and stay buttons, redirect if no name or bet, start over button link

=end



require 'rubygems'
require 'sinatra'

#set :sessions, true
use Rack::Session::Cookie, :key => 'rack.session',
					                 :path => '/',
                           :secret => 'trojans'


get '/home' do 

  "Welcome home! Whatup y'all?"
end

get '/school' do
  erb :school
end

get '/work' do
  erb :"/work/work"
end

get '/form' do 
  erb :form
end

post '/after_post' do
  puts params[:username]
end




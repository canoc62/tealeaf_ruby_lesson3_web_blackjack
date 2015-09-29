#Christopher Cano
#Tealeaf Academy Ruby Lesson 3 Assignment: Blackjack Sinatra Web App

require 'rubygems'
require 'sinatra'

use Rack::Session::Cookie, :key => 'rack.session',
					                 :path => '/',
                           :secret => 'trojans'

BLACKJACK = 21
DEALER_HIT_GOAL = 17
ACE_VALUE = 11
ROYAL_VALUE = 10

helpers do

  def clear_bet
    session[:bet] = nil 
  end

  def winning_result(msg)
    session[:money] += session[:bet]
    @success = "#{session[:username]} wins! #{msg} #{session[:username]} has won $#{session[:bet]} and now has $#{session[:money]}."
    clear_bet
  end

  def losing_result(msg)
    session[:money] -= session[:bet]
    @error = "#{session[:username]} loses! #{msg} #{session[:username]} has lost $#{session[:bet]} and now has $#{session[:money]}."
    clear_bet
  end

  def tie_result(msg)
    @success = "#{session[:username]} and the dealer have tied! #{msg} #{session[:username]} has lost $0 and still has $#{session[:money]}."
    clear_bet
  end

  def blackjack?(player_hand, dealer_hand)
    player_total = calculate_total(player_hand)
    dealer_total = calculate_total(dealer_hand)

    if player_total == BLACKJACK && dealer_total < BLACKJACK
      winning_result("BLACKJACK!")
      @ask_play_again = true
    elsif player_total < BLACKJACK && dealer_total == BLACKJACK
      losing_result("BLACKJACK! Dealer wins!")
      @ask_play_again = true
    elsif player_total == BLACKJACK && dealer_total == BLACKJACK
      tie_result("")
      @ask_play_again = true
    else 
      @hit_or_stay_btn = true
    end
  end

  def compare_totals(player_hand, dealer_hand)
    player_total = calculate_total(player_hand)
    dealer_total = calculate_total(dealer_hand)
    if player_total == dealer_total
      tie_result("#{session[:username]} Total: #{player_total}, Dealer Total: #{dealer_total}.")
    elsif player_total > dealer_total
      winning_result("#{session[:username]} Total: #{player_total}, Dealer Total: #{dealer_total}.")
    else
      losing_result("#{session[:username]} Total: #{player_total}, Dealer Total: #{dealer_total}.")
    end
  end

  def calculate_total(hand)
    total = 0
    hand.each do |card|
      total += convert_value_to_number(card[1])
    end
    adjust_total_for_aces(total, hand)
  end

  def convert_value_to_number(value)
    if(value == "ace")
      numerical_value = ACE_VALUE
    elsif (value == "jack") || (value == "queen") || (value == "king")
      numerical_value = ROYAL_VALUE
    else
      numerical_value = value.to_i
    end
    numerical_value
  end

  def adjust_total_for_aces(total, hand)
    aces_array = hand.select { |card| card[1] == "ace" }
    if !aces_array.empty?
      if total > BLACKJACK 
        aces_array.each do |ace| 
          total -= 10 unless total < (BLACKJACK + 1)#22
        end
      end
    end
    total
  end

  def display_card(card)
    first_letter = card[0][0].downcase
    value = card[1]
    if first_letter == "c"
      card_name = "clubs_#{value}.jpg"
    elsif first_letter == "d"
      card_name = "diamonds_#{value}.jpg"
    elsif first_letter == "h"
      card_name = "hearts_#{value}.jpg"
    elsif first_letter == "s"
      card_name = "spades_#{value}.jpg"
    end

    "<img src='/images/cards/#{card_name}'>"
  end

  def validate_link #For GET requests for /game and after
    if !session[:username] 
      redirect '/name_form'
    elsif !session[:bet] 
      redirect '/bet_form'
    elsif session[:money] <= 0
      redirect '/game/game_over'
    end
  end

end

before do
  @dealer_turn = false
  @hit_or_stay_btn = false
  @ask_play_again = false
end

get '/' do
  if session[:username] && session[:money] > 0
    redirect '/bet_form'
  else
    redirect '/name_form'
  end
end

get '/name_form' do
  erb :name_form
end

post '/set_bet' do
  if params[:bet].empty? || params[:bet].to_i == 0
    @error = "Must bet to play."
    halt erb :bet_form
  end
  if params[:bet].to_i > session[:money]
    @error = "Cannot enter a bet of amount of more than you currently have."
    halt erb :bet_form
  end
  session[:bet] = params[:bet].to_i
  redirect '/game'
end

post '/set_name' do 
  if params[:username].empty?
    @error = "Name required."
    halt erb :name_form
  elsif params[:money].empty? || params[:money].to_i == 0
    @error = "Must have money to play."
    halt erb :name_form
  end
  session[:username] = params[:username]
  session[:money] = params[:money].to_i
  redirect '/bet_form'
end

get '/bet_form' do
  if !session[:username] 
    redirect '/name_form'
  elsif session[:money] <= 0 
    redirect '/game/game_over'
  end
  erb :bet_form
end

get '/game' do
  validate_link

  suits = ["Hearts", "Diamonds", "Clovers", "Spades"]
  values = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "jack", "queen", "king", "ace"]
  session[:deck] = suits.product(values).shuffle!

  session[:player_hand] = []
  session[:dealer_hand] = []

  2.times do 
    session[:player_hand] << session[:deck].pop
    session[:dealer_hand] << session[:deck].pop
  end
  
  blackjack?(session[:player_hand], session[:dealer_hand])
  
  erb :game
end

post '/game/player/hit' do
  session[:player_hand] << session[:deck].pop
  redirect '/game/player'
end

get '/game/player' do
  validate_link
  @hit_or_stay_btn = true
  if calculate_total(session[:player_hand]) > BLACKJACK
    losing_result("BUST!")
    @hit_or_stay_btn = false
    @ask_play_again = true
  end
  erb :game
end

post '/game/player/stay' do
  redirect '/game/dealer'
end

get '/game/dealer' do
  validate_link
  @dealer_turn = true

  if calculate_total(session[:dealer_hand]) < DEALER_HIT_GOAL
    dealer_total = calculate_total(session[:dealer_hand])
    while dealer_total < DEALER_HIT_GOAL 
      session[:dealer_hand] << session[:deck].pop
      dealer_total = calculate_total(session[:dealer_hand])
      break if dealer_total >= BLACKJACK 
    end
    if dealer_total > BLACKJACK
    winning_result("Dealer busts!")
    @ask_play_again = true
    end
  end

  if calculate_total(session[:dealer_hand]) <= BLACKJACK
    compare_totals(session[:player_hand], session[:dealer_hand])
    @ask_play_again = true
  end

  erb :game
end

get '/game/game_over' do
  erb :game_over
end

  

#!/usr/bin/env ruby

require 'yaml'
#require "rubygame"
require "gosu"
class Character
  attr_reader :strength, :hit_power, :total_damage, :name
  STRENGTH = 4
  HIT_POWER = 1..5
  def initialize(options={})
    @strength = options[:strength] || STRENGTH
    @hit_power = options[:hit_power] || HIT_POWER
    @total_damage = options[:total_damage] || 0
    @name = options[:name] || self.class.to_s

    # TODO add some kind of weighting to the possible_damage array
    @miss_array = options[:miss_array] || [0]
  end

  def possible_damage
    hit_power.to_a + @miss_array
  end

  def dead?
    total_damage > strength
  end

  def hit(damage)
    @total_damage = @total_damage + damage
  end

  def to_s
    name
  end
end

class NullSound
  def play
    puts 'roar...'
  end
end

class Ui
  DEFAULT_ENEMY_WON_FILE = 'sword_drop.mp3'.freeze
  DEFAULT_YOU_WON_FILE = 'sword_slice.mp3'.freeze
  DEFAULT_FAIL_FILE = 'fail-trombone-01.mp3'.freeze
  DEFAULT_ROAR_FILE = 'dragon_fire.mp3'.freeze
  DEFAULT_SWORD_FILE = 'sword1.mp3'.freeze
  DEFAULT_START_FILE = 'war_horn.mp3'.freeze
  DEFAULT_LUCK_FILE = 'coin_spin.mp3'.freeze
  DEFAULT_QUIT_FILE = 'chicken_cluck.mp3'.freeze
  attr_reader :you_won_file
  attr_reader :enemy_won_file
  attr_reader :luck_file
  attr_reader :fail_file
  attr_reader :roar_file
  attr_reader :start_file
  attr_reader :quit_file
  attr_reader :sword_file
  attr_reader :null_sound
  attr_reader :window
  def initialize( options = {} )
    @window = Gosu::Window.new(640, 480, false)
    @enemy_won_file = options[ :enemy_won_file ] || DEFAULT_ENEMY_WON_FILE
    @you_won_file = options[ :you_won_file ] || DEFAULT_YOU_WON_FILE
    @quit_file = options[ :quit_file ] || DEFAULT_QUIT_FILE
    @luck_file = options[ :luck_file ] || DEFAULT_LUCK_FILE
    @fail_file = options[ :fail_file ] || DEFAULT_FAIL_FILE
    @roar_file = options[ :roar_file ] || DEFAULT_ROAR_FILE
    @sword_file = options[ :sword_file ] || DEFAULT_SWORD_FILE
    @start_file = options[ :start_file ] || DEFAULT_START_FILE
    @null_sound = NullSound.new
  end

  def inform message
    puts message
  end

  def ask question
    print "#{question}\n\t=> "
    #system "stty -echo"
    answer = gets.chomp
    #system "stty echo"
    puts
    answer
  end

  def play(key=:roar)
    send("#{key}_sound").play
  end

  private
  # TODO define_method...

  ['sword', 'start', 'roar', 'fail', 'quit', 'enemy_won', 'you_won', 'luck'].each do |key|
    method_name = "#{key}_sound"
    define_method(method_name) do
      unless instance_variable_get("@#{method_name}")
        music_file =  send("#{key}_file")
        instance_variable_set("@#{method_name}", Gosu::Sample.new(window, music_file))
      end
      if instance_variable_get("@#{method_name}")
        instance_variable_get("@#{method_name}")
      else
        warn "null"
        null_sound
      end
    end
  end
end

class Question
  def self.choose( questions, options={:formula => :least_asked} )
    sorted_questions = questions.sort{|a,b| a.ask_count <=> b.ask_count }
    _count = sorted_questions.first.ask_count
    sorted_questions.select{|q| q.ask_count <= _count }.sample
  end

  def self.tokenize( answer, tokens={} )
    tokens.each do |(k,v)|
      if answer.match(k)
        return v
      end
    end
    answer
  end

  attr_reader :text, :correct_answers, :ask_count, :full_response
  def initialize(_text, _correct_answers=[], options={})
    @text = _text
    @correct_answers = _correct_answers
    @ask_count = options[:ask_count] || 0
    @full_response = options[:full_response] || _text
  end

  def displayable_answers
    correct_answers.reject{|answer| answer.is_a?(Proc) }.map{|answer| answer.is_a?(Regexp) ? answer.source : answer }
  end

  def full_response_with( answer )
    full_response % answer
  end

  def asked
    @ask_count = @ask_count + 1
  end

  def correct?( answer_token )
    correct_answers.any? do |correct_answer|
      if correct_answer.is_a?(Regexp)
        answer_token =~ correct_answer
      elsif correct_answer.is_a?(String)
        answer_token == correct_answer
      else # Proc
        !! correct_answer.call(answer_token)
      end
    end
  end

  def to_s
    text % '?'
  end
end

QFILE="./question_file.yml"
class QuestionLoader
  attr_reader :question_file
  def initialize(question_file)
    @question_file = question_file
  end
  def load
    if config = YAML.load(File.open(question_file))
      config[:questions]
    else
      []
    end
  end
end
# TODO make the answers be lambda's so that we can process the input
LOADED_QUESTIONS = QuestionLoader.new(QFILE).load
DEFAULT_QUESTIONS = [
  [ "%s * 9 = 45 ", ["5", "(4 + 1)", lambda{|expr| full_expr = "#{expr} * 9"; 45 == eval(full_expr)}] ],
  [ "2 + 2 = %s ", ["4", lambda{|expr| (expr =~ /\-*[0-9\.\)\(]+/) && (2 + 2 == eval(expr))}] ], # restrict answer
  [ "What are you suppose to practice now %s ", [/piano/i], {:full_response => "You are suppose to practice the %s"} ],
] + LOADED_QUESTIONS


You = Character.new(:name => ['buddy', 'kid'].sample)
Dragon = Character.new(:name => 'Dragon', :strength => 5, :hit_power => 2..7)
SuperDragon = Character.new(:name => 'SuperDragon', :strength => 7, :hit_power => 3..10)
Questions = DEFAULT_QUESTIONS.collect {|details| Question.new *details }

class DragonSlayer
  HELP_MSG = "\nFor this message, type 'help' (or '?'), otherwise:\n\tType the best answer you can think of. Then press 'enter'.\n\tType 'quit' (or 'exit') to chicken-out.\n\n"
  QUIT_MSG = "\n\n\tFine, run away...\n"
  CHEAT_MSG = "\n\tHave you considered that:\n\t\t%s"
  TRY_MSG = "This is your %s try..."
  SPECIAL_ANSWERS = {
    /^\s*$|attack/ => 'try_again',
    /\?|help/i => 'help',
    /cheat/i => 'cheat',
    /quit|exit/i => 'quit',
  }

  attr_reader :you, :enemy, :ui, :questions
  private :you
  private :enemy
  private :ui
  private :questions
  def initialize(_you=You, _enemy=[Dragon, SuperDragon].sample, _ui=Ui.new, _questions=Questions)
    @slaying = true # global boolean
    @you = _you
    @enemy = _enemy
    @ui = _ui
    @questions = _questions
    instructions
  end

  def cheat
    _question_with_answer = question.full_response_with( question.displayable_answers.sample )
    ui.inform( CHEAT_MSG % _question_with_answer )
    try_again
  end

  def help
    instructions
    try_again
  end

  def quit
    ui.inform QUIT_MSG
    ui.play :quit
    sleep 5
    exit
  end

  def try_again
    @tries += 1
    ui.inform TRY_MSG % @tries

    @response = nil
    response
  end

  def attack
    ui.play :start
    while slaying?
      prepare_to_attack
      if 0 == damage_this_round
        ui.play :luck
        ui.inform( "The good news, the #{enemy} missed. The bad news, so did you!" )
      else
        if you_hit_enemy?
          ui.play :sword
          @enemy.hit(damage_this_round)
          ui.inform "You inflicted #{damage_this_round} damage-point(s) to the #{enemy} for a total of #{@enemy.total_damage} damage-points"
          if enemy.dead?
            ui.play :you_won
            ui.inform "...and he's dead!"
            @slaying = false
          else
            ui.inform "...and he's mad now, #{you}!"
          end
        elsif enemy_hit_you?
          ui.play :roar
          @you.hit(damage_this_round)
          ui.inform "The #{enemy} inflicted #{damage_this_round} damage-point(s) to you for a total of #{@you.total_damage} damage-points"
          if you.dead?
            ui.play :enemy_won
            sleep 3
            ui.play :fail
            ui.inform "...and you're dead!"
            @slaying = false
          else
            ui.inform "...and you better run, #{you}!"
          end
        end
      end
    end
  end

  private

  def slaying?
    @slaying
  end

  def enemy_hit_you?
    enemy == aggressor
  end

  def question
    unless @question
      @question = Question.choose( questions )
      @question.asked
    end
    @question
  end

  def response
    unless @response
      _response = ui.ask( question )
      tokenized_response = Question.tokenize( _response, SPECIAL_ANSWERS )
      if respond_to?(tokenized_response)
        return @response = send(tokenized_response)
      end
      @response = tokenized_response
      ui.inform question.full_response_with(@response)
    end
    @response
  end

  def instructions
    ui.inform HELP_MSG
  end

  def correct_answer?
    question.correct?( response ).tap do |bool|
      ui.inform( bool ? "Correct" : "Wrong" )
    end
  end

  # return value based on answer to question
  def aggressor
    unless @aggressor
      @aggressor = correct_answer? ? you : enemy
    end
    @aggressor
  end

  #def other
  #  unless @other
  #  @other = ([ you, enemy ] - [aggressor]).first
  #  end
  #  @other
  #end

  def you_hit_enemy?
    you == aggressor
  end

  def damage_this_round
    unless @damage_this_round
      @damage_this_round = aggressor.possible_damage.sample
    end
    @damage_this_round
  end

  def prepare_to_attack
    @tries = 1
    @question = nil
    @response = nil
    @aggressor = nil
    #@other = nil
    @damage_this_round = nil
  end
end

dragon_slayer = DragonSlayer.new
dragon_slayer.attack
sleep 5

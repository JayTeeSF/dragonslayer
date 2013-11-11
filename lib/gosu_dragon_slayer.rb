require "gosu"
require_relative 'null_sound'
require_relative 'character'
require_relative 'ui'
require_relative 'question'
require_relative 'question_loader'


# TODO make the answers be lambda's so that we can process the input
LOADED_QUESTIONS = QuestionLoader.new(Question::DEFAULT_QFILE).load
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
  TRY_MSG = "Come on, this is try #%s..."
  SPECIAL_ANSWERS = {
    /^\s*$|attack/ => 'try_again',
    /\?|help/i => 'help',
    /cheat/i => 'cheat',
    /quit|exit/i => 'quit',
  }

  attr_reader :you, :enemy, :ui, :questions, :attacking
  private :you
  private :enemy
  private :ui
  private :questions
  attr_accessor :state
  attr_accessor :sleep_end
  attr_accessor :state_queue
  alias_method :attacking?, :attacking
  def initialize(_you=You, _enemy=[Dragon, SuperDragon].sample, _ui=Ui.new(self), _questions=Questions)
    @slaying = true # global boolean
    @you = _you
    @enemy = _enemy
    @ui = _ui
    @questions = _questions
    @sleep_end = Gosu::milliseconds
    @state_queue = [:instruction_state]
    next_state
    @attacking = false
  end

  def peek_state
    @state_queue.last
  end

  def next_state
    @state = @state_queue.pop
  end

  def name
    self.class.name
  end

  def sleep_till(sleep_end)
    @sleep_end = sleep_end
    @state = :sleep_state
  end

  def cheat
    _question_with_answer = question.full_response_with( question.displayable_answers.sample )
    ui.interstitial( CHEAT_MSG % _question_with_answer, :final_sleep => 4.7 )
    state_queue.push(:try_again)
    # try_again
  end

  def help
    state_queue.push(:instructions)
    #instructions
    state_queue.push(:try_again)
    #try_again
  end

  def quit
    ui.interstitial QUIT_MSG, :sound_name => :quit, :final_sleep => 2.0
    ui.exit
  end

  def try_again
    @tries += 1
    ui.interstitial TRY_MSG % @tries, :clear_screen => false

    @response = nil
    state_queue.push(:response)
    #response
  end

  def instruction_state
    instructions :sound_name => :start, :final_sleep => 9
  end

  def sleep_state
    time_left = @sleep_end - Gosu::milliseconds
    # puts "time_left: #{time_left.inspect}"
    return if time_left > 0
    #puts "peek_state: #{peek_state.inspect}"
    next_state
  end

  def update
    if state
      puts "sending state: #{state}"
      return send(state)
    else
      puts "updating..."
      if slaying? && ! attacking?
        puts "preparing to attack..."
        state_queue.push(:attack)
        @attacking = true
        prepare_to_attack
        # state_queue.push(:aggressor)
        state_queue.push(:assign_aggressor)
        next_state
      else
        puts "already attacking..."
      end
    end
  end

  def attack
    if slaying?
      #prepare_to_attack
      #return state_queue.push(:aggressor)

      if 0 == damage_this_round
        state_queue.push(:missed)
      else
        if you_hit_enemy?
          @enemy.hit( damage_this_round )
          state_queue.push(:determine_if_enemy_is_dead)
          ui.interstitial "You inflicted #{damage_this_round} damage-point(s) to the #{enemy} for a total of #{@enemy.total_damage} damage-points", :clear_screen => false, :sound_name => :sword
        elsif enemy_hit_you?
          @you.hit( damage_this_round )
          state_queue.push(:determine_if_you_are_dead)
          ui.interstitial "The #{enemy} inflicted #{damage_this_round} damage-point(s) to you for a total of #{@you.total_damage} damage-points", :clear_screen => false, :sound_name => :roar
        end
      end
    end
    @attacking = false
  end

  private

  def determine_if_you_are_dead
    if you.dead?
      state_queue.push(:you_dead)
    else
      state_queue.push(:better_run)
    end
  end

  def determine_if_enemy_is_dead
    if enemy.dead?
      state_queue.push(:enemy_dead)
    else
      state_queue.push(:better_run)
    end
  end

  def you_dead
    ui.play :enemy_won
    ui.interstitial "...and you're dead!", :clear_screen => false, :sound_name => :defeat, :initial_sleep => 3
    @slaying = false
  end

  def enemy_dead
    ui.play :you_won
    ui.interstitial "...and he's dead!", :clear_screen => false, :sound_name => :victory, :initial_sleep => 3
    @slaying = false
  end

  def better_run
    if you_hit_enemy?
      ui.interstitial "...and you better run, #{you}!", :clear_screen => false
    else
      ui.interstitial "...and he's mad now, #{you}!", :clear_screen => false
    end
  end

  def missed
    ui.interstitial( "The good news, the #{enemy} missed. The bad news, so did you!", :sound_name => :miss, :clear_screen => false, :final_sleep => 7 )
  end

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

  def process_response
    tokenized_response = Question.tokenize( _response, SPECIAL_ANSWERS )
    if respond_to?(tokenized_response)
      # return @response = send(tokenized_response)
      return send(tokenized_response)
    end
    @response = tokenized_response
    # ui.display question.full_response_with(@response)
    ui.interstitial question.full_response_with(@response)
  end

  def response
    unless @response
      _response = ui.interstitial( question, :presentation_method => :ask, :set_response => true )
      process_response
    end
    @response
  end

  def instructions(options={})
    ui.interstitial HELP_MSG, options
  end

  def correct_answer?
    question.correct?( response ).tap do |bool|
      ui.display( bool ? "Correct" : "Wrong" )
    end
  end

  # return value based on answer to question
  def aggressor
    #unless @aggressor
    #  state_queue.push(:assign_aggressor)
    #end
    @aggressor
  end

  def assign_aggressor
    @aggressor = correct_answer? ? you : enemy
  end

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

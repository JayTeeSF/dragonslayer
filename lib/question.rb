class Question
DEFAULT_QFILE="./question_file.yml"
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

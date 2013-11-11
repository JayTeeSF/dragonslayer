require 'yaml'

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

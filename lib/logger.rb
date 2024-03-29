class Logger
  DEBUG = false
  attr_reader :log, :indent_level
  def initialize log=STDOUT, indent_level=0
    @log = log
    @indent_level = indent_level
  end

  def start
    return unless DEBUG
    message = yield
    puts_raw { indented("=> #{message}") }
    incr
  end

  def stop &block
    return unless DEBUG
    decr
    message = yield
    puts_raw { indented("<= #{message}") }
  end

  def one &block
    start( &block )
    stop( &block )
  end

  def decr
    got = indent_level - 1
    @indent_level =  got >= 0 ? got : 0
  end

  def incr
    @indent_level = @indent_level + 1
  end

  def puts
    return unless DEBUG
    message = yield
    log.puts indented("- #{message}")
  end

  def puts_raw
    return unless DEBUG
    message = yield
    log.puts message
  end

  def print_raw
    return unless DEBUG
    message = yield
    log.print message
  end

  private
  def indented message
    message_prefix = ""
    indent_level.times { message_prefix << "\t" }
    "#{message_prefix}#{message}"
  end
end

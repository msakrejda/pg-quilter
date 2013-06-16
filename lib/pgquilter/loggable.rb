module PGQuilter
  module Loggable

    def logger
      unless @logger
        @logger ||= Logger.new(STDOUT)
        @logger.level = Logger.const_get(PGQuilter::Config::LOG_LEVEL)
        puts "set logger level to #{@logger.level}"
      end
      @logger
    end

    def log(msg)
      logger.debug(msg)
    end
  end
end

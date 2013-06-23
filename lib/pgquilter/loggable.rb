module PGQuilter
  module Loggable

    def logger
      unless @logger
        @logger ||= Logger.new(STDOUT)
        @logger.level = Logger.const_get(::PGQuilter::Config::LOG_LEVEL)
      end
      @logger
    end

    def log(msg)
      logger.debug(msg)
    end
  end
end

require 'fiber'
require 'em-redis'


def callcc(proc, *args)
  curr_fiber = Fiber.current
  proc.call(*args, &curr_fiber.method(:resume))
  return Fiber.yield
end


module EventMachine
  def self.run_fiber(*args, &blk)
    f = Fiber.new(&blk)
    run(*args) { f.resume }
  end

  module Protocols::RedisFiber
    include Protocols::Redis

    # Classmethods don't get mixed in.
    def self.connect(*args)
        case args.length
        when 0
          options = {}
        when 1
          arg = args.shift
          case arg
          when Hash then options = arg
          when String then options = {:host => arg}
          else raise ArgumentError, 'first argument must be Hash or String'
          end
        when 2
          options = {:host => args[0], :port => args[1]}
        else
          raise ArgumentError, "wrong number of arguments (#{args.length} for 1)"
        end
        options[:host] ||= '127.0.0.1'
        options[:port]   = (options[:port] || 6379).to_i
        EM.connect options[:host], options[:port], self, options
      end

    
    def inline_command(*args)
      callcc((method :call_command), *args)
    end
    alias :call_command :inline_command


    def multiline_command(command, *args)
      callcc((method :cps_multiline_command), command, *args)
    end

  end
end

module Skylight
  class Subscriber
    include Util::Logging

    attr_reader :config

    def initialize(config)
      @config      = config
      @subscriber  = nil
      @normalizers = Normalizers.build(config)
    end

    def register!
      unregister! if @subscriber
      @subscriber = ActiveSupport::Notifications.subscribe nil, self
    end

    def unregister!
      ActiveSupport::Notifications.unsubscribe @subscriber
      @subscriber = nil
    end

    def start(name, id, payload)
      return unless trace = Instrumenter.current_trace

      cat, title, desc, annot = normalize(trace, name, payload)
      trace.start(now - gc_time, cat, title, desc, annot)

      trace
    rescue Exception => e
      error "Subscriber#start error; msg=%s", e.message
    end

    def finish(name, id, payload)
      return unless trace = Instrumenter.current_trace
      trace.stop(now - gc_time)
    rescue Exception => e
      error "Subscriber#finish error; msg=%s", e.message
    end

    def publish(name, *args)
      # Ignored for now because nothing in rails uses it
    end

  private

    def normalize(*args)
      @normalizers.normalize(*args)
    end

    def gc_time
      GC.update
      GC.time
    end

    def now
      Util::Clock.default.now
    end

  end
end
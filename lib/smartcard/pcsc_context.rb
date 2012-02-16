module Smartcard
module PCSC
  # +Context+ is an artefact from the PC/SC API this library
  # is based on. It provides a handle into the PC/SC system of the
  # computer. This class provides a slightly more 'rubyish' access
  # to the context functionality provided by FFI::Context, which 
  # wraps the native PC/SC library.

  class Context < FFI::Context
    # The scope that this Context has been initialized to.
    # One of:
    #     * SCOPE_USER
    #     * SCOPE_TERMINAL
    #     * SCOPE_SYSTEM          
    attr_reader :scope

    # Creates an application context connecting to the PC/SC resource manager.
    # A context is required to access every piece of PC/SC functionality.
    #
    # Wraps +SCardEstablishContext+ in PC/SC.
    #
    # === Values for +scope+
    #     * SCOPE_USER
    #     * SCOPE_TERMINAL
    #     * SCOPE_SYSTEM (default)
    def initialize scope=SCOPE_SYSTEM 
      unless [SCOPE_USER, SCOPE_TERMINAL, SCOPE_SYSTEM].include?(scope) 
        raise PcscException.new("invalid scope: #{scope}")
      end
      @scope = scope
      super
    end

    # Retrieves a subset of the currently available card readers in the system. 
    # Wraps +SCardListReaders+ in PC/SC.
    # 
    # Returns an array of strings containing the names of the card readers in the given groups.
    # You may optionally provide an array of strings inidicating which reader groups to list.
    def list_readers reader_groups=nil
      super
    end
  
    # Checks if the PC/SC context is still valid.
    # A context may become invalid if the resource manager service has been shut down.
    #
    # Wraps +SCardIsValidContext+ in PC/SC.

    def valid?
      # Method provided here for the sake of documentation.
      # rdoc sucks.
      is_valid
    end

    # Destroys the communication context connecting to the PC/SC Resource Manager. 
    # Should be the last PC/SC function called, because a context is required to 
    # access every piece of PC/SC functionality.
    def release
      # provided for the sake of documentation.
      super
    end
     
    class << self
      # Utility to avoid resource management and release of the context.
      # A PC/SC context is established and passed in to the block provided
      # to the method. You my optionally provide a scope parameter, if
      # you don't the scope defaults to +SCOPE_SYSTEM+
      #
      # ---
      #
      # === Values for +scope+
      #     * SCOPE_USER
      #     * SCOPE_TERMINAL
      #     * SCOPE_SYSTEM  
      
      def context scope=SCOPE_SYSTEM
        ctx = nil
        begin
          ctx = self.new(scope)
          yield ctx
        ensure
          ctx.release if ctx
        end
      end

      # +connect+ is simply an alias for Context.context to avoid having to type
      # things like:
      #
      #     Context.context{ |context| 
      #        # more context code here.
      #     }
      #
      # Instead, you can type: 
      #
      #     Context.connect {|ctx|
      #       # more code 
      #       # MUCH nicer ... :)
      #     }

      alias_method :connect, :context
  
    end
  end
end
end


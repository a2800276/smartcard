module Smartcard
module PCSC
  
  # +Card+ represents smartcard in a reader, it contains methods to
  # establish connections to a card, send data, query the card and
  # readers status, etc. The +Card+ class inherits from PCSC::FFI::Card 
  # which is a C extension that more or less provides a direct wrapper of
  # the PC/SC C API.
  #      
  # The derived class attempts to provide a more 'rubyish' interface,
  # based on assumptions about the most common use cases:
  #   
  # * the system contains one reader and that is the one you wish to use
  # * you wish to use the card exclusively
  # * the card should be powered down after use
  # * reconnecting to the card implies a warm reset
  #
  # If necessary all of these defaults may be changed. 
  #
  # === Example
  #
  #    # send cla=00 ins=00 p1=00 p2=00 to card
  #    Card.card {|card|
  #       resp = card.transmit("\x00\x00\x00\x00")
  #    }
 
  
  class Card < FFI::Card
    # The context this card is part of. 
    attr_reader :context
    # The name of this cards reader.
    attr_reader :reader_name
    # The share option this card is connected with.
    # One of:
    # +SHARE_EXCLUSIVE+:: This application will NOT allow others to share the reader 
    # +SHARE_SHARED+::    This application will allow others to share the reader. 
    # +SHARE_DIRECT+::    Direct control of the reader, even without a card, may be used to send control commands to the reader without a card inserted.
    attr_reader :share_mode
    

    # Establishes a connection to a card in a reader. In case a
    # +reader_name+ parameter is provided, the card in that reader is
    # used, else the first available card in the first reader will be
    # used.
    #
    # The first connection will power up and perform a reset on the card.
    #
    # Wraps +SCardConnect+ in PC/SC.
    #
    # === Parameters
    # ==== Required
    # +context+:: the +Context+ to use to connect to the PC/SC resource manager
    # ==== Optional
    # +reader_name+:: friendly name of the reader to connect to; get using <tt>Context#list_readers</tt>, defaults to the first found reader. 
    # +share_mode+:: whether a shared or exclusive lock will be requested on the reader;  use one of the <tt>PCSC::SHARE_...</tt> constants, defaults to +SHARE_EXCLUSIVE+
    # +preferred_protocols+:: desired protocol; use one of the <tt>PROTOCOL_...</tt> constants, defaults to +PROTOCOL_ANY+
    #
    # ---
    #
    # === Values for +share_mode+
    #
    # +SHARE_EXCLUSIVE+:: This application will NOT allow others to share the reader 
    # +SHARE_SHARED+::    This application will allow others to share the reader. 
    # +SHARE_DIRECT+::    Direct control of the reader, even without a card, may be used to send control commands to the reader without a card inserted.
    #
    # === Values for +preferred_protocols+
    #
    # <tt>PROTOCOL_T0</tt>::   T=0 Protocol
    # <tt>PROTOCOL_T1</tt>::   T=1 Protocol
    # <tt>PROTOCOL_T15</tt>::  T=15 Protocol
    # +PROTOCOL_RAW+::  Raw Protocol
    # +PROTOCOL_ANY+::  IFD determines Protocol
    
    def initialize context, reader_name=nil, share_mode=SHARE_EXCLUSIVE, preferred_protocols=PROTOCOL_ANY
      @context     = context
      @reader_name = reader_name || @context.list_readers(nil)[0] 
      @share_mode  = share_mode
      @preferred_protocols = preferred_protocols
      super(@context, @reader_name, @share_mode, @preferred_protocols)
    end

    # Terminates the connection made using Card#new. The Card object is
    # invalid afterwards.
    #
    # Wraps +SCardDisconnect+ in PC/SC.
    #
    # === Parameters
    # ==== Optional
    # +disposition+:: action to be taken on the card inside the reader; use one of the <tt>DISPOSITION_...</tt> constants, defaults to +DISPOSITION_UNPOWER+
    #
    # ---
    #
    # === Values for +disposition+
    #
    # +DISPOSITION_LEAVE+:: Do nothing on close.
    # +DISPOSITION_RESET+:: (Warm) Reset on close.
    # +DISPOSITION_UNPOWER+:: Power down on close.
    # +DISPOSITION_EJECT+:: Eject on close.

    def disconnect disposition = DISPOSITION_UNPOWER
      super
    end
    
    # Reestablishes a connection to a reader that was previously
    # connected to using Card#new.
    #
    # Wraps +SCardReconnect+ in PC/SC.
    #
    # === Parameters
    # ==== Optional
    # +share_mode+:: whether a shared or exclusive lock will be requested on the reader;  use one of the <tt>SHARE_...</tt> constants, defaults to the value previously used in Card#new
    # +preferred_protocols+:: desired protocol; use one of the <tt>PROTOCOL_...</tt> constants, defaults to the value previously used in Card#new    
    # +initialization+:: action to be taken on the card inside the reader; use one of the <tt>INITIALIZATION_...</tt> constants; defaults to +INITIALIZATION_RESET+ which is a warm reset.
    #
    # ---
    #
    # === Values for +share_mode+
    #
    # +SHARE_EXCLUSIVE+:: This application will NOT allow others to share the reader 
    # +SHARE_SHARED+::    This application will allow others to share the reader. 
    # +SHARE_DIRECT+::    Direct control of the reader, even without a card, may be used to send control commands to the reader without a card inserted.
    #
    # === Values for +preferred_protocols+
    #
    # <tt>PROTOCOL_T0</tt>::   T=0 Protocol
    # <tt>PROTOCOL_T1</tt>::   T=1 Protocol
    # <tt>PROTOCOL_T15</tt>::  T=15 Protocol
    # +PROTOCOL_RAW+::  Raw Protocol
    # +PROTOCOL_ANY+::  IFD determines Protocol
    #
    # === Values for +initialization+
    #
    # +INITIALIZATION_LEAVE+:: 	  Do nothing
    # +INITIALIZATION_RESET+:: 	  Reset the card (warm reset)
    # +INITIALIZATION_UNPOWER+:: 	Unpower the card (cold reset)
    # +INITIALIZATION_EJECT+:: 	  Eject the card
    # 

    
    def reconnect share_mode=nil, preferred_protocols=nil, initialization=INITIALIZATION_RESET
      share_mode ||= @share_mode
      @share_mode = share_mode
      
      preferred_protocols ||= @preferred_protocols
      @preferred_protocols = preferred_protocols

      super(@share_mode, @preferred_protocols, initialization)  
    end
   
    # Retrieves the current status of the smartcard and packages it up
    # in a nice hash for you.
    #
    # Wraps +SCardStatus+ in PC/SC.
    #
    # === Returns
    #
    # +Hash+ with the following keys
    #
    # <tt>:state</tt>:: reader/card status, bitfield with bits defined as <tt>STATUS_...</tt> constants
    # <tt>:protocol</tt>::  the protocol established with the card; check against </tt>PROTOCOL_...</tt> constants
    # <tt>:atr</tt>:: the card's ATR bytes
    # <tt>:reader_names</tt>:: array of Strings containing all the names of the reader
    #
    # ---
    # === Relevant +STATUS+ Constants
    #
    # +STATE_UNAWARE+::       App wants status.
    # +STATE_IGNORE+::        Ignore this reader.
    # +STATE_CHANGED+::       State has changed.
    # +STATE_UNKNOWN+::       Reader unknown.
    # +STATE_UNAVAILABLE+::   Status unavailable.
    # +STATE_EMPTY+::         Card removed.
    # +STATE_PRESENT+::       Card inserted.
    # +STATE_ATRMATCH+::      ATR matches card.
    # +STATE_EXCLUSIVE+::     Exclusive Mode.
    # +STATE_INUSE+::         Shared Mode.
    # +STATE_MUTE+::          Unresponsive card. 
    #
    # === Relevant +PROTOCOL+ Constants
    #
    # <tt>PROTOCOL_T0</tt>::   T=0 Protocol
    # <tt>PROTOCOL_T1</tt>::   T=1 Protocol
    # <tt>PROTOCOL_T15</tt>::  T=15 Protocol
    # +PROTOCOL_RAW+::         Raw Protocol

    def status
      super 
    end

    # Returns the ATR of the card.
    def atr
      status[:atr]
    end
    

    

    # Ends a previously begun transaction. The calling application must
    # be the owner of the transaction or an error will occur.
    #
    # Wraps +SCardEndTransaction+ in PC/SC
    #
    # === Parameters
    # ==== Optional
    #
    # +disposition+::  action to be taken on the card inside the reader; use one of the +DISPOSITION_...+ constants, defaults to DISPOSITION_LEAVE
#    def end_transaction disposition=DISPOSITION_LEAVE
#      super(disposition)
#    end
    
    
    
        
  
    # Executes the provided block of code within a transaction context,
    # The optional +disposition+ parameter (default: +DISPOSITION_LEAVE+)
    # determines the action take on the card upon ending the
    # transaction. 
    #
    # === Values for +disposition+
    #
    # +DISPOSITION_LEAVE+:: Do nothing on close.
    # +DISPOSITION_RESET+:: (Warm) Reset on close.
    # +DISPOSITION_UNPOWER+:: Power down on close.
    # +DISPOSITION_EJECT+:: Eject on close.
     
    def transaction disposition=DISPOSITION_LEAVE
      self.begin_transaction
      yield self
      self.end_transaction(disposition)
    end
    
    # Sends an APDU to the smart card, and returns the card's response to the
    # APDU. 
    #
    # Wraps +SCardTransmit+ in PC/SC.
    # 
    # The bytes in the card's response are returned wrapped in a string.
    # (don't complain, it's a low-level API)
    # 
    # ===Parameters
    # ====Required
    # +send_data+ :: APDU data to be sent to the card. 
    # ====Optional
    # +send_io_request+:: <tt>IoRequest</tt> instance indicating the send protocol; you should use one of the <tt>IOREQUEST_...</tt>  constants, default is the IO Request corresponding to the protocol of the card.
    # +recv_io_request+::	<tt>IoRequest</tt> instance receving information about the recv protocol; you can use the result of <tt>IoRequest#new</tt> or just leave this parameter out, as it serves no discernable purpose.
    #
    # ---
    #
    # === Values for +send_io_request+
    #
    # <tt>IOREQUEST_T0</tt>:: IoRequest for transmitting using the T=0 protocol.
    # <tt>IOREQUEST_T1</tt>:: IoRequest for transmitting using the T=1 protocol.
    # +IOREQUEST_RAW+:: IoRequest for transmitting using the RAW protocol. 
    
    
    def transmit send_data, send_io_request=nil, recv_io_request=nil
            send_io_request ||= begin 
                                  protocol = status[:protocol] 
                                  case protocol 
                                  when PROTOCOL_T0:
                                    IOREQUEST_T0
                                  when PROTOCOL_T1:
                                    IOREQUEST_T1 
                                  when PROTOCOL_RAW: 
                                    IOREQUEST_RAW 
                                  else
                                    raise "weird protocol: #{protocol}"
                                  end 
                                end # send_io_request

      recv_io_request ||= Smartcard::PCSC::FFI::IoRequest.new
      super(send_data, send_io_request, recv_io_request)
    end 
    
    class << self

      # Utility method provided to avoid all the work of dealing with
      # +Context+, etc. in the simple (and common) case where you only 
      # want to deal with a single reader and want to use the protocol
      # determined by the card and reader.
      #
      # This method establishes a new context, connects to the first
      # reader, yields the connected card to the block provided to this
      # method and disconnects the card and context once the block is
      # finished executing.
      #
      # If an exception is thrown in the provided block, card and
      # context are disconnected, but the exception is still passed on
      # to the caller.
      #
      # In case the default behaviour (first reader, any protocol, etc.)
      # is not desirable, it's possible to pass in a hash of options to
      # override the defaults.
      #
      # === Usage
      # 
      #   # send cla=00 ins=00 p1=00 p2=00 to card
      #   Card.card {|card|
      #     resp = card.transmit("\x00\x00\x00\x00")
      #   }
      #
      #   # The same, only set PREFERRED_PROTOCOLS to t=0 and shared
      #   # access and using an alias for +Card.card+
      #   Card.connect(:preferred_protocols => PROTOCOL_T0,
      #                :share_mode          => SHARE_SHARED) { |c|
      #      resp = c.transmit("\x00\x00\x00\x00")
      #   }
      #
      # === Option Parameters
      #
      # +scope+:: defaults to +SCOPE_SYSTEM+
      # +reader_name+:: default is the first reader returned by +Context.list_readers+
      # +share_mode+:: defaults to +SHARE_EXCLUSIVE+
      # +preferred_protocols+:: defaults to +PROTOCOL_ANY+
      # +disposition+:: what to do after disconnecting, default +DISPOSITION_UNPOWER+
      #
      # ---
      #
      # === Values for +scope+
      #     * SCOPE_USER
      #     * SCOPE_TERMINAL
      #     * SCOPE_SYSTEM  
      #     
      # === Values for +share_mode+
      #
      # +SHARE_EXCLUSIVE+:: This application will NOT allow others to share the reader 
      # +SHARE_SHARED+::    This application will allow others to share the reader. 
      # +SHARE_DIRECT+::    Direct control of the reader, even without a card, may be used to send control commands to the reader without a card inserted.
      #
      # === Values for +preferred_protocols+
      #
      # <tt>PROTOCOL_T0</tt>::   T=0 Protocol
      # <tt>PROTOCOL_T1</tt>::   T=1 Protocol
      # <tt>PROTOCOL_T15</tt>::  T=15 Protocol
      # +PROTOCOL_RAW+::  Raw Protocol
      # +PROTOCOL_ANY+::  IFD determines Protocol
      #
      # === Values for +disposition+
      #
      # +DISPOSITION_LEAVE+:: Do nothing on close.
      # +DISPOSITION_RESET+:: (Warm) Reset on close.
      # +DISPOSITION_UNPOWER+:: Power down on close.
      # +DISPOSITION_EJECT+:: Eject on close.

      def card options = {}
        scope                = options[:scope]                || SCOPE_SYSTEM 
        Context.context(scope) { |context|
  
          reader_name        = options[:reader_name]          || context.list_readers(nil)[0]
          share_mode         = options[:share_mode]           || SHARE_EXCLUSIVE
          preferred_protocols= options[:preferred_protocols]  || PROTOCOL_ANY
          disposition        = options[:disposition]          || DISPOSITION_UNPOWER
    
          card = nil
    
          begin
            card = self.new(context, reader_name, share_mode, preferred_protocols)
            yield card
          ensure
            card.disconnect(disposition) if card
          end
        }
      end

      # +connect+ is an alias for Card.card to avoid having to type
      # things like:
      #
      #     Card.card{|card|
      #        # more card code here.
      #     }
      #
      # Instead, you can type: 
      #
      #     Card.connect {|sc|
      #       # more code 
      #       # MUCH nicer ... :)
      #     }
      alias_method :connect, :card
    end
  end
end
end

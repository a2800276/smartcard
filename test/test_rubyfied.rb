require 'test/unit'
require 'smartcard'

class RubyfiedTest < Test::Unit::TestCase

  include Smartcard::PCSC
  def initialize test_method_name
    super
    begin
      ctx = Context.new
      ctx.release
    rescue
      puts $!
      puts "-------------------------------------------------------------------------"
      puts "CURRENTLY TESTS ARE ONLY POSSIBLE WITH PLUGGED-IN READER/RUNNING SERVICE!"
      puts "Make sure your reader is plugged in!"
      puts "You can set the environment variable TEST_NO_CARD to simulate a card"
      puts "using a mock card/context"
      puts "-------------------------------------------------------------------------"
      exit
    end
    begin
      unless @@card_check_performed ||= false
        @@card_check_performed = true
        Card.card{}
        @@no_card_in_reader = false
      end
    rescue
      puts $!
      puts "-------------------------------------------------------------------------"
      puts "YOU SEEM NOT TO HAVE A CARD IN THE READER"
      puts "We will skip a number of tests."
      puts "You can set the environment variable TEST_NO_CARD to simulate a card"
      puts "using a mock card/context"
      puts "-------------------------------------------------------------------------"
      @@no_card_in_reader = true
    end
  end

  def teardown    
  end

  def test_basics
    # check all classes we expect are there
    assert(Smartcard::PCSC::Card)
    assert(Smartcard::PCSC::Card.superclass == Smartcard::PCSC::FFI::Card)

    assert(Smartcard::PCSC::Context)
    assert(Smartcard::PCSC::Context.superclass == Smartcard::PCSC::FFI::Context)

  end

  def test_context
    assert_raises(Smartcard::PCSC::PcscException) {
      Context.new(100000)
    }
    ctx = Context.new
    assert_equal(SCOPE_SYSTEM, ctx.scope)
    assert(ctx.is_valid)
    assert_nothing_thrown {
      ctx.list_readers
    }
    ctx.release
    assert(!ctx.is_valid)
  end

  def test_context_with_block
    Context.context { |ctx|
      assert(ctx.is_valid)
      assert_equal(SCOPE_SYSTEM, ctx.scope)
    }
    assert_raises(Smartcard::PCSC::PcscException) {
      Context.context(100000) {|ctx|
      }
    }

    r = Context.context {|ctx|
      ctx.list_readers
    }
    assert( Array === r )
  end
  
  def test_card
    return if @@no_card_in_reader
    Context.context {|c|
      card = nil
      begin
        card = Card.new(c)
        assert_equal(c, card.context)
        assert_equal(c.list_readers[0], card.reader_name)
        assert_equal(SHARE_EXCLUSIVE, card.share_mode)
      ensure
        card.disconnect if card
      end
    }
  end
  def test_card_with_block
    return if @@no_card_in_reader
    assert_nothing_thrown {
      Card.card { |card|
        resp = card.transmit("\x00\x00\x00\x00")
        assert_equal("\x6d\x00", resp)  # is this a valid assumption?
      }
    }

    assert_nothing_thrown {
      Card.card {|c|
        c.transaction {
          resp = c.transmit("\x00\x00\x00\x00")
          assert_equal("\x6d\x00", resp)  # is this a valid assumption?
        }
      }
    }
    
    assert_nothing_thrown {
      Card.connect( :preferred_protocols => PROTOCOL_T0,
                    :share_mode => SHARE_SHARED) { |c|
         resp = c.transmit("\x00\x00\x00\x00")
         assert_equal("\x6d\x00", resp)  # is this a valid assumption?
      }
    }
    

  end

  def test_card_reconnect 
    return if @@no_card_in_reader
    [SHARE_EXCLUSIVE, SHARE_SHARED, SHARE_DIRECT].each { |share_mode|
      Card.connect(:share_mode=>share_mode) { |c|
        c.reconnect
        assert_equal(share_mode, c.share_mode)
        unless share_mode==SHARE_EXCLUSIVE
          c.reconnect(SHARE_EXCLUSIVE)
          assert_equal(SHARE_EXCLUSIVE, c.share_mode)
        end

        
      }
  
    }
  end
end

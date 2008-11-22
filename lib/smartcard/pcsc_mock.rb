# This module is for testing purposed only.
# Still need the compiled module for all the constants ...
require 'smartcard/pcsc'
module Smartcard
module PCSC
module FFI

        STDERR.puts "------------------------------------------------------------------------"
        STDERR.puts "-- This implementation of module PCSC::FFI is for testing purposed    --"
        STDERR.puts "-- only. It's sole reason for existance is to NOT use an actual card. --"
        STDERR.puts "-- You should NEVER see this message unless you are running unit      --"
        STDERR.puts "-- tests with no card or reader and have set the environment variable --"
        STDERR.puts "-- TEST_NO_CARD. If you see this message in ANY other situation there --"
        STDERR.puts "-- is something VERY VERY WRONG!                                         --"
        STDERR.puts "------------------------------------------------------------------------"
        
        class Card
          def initialize ctx, reader_name, share_mode, preferred_protocols
          end

          def disconnect disposition
          end
          
          def set_attribute arg0, arg1
          end
          
          def last_error 
          end

          def reconnect share, pref, ini
          end

          def transmit send, io_s, io_r
           "\x6d\x00" 
          end

          def begin_transaction 
          end
          
          def control  arg0, arg1, arg2
          end
          
          def status 
            {
              :state => :fake,
              :protocol => PROTOCOL_T0,
              :atr => "FAKE",
              :reader_names => ["fake1", "fake2"] 
            }   
          end
          
          def end_transaction  arg0
          end
          
          def get_attribute  arg0
          end
                  
        end # Card
        class Context
          def initialize scope
            @valid = true
          end
          
          def list_reader_groups 
            [] 
          end
          
          def list_readers  arg0
            ["test_reader"]  
          end
          
          def cancel 
          end

          def release 
            @valid = false 
          end
          
          def get_status_change  arg0, arg1
          end
          
          def is_valid 
            @valid 
          end
          
          def last_error 
          end
                
        end
end # FFI
end # PCSC
end # Smartcard

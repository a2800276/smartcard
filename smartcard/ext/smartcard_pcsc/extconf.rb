require 'mkmf'

$CFLAGS ||= ''
$LDFLAGS ||= ''

pcsc_defines = []

if RUBY_PLATFORM =~ /darwin/
  $LDFLAGS += ' -framework PCSC'
  darwin_version = `uname -r`
  if darwin_version =~ /^8./
    pcsc_defines.push 'RB_SMARTCARD_OSX_TIGER_HACK'
  end
elsif RUBY_PLATFORM =~ /win/
  have_library('winscard')
else
  # pcsc is retarded and uses stuff like '#include <wintypes.h>'
  $CFLAGS += ' -I /usr/include/PCSC -I /usr/local/include/pcsc'
  have_library('pcsclite')
end

pcsc_headers = []
['wintypes.h', 'reader.h', 'winscard.h', 'pcsclite.h'].each do |header|
  ['', 'PCSC/', './pcsc_surrogate_'].each do |path_prefix|
    if have_header(path_prefix + header)
      pcsc_headers.push((path_prefix[0,1] == '.') ? "\"#{path_prefix + header}\"" : "<#{path_prefix + header}>")
      break
    end
  end
end

File.open('pcsc_autogen.h', 'w') do |f|
  pcsc_defines.each { |d| f.write "\#define #{d}\n" }
  pcsc_headers.each { |h| f.write "\#include #{h}\n" }
end 

create_makefile('smartcard/pcsc')

def win32_hack(mf_name)
  # evil, evil, evil -- hack the makefile to embed the manifest in the extension dll
  make_contents = File.open(mf_name, 'r') { |f| f.read }
  make_rules = make_contents.split(/(\n|\r)(\n|\r)+/)
  new_make_rules = make_rules.map do |rule|
    if rule =~ /^\$\(DLLIB\)\:/
      rule + "\n\tmt.exe -manifest $(@).manifest -outputresource:$(@);2"
    else
      rule
    end
  end
  File.open(mf_name, 'w') { |f| f.write new_make_rules.join("\n\n")}
end

case RUBY_PLATFORM
when /darwin/
when /win/
  win32_hack 'Makefile'
end

%w(gui api).each {|x| require_relative x }
map('/') { run Profistory::GUI }
map('/api') { run Profistory::API }

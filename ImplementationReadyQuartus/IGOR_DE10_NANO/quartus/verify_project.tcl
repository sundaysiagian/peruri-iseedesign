package require ::quartus::project
project_open igor
puts "VERIFIED_REVISION igor"
puts "VERIFIED_TOP [get_global_assignment -name TOP_LEVEL_ENTITY]"
puts "VERIFIED_DEVICE [get_global_assignment -name DEVICE]"
project_close

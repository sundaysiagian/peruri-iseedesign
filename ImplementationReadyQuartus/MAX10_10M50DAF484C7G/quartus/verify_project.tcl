package require ::quartus::project
project_open igor_max10
puts "VERIFIED_REVISION igor_max10"
puts "VERIFIED_TOP [get_global_assignment -name TOP_LEVEL_ENTITY]"
puts "VERIFIED_DEVICE [get_global_assignment -name DEVICE]"
project_close

puts "GTK_VERSION [gtkwave::getDumpType]"
puts "LOADED [gtkwave::getDumpFileName]"
set wanted {key rx tx rv rb re received checks error_count}
set signals [list]
foreach name $wanted {
 for {set i 0} {$i < [gtkwave::getNumFacs]} {incr i} {
  set fac [gtkwave::getFacName $i]
  set base [lindex [split $fac {[}] 0]
  if {$base eq "igor_uart_115200_tb.$name"} {lappend signals $fac; break}
 }
}
puts "ADDED [gtkwave::addSignalsFromList $signals] $signals"
puts "DECIMAL_COMMANDS [info commands gtkwave::*Decimal*]"
catch {gtkwave::/Edit/Highlight_All}
catch {gtkwave::/Edit/Data_Format/Decimal}
catch {gtkwave::/Edit/UnHighlight_All}
gtkwave::setZoomRangeTimes 0 1420000000
gtkwave::setMarker 1381200000
puts "CONFIGURED 04_uart"

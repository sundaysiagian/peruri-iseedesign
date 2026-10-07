puts "GTK_VERSION [gtkwave::getDumpType]"
puts "LOADED [gtkwave::getDumpFileName]"
set wanted {start busy done enable estop protective fault vcmd wcmd error_count}
set signals [list]
foreach name $wanted {
 for {set i 0} {$i < [gtkwave::getNumFacs]} {incr i} {
  set fac [gtkwave::getFacName $i]
  set base [lindex [split $fac {[}] 0]
  if {$base eq "igor_top_tb.$name"} {lappend signals $fac; break}
 }
}
puts "ADDED [gtkwave::addSignalsFromList $signals] $signals"
puts "DECIMAL_COMMANDS [info commands gtkwave::*Decimal*]"
catch {gtkwave::/Edit/Highlight_All}
catch {gtkwave::/Edit/Data_Format/Decimal}
catch {gtkwave::/Edit/UnHighlight_All}
gtkwave::setZoomRangeTimes 6718600000 6718800000
gtkwave::setMarker 6718670000
puts "CONFIGURED 02_dwa_fault"

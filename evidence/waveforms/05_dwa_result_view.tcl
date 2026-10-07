puts "GTK_VERSION [gtkwave::getDumpType]"
puts "LOADED [gtkwave::getDumpFileName]"
set wanted {rst_n start busy done enable index score latency fault vcmd wcmd error_count}
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
gtkwave::setZoomRangeTimes 486600000 486850000
gtkwave::setMarker 486680000
puts "CONFIGURED 05_dwa_result"

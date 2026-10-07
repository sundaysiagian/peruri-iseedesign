load_package project
if {![project_exists igor]} {project_new igor -revision igor} else {project_open igor}
source igor.qsf
export_assignments
project_close

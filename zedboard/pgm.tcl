proc pgm_wrapper {proj_dir proj_name out_bit} {
  open_project $proj_dir/$proj_name.xpr 
  open_hw
  connect_hw_server
  open_hw_target
  set_property PROGRAM.FILE $out_bit [get_hw_devices xc7z020_1] 
  current_hw_device [get_hw_devices xc7z020_1]
  refresh_hw_device -update_hw_probes false [lindex [get_hw_devices xc7z020_1] 0]
  close_project
}

catch { close_sim -force }
reset_simulation -simset sim_1 -mode behavioral
reset_target simulation [get_files *.bd]
update_ip_catalog -rebuild -scan_changes
upgrade_ip [get_ips *]
generate_target simulation [get_files *.bd]
launch_simulation

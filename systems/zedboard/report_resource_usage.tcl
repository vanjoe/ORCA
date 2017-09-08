proc report_resources {proj_dir proj_name output_file} {
	open_project $proj_dir/$proj_name.xpr
	open_run impl_1
	report_utilization -hierarchical -file $output_file
}

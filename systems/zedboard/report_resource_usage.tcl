proc report_resources {proj_dir proj_name} {
	open_project $proj_dir/$proj_name.xpr
	open_run impl_1
	report_utilization -hierarchical -file resource_utilization.rpt
}

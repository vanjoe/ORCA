## Documentation for GitHub Release 
To export the 4 GitHub projects into a new directory, execute the `release.py` python
script. This script removes certain HDL files that are not publicly available, and 
stubs certain entities so the projects will still build without releasing any IP.

The scripts also clean the associated project files to ensure that the projects
continue to build correctly after the project has been pruned.

The script release.py contains a list of hdl files to delete, hdl files to stub,
and a list of projects to export. The default directory for export is ~/orca_to_push.
After the script completes, ~/orca_to_push will contain the rtl directory, as well as 
the systems directory containing the ice40ultra, zedboard, sf2plus, and de2-112 directories.
In the future, some of these should be passable as parameters to the script.

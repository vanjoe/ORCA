## Documentation for GitHub Release 

To export the GitHub projects into a new directory, execute the `release.py` python
script. This script removes certain HDL files that are not publicly available, and 
stubs certain entities so the projects will still build without releasing any IP.

The scripts also clean the associated project files to ensure that the projects
continue to build correctly after the project has been pruned.

The script release.py contains a list of hdl files to delete, hdl files to stub,
and a list of projects to export. The default directory for export is `github_orca`.
After the script completes, `orca_to_push` will contain the ip directory, the
systems directory with whatever systems are selected (see below), and the
software directory with appropriate software.

## Passing parameters to `release.py`

`release.py` will include the file `config.py` when run.  The default release is
for GitHub, but additional `config_*.py` scripts may be maintained for other
releases (e.g. `lucid_config.py` for Lucid Vision) and can be copied/symlinked
to `config.py`.

Inside `config.py` the following variables can be set:

### include_lve

Set to True or False to include or exclude LVE.  Default False.

### include_caches

Set to True or False to include or exclude caches.  Default False.

### systems_to_copy

A list of systems to include in the release.  Variables are are defined in
`release.py` for each system (`ice40ultra_system`, `sf2plus_system`, etc.).
Default `['de2_115_system', 'zedboard_system', 'sim_system']`.

### destination_repo

The directory the release will be copied to.  Default `orca_to_push`.

### upstream_repo

The upstream repo to point the release at (will not be pushed).  Default
`https://github.com/VectorBlox/orca`.

### submodules

A list of submodules to add.  Could get automated, but for now you need to put
in a tuple of submodules that will be added to the repo.  Default
`[('software/riscv-tests', 'https://github.com/riscv/riscv-tests software/riscv-tests/', '6a1a38d')]`.

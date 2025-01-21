# get IDF version for comparison
set(idf_version "${IDF_VERSION_MAJOR}.${IDF_VERSION_MINOR}")

# set conversion sources
set(srcs
    sources/shell.c
)

set(include_dirs 
    ./include
)

list(APPEND srcs
    sources/shell.c
)

idf_component_register(
  SRCS ${srcs}
  INCLUDE_DIRS ${include_dirs}
  REQUIRES console 
)

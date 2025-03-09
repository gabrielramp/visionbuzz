# get IDF version for comparison
set(idf_version "${IDF_VERSION_MAJOR}.${IDF_VERSION_MINOR}")

# set conversion sources
set(srcs
    sources/ipc.c
)

set(include_dirs 
    ./include
)

list(APPEND srcs
    sources/ipc.c
)

idf_component_register(
  SRCS ${srcs}
  INCLUDE_DIRS ${include_dirs}
  REQUIRES esp_driver_uart driver wifi camera
)

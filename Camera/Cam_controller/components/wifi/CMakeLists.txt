# get IDF version for comparison
set(idf_version "${IDF_VERSION_MAJOR}.${IDF_VERSION_MINOR}")

# set conversion sources
set(srcs
    sources/wifi.c
)

set(include_dirs 
    ./include
)

list(APPEND srcs
    sources/wifi.c
)

idf_component_register(
  SRCS ${srcs}
  INCLUDE_DIRS ${include_dirs}
  REQUIRES nvs_flash esp_wifi wpa_supplicant esp_http_client camera BLE
)

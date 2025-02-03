idf_component_register(SRCS "main.c"
                    INCLUDE_DIRS "../components/BLE/include" 
                    REQUIRES bt nvs_flash spi_flash LED BLE)
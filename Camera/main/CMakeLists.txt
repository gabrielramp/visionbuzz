idf_component_register(SRCS "main.c"
                    INCLUDE_DIRS "../components/esp32-camera/driver/include" 
                                 "../components/camera/include"
                                 "../components/BLE/include" 
                                 "../components/wifi/include"
                                 "../components/shell/include"
                    REQUIRES bt nvs_flash spi_flash LED BLE wifi)
/*
 * SPDX-FileCopyrightText: 2010-2022 Espressif Systems (Shanghai) CO LTD
 *
 * SPDX-License-Identifier: CC0-1.0
 */

#include <stdio.h>
#include <inttypes.h>
#include "sdkconfig.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_chip_info.h"
#include "esp_flash.h"
#include "esp_system.h"
#include "driver/uart.h"
#include "esp_camera.h"
// #include "esp_spiffs.h"

#include "led.h"
#include "ble.h"
#include "wifi.h"
#include "camera.h"
#include "shell.h"

void app_main(void)
{
    printf("woah look my code is running\n");
    fflush(stdout);

    // shell_init();

    /*
    // esp_err_t err = camera_init();

    if (err)
    {
        printf("Camera initialization error - %d", err);
        fflush(stdout);
    }

    led_init(14);
    led_off(14);*/

    wifi_init();

    // wifi_connect();
    ble_init();
    
    // wifi_set_identity("au907615");
    // wifi_set_username("au907615");
    // wifi_set_password("!!11qqQQ!!11qqQQ!!11qqQQ");
    // wifi_set_ssid("UCF_WPA2");
    // wifi_init();
    /*
    gpio_config_t gpio_cfg_4 = {
        .intr_type = GPIO_INTR_DISABLE,
        .mode = GPIO_MODE_OUTPUT,
        .pin_bit_mask = (1 << 4),
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .pull_up_en = GPIO_PULLUP_DISABLE
    };*/
    
    /*

    gpio_config_t gpio_cfg_15 = {
        .intr_type = GPIO_INTR_DISABLE,
        .mode = GPIO_MODE_INPUT,
        .pin_bit_mask = (1 << 15),
        .pull_down_en = GPIO_PULLDOWN_ENABLE,
        .pull_up_en = GPIO_PULLUP_DISABLE
    };

    gpio_config(&gpio_cfg_4);
    gpio_config(&gpio_cfg_15);

    uart_driver_delete(UART_NUM_0);
    uart_driver_install(UART_NUM_0, 2048, 2048, 0, NULL, 0);
    uart_param_config(UART_NUM_0, &uart_cfg);
    */
    
    /*
    esp_err_t err = esp_camera_init(&camera_config);

    if (err)
    {
        printf("Error - camera init (err %d)", err);
        fflush(stdout);
        return;
    }*/

    led_task_create();
    // vTaskStartScheduler();
    
    printf("Initialization successful\n");
    fflush(stdout);

    // vTaskStartScheduler();
}

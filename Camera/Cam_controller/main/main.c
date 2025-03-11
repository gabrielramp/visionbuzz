/*
 * SPDX-FileCopyrightText: 2010-2022 Espressif Systems (Shanghai) CO LTD
 *
 * SPDX-License-Identifier: CC0-1.0
 */

#include <stdio.h>
#include <inttypes.h>
#include "esp_log.h"
#include "sdkconfig.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_chip_info.h"
#include "esp_flash.h"
#include "esp_system.h"
#include "driver/uart.h"
#include "esp_camera.h"
// #include "esp_spiffs.h"

#include "wifi.h"
#include "camera.h"
#include "ipc.h"

void ipc_rx_cb(uint8_t *msg, int len, uint8_t msg_id)
{
    printf("Msg received: %d bytes [%.*s]\n", len, len, msg);
    fflush(stdout);

    ipc_handle_msg(msg, len, msg_id);
}

void app_main(void)
{
    printf("woah look my code is running\n");
    fflush(stdout);

    ipc_init(12, 13, ipc_rx_cb);

    vTaskDelay(pdMS_TO_TICKS(2000));

    wifi_init();
    
    vTaskDelay(pdMS_TO_TICKS(2000));
    
    esp_err_t err = camera_init();

    if (err)
    {
        printf("Camera init failed - %d", err);
    }
    else
    {
        printf("Camera initialized");
    }

    printf("Initialization successful\n");
    fflush(stdout);

    vTaskDelay(pdMS_TO_TICKS(500));

    // wifi_set_username((uint8_t *)"au907615", 8);
    // wifi_set_password((uint8_t *)"!!11qqQQ!!11qqQQ!!11qqQQ", 24);
    // wifi_set_identity((uint8_t *)"au907615", 8);
    // wifi_set_ssid((uint8_t *)"UCF_WPA2", 8);

    // wifi_connect();

    while (!wifi_is_ready())
    {
        wifi_print_credentials();
        vTaskDelay(pdMS_TO_TICKS(5000));
    }

    // wifi_set_api_username((uint8_t *)"test7", 5, 0);
    // wifi_set_api_password((uint8_t *)"test7", 5, 0);

    // wifi_api_login();
    
    vTaskDelay(pdMS_TO_TICKS(2000));

    camera_fb_t *img;

    while (true)
    {
        // wifi_print_credentials();

        if (wifi_is_ready() && api_is_ready())
        {
            img = camera_get_img();
    
            wifi_send_img(img);
    
            camera_release_img(img);
            
            vTaskDelay(pdMS_TO_TICKS(100));
        }
        else
        {
            vTaskDelay(pdMS_TO_TICKS(5000));
        }
    }

    wifi_disconnect();

    // vTaskStartScheduler();
}

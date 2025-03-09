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

    wifi_init();
    vTaskDelay(pdMS_TO_TICKS(2000));

    /* esp_err_t err = camera_init();

    if (err)
    {
        printf("Camera init failed - %d", err);
    }
    else
    {
        printf("Camera initialized");
    }
        */
    
    fflush(stdout);

    vTaskDelay(pdMS_TO_TICKS(500));
    
    ipc_wifi_set_password((uint8_t *) "!!11qqQQ!!11qqQQ!!11qqQQ", 24);
    ipc_wifi_set_username((uint8_t *) "au907615", 8);
    ipc_wifi_set_identity((uint8_t *) "au907615", 8);
    ipc_wifi_set_ssid((uint8_t *) "UCF_WPA2", 8);
    ipc_api_set_username((uint8_t *) "test6", 5);
    ipc_api_set_password((uint8_t *) "test6", 5);

    vTaskDelay(pdMS_TO_TICKS(500));

    ipc_wifi_connect();

    while (!wifi_is_ready())
    {
        vTaskDelay(pdMS_TO_TICKS(1000));
    }

    wifi_api_login();

    while (true)
    {
        vTaskDelay(pdMS_TO_TICKS(2000));
    }

    printf("Initialization successful\n");
    fflush(stdout);

    camera_fb_t *img;

    vTaskDelay(pdMS_TO_TICKS(1000));

    while (true)
    {
        if (wifi_is_ready())
        {
            img = camera_get_img();
    
            printf("Corners: 0x%x\n", img->buf[img->len/2]);
            fflush(stdout);
    
            wifi_send_img(img);
    
            vTaskDelay(pdMS_TO_TICKS(100));
    
            camera_release_img(img);
            
            vTaskDelay(pdMS_TO_TICKS(1000));
        }
        else
        {
            vTaskDelay(pdMS_TO_TICKS(2000));
        }
    }

    // vTaskStartScheduler();
}

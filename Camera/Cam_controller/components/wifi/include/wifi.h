#ifndef WIFI_H
#define WIFI_H

#include <stdio.h>
#include <stdbool.h>
#include "esp_mac.h"
#include "esp_err.h"
#include "esp_camera.h"

#define WIFI_CREDENTIAL_MAX_LEN 32

#define WIFI_ERROR_CHECK(err, msg) \
    { \
    esp_err_t out = err;\
    if (out != ESP_OK) \
    { \
        printf("%s failed (error code %d)\n", msg, out); \
        fflush(stdout); \
        return out; \
    } \
    }

#define API_TOKEN_MAX_LEN 512

esp_err_t wifi_init(void);
esp_err_t wifi_set_identity(uint8_t *identity, uint8_t len, uint16_t offset);
esp_err_t wifi_set_username(uint8_t *username, uint8_t len, uint16_t offset);
esp_err_t wifi_set_password(uint8_t *password, uint8_t len, uint16_t offset);
esp_err_t wifi_set_ssid(uint8_t *ssid, uint8_t len, uint16_t offset);
esp_err_t wifi_set_api_username(uint8_t *api_username, uint8_t len, uint16_t offset);
esp_err_t wifi_set_api_password(uint8_t *api_password, uint8_t len, uint16_t offset);
esp_err_t wifi_set_api_token(uint8_t *token, uint8_t len, uint16_t offset);
esp_err_t wifi_set_api_token_len(uint16_t token_len);
esp_err_t wifi_api_login(void);
esp_err_t wifi_connect(void);
esp_err_t wifi_disconnect(void);
esp_err_t wifi_connect_cb(void);
esp_err_t wifi_send_img(camera_fb_t *img);
esp_err_t wifi_ping(void);
esp_err_t wifi_print_credentials(void);
bool wifi_is_ready(void);

#endif
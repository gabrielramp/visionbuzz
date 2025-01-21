#ifndef WIFI_H
#define WIFI_H

#include <stdio.h>
#include <stdbool.h>
#include "esp_mac.h"
#include "esp_err.h"

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

esp_err_t wifi_init(void);
esp_err_t wifi_set_identity(const char *identity);
esp_err_t wifi_set_username(const char *username);
esp_err_t wifi_set_password(const char *password);
esp_err_t wifi_set_ssid(const char *ssid);
esp_err_t wifi_connect_cb(void);
esp_err_t wifi_ping(void);
esp_err_t wifi_print_credentials(void);
char *wifi_identity_addr(void);
char *wifi_username_addr(void);
char *wifi_password_addr(void);
char *wifi_ssid_addr(void);
uint8_t *wifi_connect_addr(void);

#endif
#include "wifi.h"

#include <stdio.h>
#include <string.h>
#include <inttypes.h>
#include "sdkconfig.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/event_groups.h"
#include "esp_chip_info.h"
#include "esp_flash.h"
#include "esp_system.h"
#include "esp_wifi.h"
#include "esp_eap_client.h"
#include "nvs.h"
#include "nvs_flash.h"
#include "esp_log.h"
#include "esp_mac.h"
#include "esp_http_client.h"
#include "camera.h"

static char _ssid[WIFI_CREDENTIAL_MAX_LEN + 1];
static char _password[WIFI_CREDENTIAL_MAX_LEN + 1];
static char _identity[WIFI_CREDENTIAL_MAX_LEN + 1];
static char _username[WIFI_CREDENTIAL_MAX_LEN + 1];
static uint8_t _connect = 0;

static bool connected = false;

esp_err_t nvs_save_credentials(void)
{
    nvs_handle_t nvs_handle;

    printf("Saving credentials to NVS\n");
    fflush(stdout);

    esp_err_t err = nvs_open("wifi_cred", NVS_READWRITE, &nvs_handle);

    if (err)
    {
        printf("Error accessing NVS: %d\n", err);
        fflush(stdout);
        return err;
    }

    err = nvs_set_blob(nvs_handle, "ssid", (void *) _ssid, WIFI_CREDENTIAL_MAX_LEN);
    if (err) goto nvs_set_err;
    err = nvs_set_blob(nvs_handle, "username", (void *) _username, WIFI_CREDENTIAL_MAX_LEN);
    if (err) goto nvs_set_err;
    err = nvs_set_blob(nvs_handle, "identity", (void *) _identity, WIFI_CREDENTIAL_MAX_LEN);
    if (err) goto nvs_set_err;
    err = nvs_set_blob(nvs_handle, "password", (void *) _password, WIFI_CREDENTIAL_MAX_LEN);

nvs_set_err:

    if (err)
    {
        printf("NVS set blob err: %d", err);
        fflush(stdout);
    }

    err = nvs_commit(nvs_handle);

    if (err)
    {
        printf("NVS commit err: %d", err);
        fflush(stdout);
    }

    nvs_close(nvs_handle);

    return ESP_OK;
}

esp_err_t nvs_load_credentials(void)
{
    nvs_handle_t nvs_handle;

    printf("Loading credentials from NVS\n");
    fflush(stdout);

    esp_err_t err = nvs_open("wifi_cred", NVS_READWRITE, &nvs_handle);

    if (err)
    {
        printf("Error accessing NVS: %d\n", err);
        fflush(stdout);
        return err;
    }

    size_t length = WIFI_CREDENTIAL_MAX_LEN + 1;
    err = nvs_get_blob(nvs_handle, "ssid", (void *) _ssid, &length);
    if (err) goto nvs_set_err;

    length = WIFI_CREDENTIAL_MAX_LEN + 1;
    err = nvs_get_blob(nvs_handle, "username", (void *) _username, &length);
    if (err) goto nvs_set_err;

    length = WIFI_CREDENTIAL_MAX_LEN + 1;
    err = nvs_get_blob(nvs_handle, "identity", (void *) _identity, &length);
    if (err) goto nvs_set_err;

    length = WIFI_CREDENTIAL_MAX_LEN + 1;
    err = nvs_get_blob(nvs_handle, "password", (void *) _password, &length);

nvs_set_err:

    if (err)
    {
        printf("NVS get blob err: %d", err);
        fflush(stdout);
        return err;
    }

    err = nvs_commit(nvs_handle);

    if (err)
    {
        printf("NVS commit err: %d", err);
        fflush(stdout);
        return err;
    }

    nvs_close(nvs_handle);

    return ESP_OK;
}

static esp_err_t http_event_handler(esp_http_client_event_t *evt)
{
    printf("HTTP event id: %u\n", evt->event_id);
    fflush(stdout);

    switch(evt->event_id)
    {
        case HTTP_EVENT_ERROR:
            printf("HTTP ERROR\n");
            fflush(stdout);
            break;

        case HTTP_EVENT_ON_DATA:
            printf("HTTP data received:\n%.*s", evt->data_len, (char *) evt->data);
            break;

        default:
            break;
    }

    return ESP_OK;
}

static void ip_event_handler(void* event_handler_arg, esp_event_base_t event_base, int32_t event_id, void* event_data)
{
    printf("IP event id: %ld\n", event_id);
    fflush(stdout);

    switch(event_id)
    {
        case IP_EVENT_STA_GOT_IP:
            ip_event_got_ip_t *ip_event = (ip_event_got_ip_t *) event_data;
            printf("Got IP address: " IPSTR, IP2STR(&ip_event->ip_info.ip));
            fflush(stdout);
            // wifi_ping();
            break;

        case IP_EVENT_STA_LOST_IP:
            printf("Lost IP address");
            fflush(stdout);
            break;

        default:
            break;
    }
}

static void wifi_event_handler(void* event_handler_arg, esp_event_base_t event_base, int32_t event_id, void* event_data)
{
    printf("Wifi event id: %ld\n", event_id);
    fflush(stdout);

    switch (event_id)
    {
        case WIFI_EVENT_STA_START:
            printf("Wifi started\n");
            fflush(stdout);
            static wifi_config_t config;

            strcpy((char *) config.sta.ssid, _ssid);
            strcpy((char *) config.sta.password, _password);
            esp_wifi_set_config(WIFI_IF_STA, &config);

            if (_connect)
                esp_wifi_connect();
            
            break;

        case WIFI_EVENT_STA_DISCONNECTED:
            char ssid[33];
            wifi_event_sta_disconnected_t *data = (wifi_event_sta_disconnected_t *) event_data;
            strncpy(ssid, (const char *) data->ssid, data->ssid_len);
            ssid[data->ssid_len] = '\0';
            printf("disconnected from SSID \"%s\" - reason: %u\n", ssid, data->reason);
            fflush(stdout);

            connected = false;

            if (_connect)
                esp_wifi_connect();
            
            break;
    
        case WIFI_EVENT_STA_CONNECTED:
            printf("Wi-Fi connected!\n");
            fflush(stdout);

            connected = true;

            break;

    }
}

/**
 * Initialize the Wi-Fi stack. This sets the receiver to station mode and prepares
 * for connection.
 * 
 * @returns ESP_OK if successful, an ESP error code if not. 
 */
esp_err_t wifi_init(void)
{
    printf("Initializing Wi-Fi\n");
    fflush(stdout);

    memset(_ssid, 0, WIFI_CREDENTIAL_MAX_LEN + 1);
    memset(_password, 0, WIFI_CREDENTIAL_MAX_LEN + 1);
    memset(_identity, 0, WIFI_CREDENTIAL_MAX_LEN + 1);
    memset(_username, 0, WIFI_CREDENTIAL_MAX_LEN + 1);
    
    WIFI_ERROR_CHECK(nvs_flash_init(), "nvs_flash_init");

    esp_err_t err = nvs_load_credentials();

    wifi_print_credentials();

    if (err)
    {
        printf("Error loading Wifi credentials from NVS: %d\n", err);
        fflush(stdout);
        return err;
    }

    /*

    wifi_init_config_t init_config = WIFI_INIT_CONFIG_DEFAULT();

    WIFI_ERROR_CHECK(esp_wifi_init(&init_config), "esp_wifi_init");
    WIFI_ERROR_CHECK(esp_netif_init(), "esp_netif_init");
    WIFI_ERROR_CHECK(esp_wifi_set_storage(WIFI_STORAGE_RAM), "esp_wifi_set_storage");
    WIFI_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA), "esp_wifi_set_mode");
    WIFI_ERROR_CHECK(esp_wifi_set_protocol(WIFI_IF_STA, WIFI_PROTOCOL_11B | WIFI_PROTOCOL_11G | WIFI_PROTOCOL_11N), "esp_wifi_set_protocol");
    
    // Register EVent Handlers
    WIFI_ERROR_CHECK(esp_event_loop_create_default(), "esp_event_loop_create_default");
    esp_netif_create_default_wifi_sta();
    WIFI_ERROR_CHECK(esp_event_handler_instance_register(WIFI_EVENT, ESP_EVENT_ANY_ID, \
                     wifi_event_handler, NULL, NULL), "wifi_event_handler");
    WIFI_ERROR_CHECK(esp_event_handler_instance_register(IP_EVENT, ESP_EVENT_ANY_ID, \
                     ip_event_handler, NULL, NULL), "ip_event_handler");

    WIFI_ERROR_CHECK(esp_eap_client_set_ttls_phase2_method(ESP_EAP_TTLS_PHASE2_MSCHAPV2), "esp_eap_client_set_ttls_phase2_method");
    WIFI_ERROR_CHECK(esp_eap_client_use_default_cert_bundle(true), "esp_eap_client_use_default_cert_bundle");
    WIFI_ERROR_CHECK(esp_wifi_sta_enterprise_enable(), "esp_wifi_sta_enterprise_enable");

    WIFI_ERROR_CHECK(esp_wifi_start(), "wifi start");

    printf("Wi-Fi Successfully Initialized");
    fflush(stdout);

    */

    return ESP_OK;
}

/**
 * Set the identity used during PEAP/TTLS authentication
 * 
 * @param identity a null-terminated ascii string representation of the identity
 * 
 * @returns ESP_OK if successful, an ESP error code if not. 
 */
esp_err_t wifi_set_identity(const char *identity)
{
    strcpy(_identity, identity);
    WIFI_ERROR_CHECK(esp_eap_client_set_identity((const unsigned char *) identity, strlen(identity)), "esp_eap_client_set_identity");

    return ESP_OK;
}

/**
 * Set the username used during PEAP/TTLS authentication
 * 
 * @param username a null-terminated ascii string representation of the username
 * 
 * @returns ESP_OK if successful, an ESP error code if not. 
 */
esp_err_t wifi_set_username(const char *username)
{
    strcpy(_username, username);
    WIFI_ERROR_CHECK(esp_eap_client_set_username((const unsigned char *) username, strlen(username)), "esp_eap_client_set_username");

    return ESP_OK;
}

/**
 * Set the password used during PEAP/TTLS authentication
 * 
 * @param password a null-terminated ascii string representation of the password
 * 
 * @returns ESP_OK if successful, an ESP error code if not. 
 */
esp_err_t wifi_set_password(const char *password)
{
    strcpy(_password, password);
    WIFI_ERROR_CHECK(esp_eap_client_set_password((const unsigned char *) password, strlen(password)), "esp_eap_client_set_password");

    return ESP_OK;
}

/**
 * Set the SSID of the network to connect to
 * 
 * @param ssid a null-terminated ascii string representation of the SSID
 * 
 * @returns ESP_OK if successful, an ESP error code if not. 
 */
esp_err_t wifi_set_ssid(const char *ssid)
{
    strcpy(_ssid, ssid);
    return ESP_OK;
}

esp_err_t wifi_connect_cb(void)
{
    printf("connected: %d, _connect: %d", connected, _connect);
    fflush(stdout);

    nvs_save_credentials();

    /*

    if (!connected && _connect == 1)
    {
        printf("Connecting to wifi!\n");
        fflush(stdout);
        return esp_wifi_connect();
    }

    if (connected && _connect == 0)
    {
        printf("Disconnecting from wifi!\n");
        fflush(stdout);
        return esp_wifi_disconnect();
    }

    return EALREADY;*/

    return ESP_OK;
}

esp_err_t wifi_ping()
{
    const static esp_http_client_config_t http_config = {
        .url = "http://159.223.99.186/api/v1/test_upload",
        .event_handler = http_event_handler, 
        .method = HTTP_METHOD_POST
    };

    esp_http_client_handle_t http_handle = esp_http_client_init(&http_config);

    if (http_handle == NULL)
    {
        printf("HTTP client init error!");
        fflush(stdout);
        return ESP_FAIL;
    }
    
    esp_err_t err = esp_http_client_set_header(http_handle, "Content-Type", "application/octet-stream");

    if (err)
    {
        printf("err 1");
        fflush(stdout);
        return ESP_FAIL;
    }

    camera_fb_t *fb = camera_get_img();

    err = esp_http_client_set_post_field(http_handle, (char *) &fb->buf[0], fb->len);

    if (err)
    {
        printf("err 2");
        fflush(stdout);
        return ESP_FAIL;
    }

    err = esp_http_client_perform(http_handle);

    if (err)
    {
        printf("HTTP err - %u", err);
        fflush(stdout);
    }

    esp_http_client_cleanup(http_handle);
    return ESP_OK;
}

esp_err_t wifi_print_credentials(void)
{
    printf("Wifi credentials:\n");
    printf("-----------------\n");

    if (_ssid[0] != 0)
        printf("SSID: %s\n", _ssid);

    if (_username[0] != 0)
        printf("Username: %s\n", _username);

    if (_identity[0] != 0)
        printf("Identity: %s\n", _identity);

    if (_password[0] != 0)
        printf("Password: %s\n", _password);
        
    printf("-----------------\n");

    return ESP_OK;
}

char *wifi_identity_addr(void)
{
    return _identity;
}

char *wifi_password_addr(void)
{
    return _password;
}

char *wifi_username_addr(void)
{
    return _username;
}

char *wifi_ssid_addr(void)
{
    return _ssid;
}

uint8_t *wifi_connect_addr(void)
{
    return &_connect;
}
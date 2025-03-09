#ifndef IPC_H
#define IPC_H

#include <esp_err.h>
#include <stdint.h>

#define RX_BUF_SIZE 256

#define MSG_START_1 0xA2
#define MSG_START_2 0xC5
#define MSG_END_1   0xB3
#define MSG_END_2   0xD6

#define MSG_MAX_LEN 255
#define MSG_PAD_LEN 7

// Max message length of 255

/**
 * IPC Message Format:
 * 
 * 2 bytes: start msg
 * 1 byte:  msg ID
 * 1 byte:  msg len
 * contents {measure of len}
 * 1 byte:  checksum
 * 2 bytes: end msg
 */

enum ipc_message_type 
{
    /**
     * IPC ACK
     * 2 bytes
     * {IPC_ACK | msg num}
     * No ACK
     */
    IPC_ACK,

    /**
     * IPC WIFI USERNAME/IDENTITY/PASSWORD/SSID
     * 2 + n bytes
     * {IPC_WIFI_XXX | n | n bytes string}
     */
    IPC_WIFI_USERNAME,
    IPC_WIFI_IDENTITY,
    IPC_WIFI_PASSWORD,
    IPC_WIFI_SSID,

    /**
     * IPC WIFI CONNECT/DISCONNECT
     * 1 byte
     * {IPC_WIFI_XXX}
     */
    IPC_WIFI_CONNECT,
    IPC_WIFI_DISCONNECT,

    /**
     * IPC CAMERA START/STOP
     * 1 byte
     * {IPC_CAMERA_XXX}
     */
    IPC_CAMERA_START,
    IPC_CAMERA_STOP,

    /**
     * IPC API USERNAME/PASSWORD
     * 2 + n bytes
     * {IPC_API_XXX | n | n bytes string}
     */
    IPC_API_USERNAME,
    IPC_API_PASSWORD,

    /**
     * IPC API LOGIN
     * 1 byte
     * {IPC_API_LOGIN}
     */
    IPC_API_LOGIN,

    /**
     * IPC ERROR
     * 2 bytes
     * {IPC_ERROR | Error code}
     */
    IPC_ERROR
};

typedef void (*ipc_receive_cb)(uint8_t *msg, int len, uint8_t msg_id);

esp_err_t ipc_init(int gpio_send, int gpio_receive, ipc_receive_cb cb);
int ipc_send(uint8_t *msg, int len);

esp_err_t ipc_ack(uint8_t msg_num);
esp_err_t ipc_wifi_set_username(uint8_t *username, uint8_t len);
esp_err_t ipc_wifi_set_identity(uint8_t *identity, uint8_t len);
esp_err_t ipc_wifi_set_password(uint8_t *password, uint8_t len);
esp_err_t ipc_wifi_set_ssid(uint8_t *ssid, uint8_t len);
esp_err_t ipc_wifi_connect();
esp_err_t ipc_wifi_disconnect();
esp_err_t ipc_camera_start();
esp_err_t ipc_camera_stop();
esp_err_t ipc_api_set_username(uint8_t *username, uint8_t len);
esp_err_t ipc_api_set_password(uint8_t *password, uint8_t len);
esp_err_t ipc_api_login();
esp_err_t ipc_send_error(uint8_t error_code);
esp_err_t ipc_handle_msg(uint8_t *msg, uint8_t len, uint8_t msg_id);

#endif
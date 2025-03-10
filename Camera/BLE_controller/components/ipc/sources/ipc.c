#include "ipc.h"

#include "driver/uart.h"
#include "driver/gpio.h"
#include <stdlib.h>
#include <string.h>

const int uart_port = 1;
static QueueHandle_t uart_queue = NULL;
static ipc_receive_cb rx_cb = NULL;

void process_msg(void);

uint8_t calc_checksum(uint8_t *msg, int len)
{
    uint8_t checksum = 0xB7;

    for (int i = 0; i < len; i++)
    {
        checksum += msg[i];
        checksum ^= 0xA4;
    }

    return checksum;
}

static uint8_t send_buf[MSG_MAX_LEN + 6];
static uint8_t msg_id = 0; 

int ipc_send(uint8_t *msg, int len)
{
    if (len > 255)
    {
        printf("msg too long: len %d", len);
        fflush(stdout);
        return -1;
    }

    memset(send_buf, 0, len + 2);

    send_buf[0] = MSG_START_1;
    send_buf[1] = MSG_START_2;
    send_buf[2] = msg_id++;
    send_buf[3] = len;

    for (int i = 0; i < len; i++)
    {
        send_buf[i + 4] = msg[i];
    }

    send_buf[len + 4] = calc_checksum((uint8_t *) msg, len);
    send_buf[len + 5] = MSG_END_1;
    send_buf[len + 6] = MSG_END_2;

    int err = uart_write_bytes(uart_port, send_buf, len + 7);

    if (err == -1)
    {
        return -1;
    }

    return msg_id;
}

static uint8_t rx_buf[(MSG_MAX_LEN + 6) * 4];
static int rx_buf_len = 0;
static bool new_msg = false;

static void uart_task(void *param)
{
    esp_err_t err = ESP_OK;

    while (true)
    {
        size_t data_len = 0;
        err = uart_get_buffered_data_len(uart_port, &data_len);

        if (err)
        {
            printf("uart data len err %d\n", err);
            fflush(stdout);
            continue;
        }

        if (data_len != 0)
        {
            if (data_len > (MSG_MAX_LEN * 4 - rx_buf_len))
            {
                rx_buf_len = 0;
            }

            uart_read_bytes(uart_port, &(rx_buf[rx_buf_len]), data_len, 0);
            rx_buf_len += data_len;
            new_msg = true;

            // printf("Data received: %s\n", rx_buf);
            // fflush(stdout);
        }
        else
        {
            if (new_msg)
            {
                process_msg();
            }

            new_msg = false;

            vTaskDelay(pdMS_TO_TICKS(100));
        }
    }

    vTaskDelete(NULL);
}

void process_msg(void)
{
    for (int i = 0; i < rx_buf_len; i++)
    {
        if (rx_buf[i] != MSG_START_1 || rx_buf[i + 1] != MSG_START_2)
        {
            continue;
        }

        uint8_t len = rx_buf[i + 3];
        uint8_t checksum = calc_checksum(&(rx_buf[i + 4]), len);

        if (rx_buf[i + len + 4] != checksum || rx_buf[i + len + 5] != MSG_END_1 || rx_buf[i + len + 6] != MSG_END_2)
        {
            printf("Checksum or end byte check failed\n");
            fflush(stdout);
        }

        (*rx_cb)(&(rx_buf[i + 4]), len, msg_id);

        i += len;
    }

    rx_buf_len = 0;
}

esp_err_t ipc_init(int gpio_tx, int gpio_rx, ipc_receive_cb cb)
{
    static uart_config_t uart_config = {
        .baud_rate = 115200,
        .data_bits = UART_DATA_8_BITS,
        .flow_ctrl = UART_HW_FLOWCTRL_DISABLE,
        .parity = UART_PARITY_DISABLE,
        .source_clk = UART_SCLK_DEFAULT,
        .stop_bits = UART_STOP_BITS_1
    };

    rx_cb = cb;

    uart_param_config(uart_port, &uart_config);
    //                         12       13
    uart_set_pin(uart_port, gpio_tx, gpio_rx, -1, -1);

    gpio_pullup_en(gpio_tx);

    uart_driver_install(uart_port, 1024, 1024, 10, &uart_queue, 0);

    xTaskCreate(uart_task, "uart_task", 3072, NULL, 12, NULL);

    return ESP_OK;
}

static uint8_t ipc_msg_buf[MSG_MAX_LEN];

esp_err_t ipc_ack(uint8_t msg_num)
{
    ipc_msg_buf[0] = IPC_ACK;
    ipc_msg_buf[1] = msg_num;

    ipc_send(ipc_msg_buf, 2);
    return ESP_OK;
}

esp_err_t ipc_wifi_set_username(uint8_t *username, uint8_t len, uint16_t offset)
{
    ipc_msg_buf[0] = IPC_WIFI_USERNAME;
    ipc_msg_buf[1] = (offset & 0xFF00) >> 8;
    ipc_msg_buf[2] = (offset & 0x00FF);
    ipc_msg_buf[3] = len;
    strncpy((void *) &(ipc_msg_buf[4]), (void *) username, len);

    ipc_send(ipc_msg_buf, len + 4);
    return ESP_OK;
}

esp_err_t ipc_wifi_set_identity(uint8_t *identity, uint8_t len, uint16_t offset)
{
    ipc_msg_buf[0] = IPC_WIFI_IDENTITY;
    ipc_msg_buf[1] = (offset & 0xFF00) >> 8;
    ipc_msg_buf[2] = (offset & 0x00FF);
    ipc_msg_buf[3] = len;
    strncpy((void *) &(ipc_msg_buf[4]), (void *) identity, len);

    ipc_send(ipc_msg_buf, len + 4);
    return ESP_OK;
}

esp_err_t ipc_wifi_set_password(uint8_t *password, uint8_t len, uint16_t offset)
{
    ipc_msg_buf[0] = IPC_WIFI_PASSWORD;
    ipc_msg_buf[1] = (offset & 0xFF00) >> 8;
    ipc_msg_buf[2] = (offset & 0x00FF);
    ipc_msg_buf[3] = len;
    strncpy((void *) &(ipc_msg_buf[4]), (void *) password, len);

    ipc_send(ipc_msg_buf, len + 4);
    return ESP_OK;
}

esp_err_t ipc_wifi_set_ssid(uint8_t *ssid, uint8_t len, uint16_t offset)
{
    ipc_msg_buf[0] = IPC_WIFI_SSID;
    ipc_msg_buf[1] = (offset & 0xFF00) >> 8;
    ipc_msg_buf[2] = (offset & 0x00FF);
    ipc_msg_buf[3] = len;
    strncpy((void *) &(ipc_msg_buf[4]), (void *) ssid, len);

    ipc_send(ipc_msg_buf, len + 4);
    return ESP_OK;
}

esp_err_t ipc_wifi_connect()
{
    ipc_msg_buf[0] = IPC_WIFI_CONNECT;

    ipc_send(ipc_msg_buf, 1);
    return ESP_OK;
}

esp_err_t ipc_wifi_disconnect()
{
    ipc_msg_buf[0] = IPC_WIFI_DISCONNECT;

    ipc_send(ipc_msg_buf, 1);
    return ESP_OK;
}

esp_err_t ipc_camera_start()
{
    ipc_msg_buf[0] = IPC_CAMERA_START;

    ipc_send(ipc_msg_buf, 1);
    return ESP_OK;
}

esp_err_t ipc_camera_stop()
{
    ipc_msg_buf[0] = IPC_CAMERA_STOP;

    ipc_send(ipc_msg_buf, 1);
    return ESP_OK;
}

esp_err_t ipc_api_set_token(uint8_t *username, uint8_t len, uint16_t offset)
{
    ipc_msg_buf[0] = IPC_API_TOKEN;
    ipc_msg_buf[1] = (offset & 0xFF00) >> 8;
    ipc_msg_buf[2] = (offset & 0x00FF);
    ipc_msg_buf[3] = len;
    strncpy((void *) &(ipc_msg_buf[4]), (void *) username, len);

    ipc_send(ipc_msg_buf, len + 4);
    return ESP_OK;
}

esp_err_t ipc_api_set_token_len(uint16_t len)
{
    ipc_msg_buf[0] = IPC_API_TOKEN_LEN;
    ipc_msg_buf[1] = (len & 0xFF00) >> 8;
    ipc_msg_buf[2] = (len & 0x00FF);

    ipc_send(ipc_msg_buf, 3);
    return ESP_OK;
}

esp_err_t ipc_send_error(uint8_t error_code)
{
    ipc_msg_buf[0] = IPC_ERROR;
    ipc_msg_buf[1] = error_code;

    ipc_send(ipc_msg_buf, 2);
    return ESP_OK;
}

esp_err_t ipc_handle_msg(uint8_t *msg, uint8_t len, uint8_t msg_id)
{
    switch (msg[0])
    {
        case IPC_ACK:
            printf("IPC msg ack'ed - %d", msg[1]);
            fflush(stdout);
            return ESP_OK;

        case IPC_ERROR:
            printf("IPC Error - %d", msg[1]);
            fflush(stdout);
            break;
    }

    return ESP_OK;
}
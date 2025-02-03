#include "ble.h"
#include <inttypes.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/event_groups.h"
#include "esp_system.h"
#include "esp_log.h"
#include "nvs_flash.h"
#include "esp_bt.h"

#include "esp_gap_ble_api.h"
#include "esp_gatts_api.h"
#include "esp_bt_defs.h"
#include "esp_bt_main.h"
#include "esp_bt_device.h"
#include "esp_mac.h"

#include "../../wifi/include/wifi.h"
#include "../../LED/include/led.h"

#define ERR_CHECK(err) if (err) { \
    printf("Err: %d (%s:%d)", err, __FILE__, __LINE__); \
    fflush(stdout); \
    return err; \
}

#define LOG_MSG(msg) { \
    printf("%s:%d | ", __FILE__, __LINE__); \
    printf(msg); \
    printf("\n"); \
    fflush(stdout); \
}

esp_err_t ble_start_advertising(void);
esp_err_t ble_stop_advertising(void);

static esp_gatt_if_t gatt_interface = 0x00;
static uint16_t created_handle = 0x0000;
static esp_gatt_status_t gatt_status = ESP_GATT_OK;
static TaskHandle_t ble_init_task;
static struct ble_service ble_services[BLE_NUM_SERVICES];
static struct ble_characteristic vibrator_characteristics[BLE_NUM_VIBRATOR_CHARACTERISTICS];
static struct ble_characteristic wifi_characteristics[BLE_NUM_WIFI_CHARACTERISTICS];

static uint32_t vibrator_ctrl_value = 0;

esp_err_t ble_create_service(esp_gatt_srvc_id_t *srvc_id, uint16_t num_handles, struct ble_service *service_out)
{
    LOG_MSG("Creating service");

    esp_err_t err = esp_ble_gatts_create_service(gatt_interface, srvc_id, num_handles);
    ulTaskNotifyTake(pdTRUE, pdMS_TO_TICKS(100));

    if (gatt_status != ESP_GATT_OK)
    {
        printf("Create vibrator service failed - status %d, err %d", gatt_status, err);
        fflush(stdout);
        return ESP_FAIL;
    }

    err = esp_ble_gatts_start_service(created_handle);

    if (err != ESP_OK)
    {
        printf("Start vibrator service failed - %d", gatt_status);
        fflush(stdout);
        return err;
    }

    service_out->handle = created_handle;

    return err;
}

/**
 * @brief BLE Create Characteristic
 * 
 * Create a BLE characteristic. This function needs to be called after the GATT server is initialized
 * 
 * @param srvc_handle a handle to the parent service that this characteristic belongs to
 * @param chrc_id the UUID of the characteristic to add
 * @param value a pointer to the value data to attach to the created characteristic
 * @param value_len the length of the value data
 * @param characteristic_out the initialized characteristic struct, containing created characteristic information
 * 
 * @returns ESP_OK on success, an ESP error code on failure
 */
esp_err_t ble_create_characteristic(uint16_t srvc_handle, esp_bt_uuid_t *chrc_id, void *value, uint32_t value_len, struct ble_characteristic *characteristic_out)
{
    esp_attr_value_t attr_value = {
        .attr_len = value_len,
        .attr_max_len = value_len,
        .attr_value = (uint8_t *) value
    };

    // Why the hell is this designed this way, the struct contains 1 single element
    esp_attr_control_t attr_control = { 
        .auto_rsp = ESP_GATT_AUTO_RSP
    };
    
    LOG_MSG("Creating characteristic");

    esp_err_t err = esp_ble_gatts_add_char(srvc_handle,
        chrc_id, 
        ESP_GATT_PERM_READ | ESP_GATT_PERM_WRITE, 
        ESP_GATT_CHAR_PROP_BIT_READ | ESP_GATT_CHAR_PROP_BIT_WRITE, 
        &attr_value,
        &attr_control
    );

    ulTaskNotifyTake(pdTRUE, pdMS_TO_TICKS(100));

    if (gatt_status != ESP_GATT_OK || err != ESP_OK)
    {
        printf("Create characteristic failed - %d, %d", gatt_status, err);
        fflush(stdout);
        return ESP_FAIL;
    }

    characteristic_out->handle = created_handle;
    characteristic_out->value = (uint8_t *) value;
    characteristic_out->value_len = value_len;
    characteristic_out->write_cb = NULL;
    characteristic_out->read_cb = NULL;

    return ESP_OK;
}

/**
 * @brief BLE Init Interface
 * 
 * Initialize the BLE GATT interface. This creates all of the services and characteristics required to operate
 * the device. This function needs to be called after the GATT server is initialized
 * 
 * @returns ESP_OK on success, an ESP error code on failure
 */
esp_err_t ble_init_interface()
{
    // Vibrator service UUIDs
    esp_gatt_srvc_id_t vibrator_srvc_id = SERVICE_ID(VIBRATOR_SERVICE_UUID, true);
    esp_bt_uuid_t vibrator_ctrl_uuid = CHARACTERISTIC_UUID(VIBRATOR_CTRL_UUID);

    // Wi-Fi service UUIDs
    esp_gatt_srvc_id_t wifi_srvc_id = SERVICE_ID(WIFI_SERVICE_UUID, true);
    esp_bt_uuid_t wifi_ssid_uuid = CHARACTERISTIC_UUID(WIFI_SSID_UUID);
    esp_bt_uuid_t wifi_username_uuid = CHARACTERISTIC_UUID(WIFI_USERNAME_UUID);
    esp_bt_uuid_t wifi_identity_uuid = CHARACTERISTIC_UUID(WIFI_IDENTITY_UUID);
    esp_bt_uuid_t wifi_password_uuid = CHARACTERISTIC_UUID(WIFI_PASSWORD_UUID);
    esp_bt_uuid_t wifi_connect_uuid = CHARACTERISTIC_UUID(WIFI_CONNECT_UUID);

    esp_err_t err = ESP_OK;

    // Create the vibration service
    err = ble_create_service(&vibrator_srvc_id, 10, &(ble_services[0]));
    ERR_CHECK(err);

    ble_services[0].characteristics = vibrator_characteristics;
    ble_services[0].characteristics_len = BLE_NUM_VIBRATOR_CHARACTERISTICS;

    err = ble_create_characteristic(ble_services[0].handle, &vibrator_ctrl_uuid, (void *) led_get_ble_val(), 4, &ble_services[0].characteristics[0]);
    ERR_CHECK(err);

    // Create the Wi-Fi connection service
    err = ble_create_service(&wifi_srvc_id, 50, &(ble_services[1]));
    ERR_CHECK(err);

    ble_services[1].characteristics = wifi_characteristics;
    ble_services[1].characteristics_len = BLE_NUM_WIFI_CHARACTERISTICS;

    err = ble_create_characteristic(ble_services[1].handle, &wifi_ssid_uuid, (void *) wifi_ssid_addr(), 
        WIFI_CREDENTIAL_MAX_LEN, &ble_services[1].characteristics[0]);
    ERR_CHECK(err);

    ble_services[1].characteristics[0].write_cb = wifi_print_credentials;

    err = ble_create_characteristic(ble_services[1].handle, &wifi_username_uuid, (void *) wifi_username_addr(), 
        WIFI_CREDENTIAL_MAX_LEN, &ble_services[1].characteristics[1]);
    ERR_CHECK(err);
    
    ble_services[1].characteristics[1].write_cb = wifi_print_credentials;

    err = ble_create_characteristic(ble_services[1].handle, &wifi_identity_uuid, (void *) wifi_identity_addr(), 
        WIFI_CREDENTIAL_MAX_LEN, &ble_services[1].characteristics[2]);
    ERR_CHECK(err);
    
    ble_services[1].characteristics[2].write_cb = wifi_print_credentials;

    err = ble_create_characteristic(ble_services[1].handle, &wifi_password_uuid, (void *) wifi_password_addr(), 
        WIFI_CREDENTIAL_MAX_LEN, &ble_services[1].characteristics[3]);
    ERR_CHECK(err);
    
    ble_services[1].characteristics[3].write_cb = wifi_print_credentials;

    err = ble_create_characteristic(ble_services[1].handle, &wifi_connect_uuid, (void *) wifi_connect_addr(),
         sizeof(bool), &ble_services[1].characteristics[4]);
    ERR_CHECK(err);
    
    ble_services[1].characteristics[4].write_cb = wifi_connect_cb;

    return err;
}

esp_err_t ble_handle_write_evt(struct gatts_write_evt_param *write_param)
{
    uint16_t handle = write_param->handle;
    struct ble_service *service = NULL;
    struct ble_characteristic *characteristic = NULL;

    for (uint32_t i = 1; i < BLE_NUM_SERVICES; i++)
    {
        if (ble_services[i - 1].handle < handle && ble_services[i].handle >= handle)
        {
            service = &ble_services[i - 1];
        }
    }

    if (service == NULL)
        service = &ble_services[BLE_NUM_SERVICES - 1];

    for (uint32_t i = 0; i < service->characteristics_len; i++)
    {
        if (service->characteristics[i].handle == handle)
        {
            characteristic = &service->characteristics[i];
        }
    }

    if (characteristic == NULL)
        return ESP_ERR_NOT_FOUND;

    for (uint32_t i = 0; i < write_param->len; i++)
    {
        characteristic->value[write_param->offset + i] = write_param->value[i];
    }

    for (uint32_t i = write_param->len + write_param->offset; i < characteristic->value_len; i++)
    {
        characteristic->value[i] = '\0';
    }

    if (characteristic->write_cb != NULL)
        (*characteristic->write_cb)();

    return ESP_OK;
}

esp_err_t ble_handle_read_evt(struct gatts_read_evt_param *read_param)
{
    uint16_t handle = read_param->handle;
    struct ble_service *service = NULL;
    struct ble_characteristic *characteristic = NULL;

    for (uint32_t i = 1; i < BLE_NUM_SERVICES; i++)
    {
        if (ble_services[i - 1].handle < handle && ble_services[i].handle >= handle)
        {
            service = &ble_services[i - 1];
        }
    }

    if (service == NULL)
        service = &ble_services[BLE_NUM_SERVICES - 1];

    for (uint32_t i = 0; i < service->characteristics_len; i++)
    {
        if (service->characteristics[i].handle == handle)
        {
            characteristic = &service->characteristics[i];
        }
    }

    if (characteristic == NULL)
        return ESP_ERR_NOT_FOUND;

    /*for (uint32_t i = 0; i < characteristic->value_len; i++)
    {
        if (write_param->len < characteristic->value_len)
        {
            characteristic->value[i] = '\0';
        }
        else
        {
            characteristic->value[i] = write_param->value[i];
        }
    }*/

    if (characteristic->read_cb != NULL)
        (*characteristic->read_cb)();

    return ESP_OK;
}

void ble_gap_cb(esp_gap_ble_cb_event_t event, esp_ble_gap_cb_param_t *param)
{
    switch (event)
    {
        case ESP_GAP_BLE_ADV_START_COMPLETE_EVT:
            LOG_MSG("Advertising started");
            break;

        case ESP_GAP_BLE_ADV_STOP_COMPLETE_EVT:
            LOG_MSG("Advertising stopped");
            break;

        default:
            return;
    }
}

/**
 * @brief BLE Gatts Callback
 * 
 * This callback handles all events related to the BLE GATT Server
 * 
 * @param event the GATTS event that has occurred
 * @param gatts_if the GATTS interface type for client applications
 * @param param event parameters for the current event
 */
void ble_gatts_cb(esp_gatts_cb_event_t event, esp_gatt_if_t gatts_if, esp_ble_gatts_cb_param_t *param)
{
    esp_err_t err;

    switch (event)
    {
        case ESP_GATTS_CONNECT_EVT:
            struct gatts_connect_evt_param *evt_param = (struct gatts_connect_evt_param *) param;

            esp_ble_conn_update_params_t ble_conn_update_params = {
                .max_int = 80, // 100 ms
                .min_int = 80, // 100 ms
                .latency = 49, // 5s disconnected
                .timeout = 1000, // 10s
                .bda = {
                    evt_param->remote_bda[0], 
                    evt_param->remote_bda[1], 
                    evt_param->remote_bda[2], 
                    evt_param->remote_bda[3], 
                    evt_param->remote_bda[4], 
                    evt_param->remote_bda[5], 
                }
            };

            LOG_MSG("Device connected");
            ble_stop_advertising();
            
            esp_err_t err = esp_ble_gap_update_conn_params(&ble_conn_update_params);

            if (err)
            {
                printf("Error updating conn params: %d", err);
                fflush(stdout);
            }

            break;

        case ESP_GATTS_DISCONNECT_EVT:
            LOG_MSG("Device disconnected");
            ble_start_advertising();
            break;

        case ESP_GATTS_REG_EVT:
            LOG_MSG("App ID Registered");
            gatt_interface = gatts_if;
            break;

        // A service has been created. 
        case ESP_GATTS_CREATE_EVT:
            LOG_MSG("Service created");
            struct gatts_create_evt_param *create_param = &param->create;
            created_handle = create_param->service_handle;
            gatt_status = create_param->status;
            xTaskNotifyGive(ble_init_task);
            break;

        case ESP_GATTS_ADD_CHAR_EVT:
            LOG_MSG("Characteristic created");
            struct gatts_add_char_evt_param *add_char_param = &param->add_char;
            created_handle = add_char_param->attr_handle;
            gatt_status = add_char_param->status;
            xTaskNotifyGive(ble_init_task);
            break;

        case ESP_GATTS_WRITE_EVT:
            LOG_MSG("Write event");
            struct gatts_write_evt_param write_param = param->write;

            err = ble_handle_write_evt(&write_param);

            if (err)
            {
                printf("GATTS write err %d", err);
                fflush(stdout);
            }

            break;

        case ESP_GATTS_READ_EVT:
            LOG_MSG("Read event");
            struct gatts_read_evt_param read_param = param->read;

            err = ble_handle_read_evt(&read_param);

            if (err)
            {
                printf("GATTS write err %d", err);
                fflush(stdout);
            }

            break;

        default:
            return;
    }
}

static esp_ble_adv_data_t ble_adv_data = {
    .set_scan_rsp = true,
    .include_name = true,
    .include_txpower = true,
    .min_interval = 0x20,
    .max_interval = 0x40,
    .appearance = 0x00,
    .manufacturer_len = 15,
    .service_data_len = 0,
    .service_uuid_len = 0,
    .p_service_uuid = NULL,
    .p_manufacturer_data = (uint8_t *) "August Druzgal",
    .p_service_data = NULL,
    .flag = ESP_BLE_ADV_FLAG_GEN_DISC | ESP_BLE_ADV_FLAG_BREDR_NOT_SPT
};

static esp_ble_adv_params_t adv_params = {
    .adv_int_min = 0x100,
    .adv_int_max = 0x100,
    .adv_type = ADV_TYPE_IND,
    .own_addr_type = BLE_ADDR_TYPE_PUBLIC,
    .peer_addr_type = BLE_ADDR_TYPE_PUBLIC,
    .peer_addr = {0xB0, 0x00, 0x00, 0x00, 0xB1, 0xE5},
    .channel_map = ADV_CHNL_ALL,
    .adv_filter_policy = ADV_FILTER_ALLOW_SCAN_ANY_CON_ANY,
};

esp_err_t ble_start_advertising(void)
{
    esp_err_t ret = esp_ble_gap_config_adv_data(&ble_adv_data);
    ERR_CHECK(ret);

    ret = esp_ble_gap_start_advertising(&adv_params);
    ERR_CHECK(ret);

    return ret;
}

esp_err_t ble_stop_advertising(void)
{
    esp_err_t ret = esp_ble_gap_stop_advertising();
    ERR_CHECK(ret);

    return ret;
}

esp_err_t ble_disable(void)
{
    esp_bluedroid_disable();
    esp_bluedroid_deinit();
    esp_bt_controller_deinit();
    return ESP_OK;
}

esp_err_t ble_init(void)
{
    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_ERROR_CHECK(nvs_flash_erase());
        ret = nvs_flash_init();
    }
    ERR_CHECK(ret);

    ble_init_task = xTaskGetCurrentTaskHandle();

    esp_bt_controller_config_t bt_cfg = BT_CONTROLLER_INIT_CONFIG_DEFAULT();
    ret = esp_bt_controller_init(&bt_cfg);
    ERR_CHECK(ret);

    ret = esp_bt_controller_enable(ESP_BT_MODE_BLE);
    ERR_CHECK(ret);

    ret = esp_bluedroid_init();
    ERR_CHECK(ret);

    ret = esp_bluedroid_enable();
    ERR_CHECK(ret);

    ret = esp_ble_gap_register_callback(ble_gap_cb);
    ERR_CHECK(ret);

    ret = esp_ble_gatts_register_callback(ble_gatts_cb);
    ERR_CHECK(ret);

    ret = esp_ble_gap_set_device_name("August Device");
    ERR_CHECK(ret);

    esp_ble_gatts_app_register(APP_ID);

    ulTaskNotifyTake(pdTRUE, pdMS_TO_TICKS(100));
    ble_init_interface();

    ble_start_advertising();

    return ESP_OK;
}
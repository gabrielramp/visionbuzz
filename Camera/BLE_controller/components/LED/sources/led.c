#include <stdio.h>
#include <inttypes.h>
#include "sdkconfig.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_chip_info.h"
#include "esp_system.h"
#include "driver/gpio.h"

#include "led.h"

uint8_t led_ble_val = 0x00;
uint8_t pulse_counter = 0;

void led_task_fn(void *args)
{
    gpio_set_level(14, 0);

    while (true)
    {
        vTaskDelay(pdMS_TO_TICKS(1000));
        // printf("Task is alive\n");
        // fflush(stdout);

        continue;
        if (pulse_counter != 0)
        {
            gpio_set_level(14, 1);
            vTaskDelay(pdMS_TO_TICKS(led_ble_val % 2 == 1 ? PULSE_MS_1 : PULSE_MS_0));
            gpio_set_level(14, 0);
            vTaskDelay(pdMS_TO_TICKS(PULSE_MS_PAUSE));
            led_ble_val >>= 1;
            pulse_counter--;
        }
        else
        {
            gpio_set_level(14, 0);
            vTaskDelay(pdMS_TO_TICKS(100));
        }
    }
}

void led_task_create(void)
{
    xTaskCreate(led_task_fn, "LED_task", 2048, NULL, 2, NULL);
}

void led_init(uint32_t pin)
{
    gpio_config_t gpio_cfg = {
        .intr_type = GPIO_INTR_DISABLE,
        .mode = GPIO_MODE_OUTPUT,
        .pin_bit_mask = (1 << pin),
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .pull_up_en = GPIO_PULLUP_DISABLE
    };

    gpio_config(&gpio_cfg);
}

uint8_t *led_get_pulse_counter(void)
{
    return &pulse_counter;
}

uint8_t *led_get_ble_val(void)
{
    return &led_ble_val;
}

void led_on(uint32_t pin)
{
    gpio_set_level(pin, 1);
}

void led_off(uint32_t pin)
{
    gpio_set_level(pin, 0);
}

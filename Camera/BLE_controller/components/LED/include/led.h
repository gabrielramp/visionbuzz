#ifndef LED_H
#define LED_H

#define PULSE_MS_0 150
#define PULSE_MS_1 300
#define PULSE_MS_PAUSE 150

void led_task_fn(void *args);
void led_init(uint32_t pin);
void led_task_create(void);
uint8_t *led_get_ble_val(void);
uint8_t *led_get_pulse_counter(void);
void led_on(uint32_t pin);
void led_off(uint32_t pin);

#endif
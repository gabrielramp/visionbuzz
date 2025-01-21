#include "shell.h"
#include "esp_console.h"

int hello_cmd_func(int argc, char **argv)
{
    printf("Hey!");
    fflush(stdout);
    return 0;
}

const esp_console_cmd_t console_hello_cmd = {
    .command = "hello",
    .help = "say hello to the camera",
    .hint = "type \"hello\"",
    .func = hello_cmd_func,
    .argtable = NULL,
    .func_w_context = NULL,
    .context = NULL
};

esp_err_t shell_init(void)
{
    esp_console_repl_t *console_repl = NULL;

    const esp_console_config_t console_config = {
        .heap_alloc_caps = MALLOC_CAP_SPIRAM,
        .hint_bold = 1,
        .hint_color = 6,
        .max_cmdline_args = 4,
        .max_cmdline_length = 80
    };

    esp_err_t err = esp_console_init(&console_config);

    if (err)
    {
        printf("Console initialization error - %d", err);
        fflush(stdout);
        return err;
    }

    err = esp_console_cmd_register(&console_hello_cmd);

    if (err)
    {
        printf("Help command initialization error - %d", err);
        fflush(stdout);
        return err;
    }


    return EXIT_SUCCESS;
}
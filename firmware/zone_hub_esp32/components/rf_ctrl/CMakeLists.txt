idf_component_register(
    SRCS "rf_ctrl.c"
    INCLUDE_DIRS "include"
    REQUIRES driver esp_timer esp_rom
)

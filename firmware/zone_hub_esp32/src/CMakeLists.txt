FILE(GLOB_RECURSE app_sources "*.c" "*.cpp")

idf_component_register(
    SRCS ${app_sources}
    INCLUDE_DIRS "."
    REQUIRES driver led_strip relay_ctrl ir_ctrl rf_ctrl pzem_ctrl
)
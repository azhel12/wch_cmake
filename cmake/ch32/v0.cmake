set(CH32_V0_TYPES 
    V00x
)
set(CH32_V0_TYPE_MATCH 
    "V00..."
)
set(CH32_V0_RAM_SIZES 
     2K
)

ch32_util_create_family_targets(V0)

target_compile_options(CH32::V0 INTERFACE 
    -march=rv32ec_zicsr -mabi=ilp32e
)
target_link_options(CH32::V0 INTERFACE 
    -march=rv32ec_zicsr -mabi=ilp32e -nostartfiles
)

function(ch32v0_get_memory_info DEVICE TYPE FLASH_SIZE RAM_SIZE)
    # All has 2kb sram
    set(${RAM_SIZE} "2K" PARENT_SCOPE)
endfunction()
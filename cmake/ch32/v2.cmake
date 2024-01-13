set(CH32_V2_TYPES 
    V20x_D6 V20x_D8 V20x_D6W
)
set(CH32_V2_TYPE_MATCH 
    "V20[^8][^R]." "V203R." "V208.."
)
set(CH32_V2_RAM_SIZES 
     20K 64K 64K
)

ch32_util_create_family_targets(V2)

target_compile_options(CH32::V2 INTERFACE 
    -march=rv32ifc_zicsr -mabi=ilp32f
)
target_link_options(CH32::V2 INTERFACE 
    -march=rv32ifc_zicsr -mabi=ilp32f -nostartfiles
)
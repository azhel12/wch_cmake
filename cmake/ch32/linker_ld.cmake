if(${FAMILY} STREQUAL "V0")
    set(VECTOR_SECTION "")
else()
    set(VECTOR_SECTION
"  .vector :\n\
  {\n\
    *(.vector);\n\
    . = ALIGN(64);\n\
  } >FLASH AT>FLASH\n\
")
endif()

set(SCRIPT_TEXT 
"ENTRY( _start )\n\
\n\
__stack_size =  ${STACK_SIZE};\n\
\n\
PROVIDE( _stack_size = __stack_size );\n\
\n\
MEMORY\n\
{\n\
    FLASH (rx)      : ORIGIN = ${FLASH_ORIGIN}, LENGTH = ${FLASH_SIZE}\n\
    RAM (xrw)      : ORIGIN = ${RAM_ORIGIN}, LENGTH = ${RAM_SIZE}\n\
}\n\
\n\
SECTIONS\n\
{\n\
  .init :\n\
  {\n\
    _sinit = .;\n\
    . = ALIGN(4);\n\
    KEEP(*(SORT_NONE(.init)))\n\
    . = ALIGN(4);\n\
  } >FLASH AT>FLASH\n\
\n\
${VECTOR_SECTION}\n\
  .text :\n\
    {\n\
        . = ALIGN(4);\n\
        *(.text)\n\
        *(.text.*)\n\
        *(.rodata)\n\
        *(.rodata*)\n\
        *(.glue_7)\n\
        *(.glue_7t)\n\
        *(.gnu.linkonce.t.*)\n\
        . = ALIGN(4);\n\
    } >FLASH AT>FLASH \n\
\n\
    .fini :\n\
    {\n\
        KEEP(*(SORT_NONE(.fini)))\n\
        . = ALIGN(4);\n\
    } >FLASH AT>FLASH\n\
\n\
    PROVIDE( _etext = . );\n\
    PROVIDE( _eitcm = . );	\n\
\n\
    .preinit_array  :\n\
    {\n\
      PROVIDE_HIDDEN (__preinit_array_start = .);\n\
      KEEP (*(.preinit_array))\n\
      PROVIDE_HIDDEN (__preinit_array_end = .);\n\
    } >FLASH AT>FLASH \n\
    \n\
    .init_array     :\n\
    {\n\
      PROVIDE_HIDDEN (__init_array_start = .);\n\
      KEEP (*(SORT_BY_INIT_PRIORITY(.init_array.*) SORT_BY_INIT_PRIORITY(.ctors.*)))\n\
      KEEP (*(.init_array EXCLUDE_FILE (*crtbegin.o *crtbegin?.o *crtend.o *crtend?.o ) .ctors))\n\
      PROVIDE_HIDDEN (__init_array_end = .);\n\
    } >FLASH AT>FLASH \n\
    \n\
    .fini_array     :\n\
    {\n\
      PROVIDE_HIDDEN (__fini_array_start = .);\n\
      KEEP (*(SORT_BY_INIT_PRIORITY(.fini_array.*) SORT_BY_INIT_PRIORITY(.dtors.*)))\n\
      KEEP (*(.fini_array EXCLUDE_FILE (*crtbegin.o *crtbegin?.o *crtend.o *crtend?.o ) .dtors))\n\
      PROVIDE_HIDDEN (__fini_array_end = .);\n\
    } >FLASH AT>FLASH \n\
    \n\
    .ctors          :\n\
    {\n\
      /* gcc uses crtbegin.o to find the start of\n\
         the constructors, so we make sure it is\n\
         first.  Because this is a wildcard, it\n\
         doesn't matter if the user does not\n\
         actually link against crtbegin.o; the\n\
         linker won't look for a file to match a\n\
         wildcard.  The wildcard also means that it\n\
         doesn't matter which directory crtbegin.o\n\
         is in.  */\n\
      KEEP (*crtbegin.o(.ctors))\n\
      KEEP (*crtbegin?.o(.ctors))\n\
      /* We don't want to include the .ctor section from\n\
         the crtend.o file until after the sorted ctors.\n\
         The .ctor section from the crtend file contains the\n\
         end of ctors marker and it must be last */\n\
      KEEP (*(EXCLUDE_FILE (*crtend.o *crtend?.o ) .ctors))\n\
      KEEP (*(SORT(.ctors.*)))\n\
      KEEP (*(.ctors))\n\
    } >FLASH AT>FLASH \n\
    \n\
    .dtors          :\n\
    {\n\
      KEEP (*crtbegin.o(.dtors))\n\
      KEEP (*crtbegin?.o(.dtors))\n\
      KEEP (*(EXCLUDE_FILE (*crtend.o *crtend?.o ) .dtors))\n\
      KEEP (*(SORT(.dtors.*)))\n\
      KEEP (*(.dtors))\n\
    } >FLASH AT>FLASH \n\
\n\
    .dalign :\n\
    {\n\
        . = ALIGN(4);\n\
        PROVIDE(_data_vma = .);\n\
    } >RAM AT>FLASH	\n\
\n\
    .dlalign :\n\
    {\n\
        . = ALIGN(4); \n\
        PROVIDE(_data_lma = .);\n\
    } >FLASH AT>FLASH\n\
\n\
    .data :\n\
    {\n\
        . = ALIGN(4);\n\
        *(.gnu.linkonce.r.*)\n\
        *(.data .data.*)\n\
        *(.gnu.linkonce.d.*)\n\
        . = ALIGN(8);\n\
        PROVIDE( __global_pointer$ = . + 0x800 );\n\
        *(.sdata .sdata.*)\n\
        *(.sdata2.*)\n\
        *(.gnu.linkonce.s.*)\n\
        . = ALIGN(8);\n\
        *(.srodata.cst16)\n\
        *(.srodata.cst8)\n\
        *(.srodata.cst4)\n\
        *(.srodata.cst2)\n\
        *(.srodata .srodata.*)\n\
        . = ALIGN(4);\n\
        PROVIDE( _edata = .);\n\
    } >RAM AT>FLASH\n\
\n\
    .bss :\n\
    {\n\
        . = ALIGN(4);\n\
        PROVIDE( _sbss = .);\n\
          *(.sbss*)\n\
        *(.gnu.linkonce.sb.*)\n\
        *(.bss*)\n\
         *(.gnu.linkonce.b.*)		\n\
        *(COMMON*)\n\
        . = ALIGN(4);\n\
        PROVIDE( _ebss = .);\n\
    } >RAM AT>FLASH\n\
\n\
    PROVIDE( _end = _ebss);\n\
    PROVIDE( end = . );\n\
\n\
  .stack ORIGIN(RAM) + LENGTH(RAM) - __stack_size :\n\
  {\n\
      PROVIDE( _heap_end = . );   \n\
      . = ALIGN(4);\n\
      PROVIDE(_susrstack = . );\n\
      . = . + __stack_size;\n\
      PROVIDE( _eusrstack = .);\n\
  } >RAM \n\
}"
)
file(WRITE "${LINKER_SCRIPT}" "${SCRIPT_TEXT}")



#if defined (CH32V0)
    #include "ch32v00x_gpio.h"
    #include "ch32v00x_rcc.h"
    
    #define LED_PORT GPIOD
    #define LED_PIN GPIO_Pin_2
    #define LED_BUS RCC_APB2Periph_GPIOD
#elif defined (CH32V2)
    #include "ch32v20x_gpio.h"
    #include "ch32v20x_rcc.h"

    #define LED_PORT GPIOA
    #define LED_PIN GPIO_Pin_0
    #define LED_BUS RCC_APB2Periph_GPIOA
#endif

int main()
{
    GPIO_InitTypeDef  GPIO_InitStructure = {0};

    RCC_APB2PeriphClockCmd(LED_BUS, ENABLE);

    GPIO_InitStructure.GPIO_Pin = LED_PIN;
    GPIO_InitStructure.GPIO_Speed = GPIO_Speed_10MHz;
    GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
    GPIO_Init(LED_PORT, &GPIO_InitStructure);

    while(1)
    {
        GPIO_SetBits(LED_PORT, LED_PIN);
        for (int i = 0; i < 4000000; ++i)
			__asm("nop");

        GPIO_ResetBits(LED_PORT, LED_PIN);
        for (int i = 0; i < 4000000; ++i)
			__asm("nop");
    }
}

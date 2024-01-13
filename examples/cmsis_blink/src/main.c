// Works on ch32v003

#if defined (CH32V0)
	#include "ch32v00x.h"
#elif defined (CH32V2)
	#include "ch32v20x.h"
#endif

int main()
{
	// Enable GPIOA
	RCC->APB2PCENR |= RCC_IOPAEN;
	// GPIO D0 Push-Pull
	GPIOA->CFGLR &= ~(0xf << (4 * 0));
	GPIOA->CFGLR |= GPIO_CFGLR_MODE0_0 << (4 * 0);

	while (1)
	{
		GPIOA->BSHR = (1 << 0); // Turn on PA0
		for (int i = 0; i < 4000000; ++i)
			__asm("nop");

		GPIOA->BSHR = (1 << (16 + 0)); // Turn off PA0
		for (int i = 0; i < 4000000; ++i)
			__asm("nop");
	}
}

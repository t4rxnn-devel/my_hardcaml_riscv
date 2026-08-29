int main(void) {
    volatile int *leds = (int *) 0x30000000;
    int counter = 0;

    while (1) {
        *leds = counter++;
        for (volatile int i = 0; i < 1000; i++); // Simple delay loop
    }

    return 0;
}

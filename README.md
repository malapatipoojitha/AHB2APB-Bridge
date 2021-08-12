AHB and APB Protocols come under the AMBA family of protocols. They are designed by ARM as an interface for their processors. AHB is for high-performance, high clock frequency system modules and supports multiple bus masters whereas APB is used for low-power peripherals. 

AHB2APB Bridge is an AHB Slave that converts system bus transfers into  APB Transfers. Bridge Latches the address and holds it valid throughout the transfer. It also decodes the address and generates a slave select signal

bulk endpoint endless source/sink firmware.

EP2OUT will always accept a bulk OUT
EP4OUT will always accept a bulk OUT

EP6IN will always return a 512 byte packet. The packet contains an
incrementing byte starting at 0x02.  Since EP6 always returns a 512
byte packet, this endpoint should never be accessed except with a 
high-speed host controller.

EP8IN will continuously return the packet most recently written to
EP4OUT

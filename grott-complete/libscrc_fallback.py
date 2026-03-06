"""Pure Python Modbus CRC16 fallback for libscrc.

Drop-in replacement that provides libscrc.modbus() without C compilation.
"""

def modbus(data):
    """Calculate Modbus CRC16 checksum."""
    crc = 0xFFFF
    for byte in data:
        crc ^= byte
        for _ in range(8):
            if crc & 0x0001:
                crc = (crc >> 1) ^ 0xA001
            else:
                crc >>= 1
    return crc

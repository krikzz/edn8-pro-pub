/base: system stuff. do not modify this files
/000: mapper pack. Each *.rbf file may contain one or more mappers. Every mapper should be linked via map_hub.v

Mappers instalation:
EDN8 loads mappers from .RBF files. RBF is a quartus binary output, without any changes.
OS loads mappers from /EDN8/MAPS/ 
.RBF file can be loaded via USB for testing. During loading via USB .RBF file will not be saved to SD card, it will be loaded directly to fpga just for single game launch.

OS uses mappers linking table to link certain mapper number to specific .RBF file. This table stored in MAPROUT.BIN
Each record in MAPROUT.BIN is one byte. Offset equal to mapper number, value equal to .RBF name (decimal number)

Mapper linking procedure:
For example 000.RBF contains mappers 3 and 7. In MAPROUT.BIN set 0x00 at offset 0x03 and 0x07 (MAPROUT.BIN[3] = 0, MAPROUT.BIN[7] = 0)
Value 0xFF means that mapper is not supported.

Last reccord reserved for OS, always should be 0xff

Begins from firmware V2.15 *.rbf file can be simply stored along with rom in same folder,
so no need to put it in system folder and modify MAPROUT.BIN anymore

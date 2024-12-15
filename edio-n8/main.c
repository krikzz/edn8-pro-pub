
#include "main.h"

void romPath();
void romRead();
void fileRead();
void fileRead();
void fileWrite();
void fileToRom();
void folderList();
void usbWrite();
void usbRead();

void main() {

    sysInit();
    ed_init();

    gClearScreen();
    gConsPrint("");
    gConsPrint("");
    gConsPrintCX("EverDrive-N8 IO sample");
    gConsPrint("");
    gConsPrint("");

    romPath(); //get current rom path
    romRead(); //read rom memory
    fileRead(); //read from file
    fileWrite(); //write to the file
    fileToRom(); //fast dma transfer from file to the rom memory
    folderList(); //print list of files in the folder

    gConsPrint("");
    gConsPrint("press key if ready to test usb");
    gRepaint();

    while (sysJoyRead() == 0);
    gClearScreen();
    gRepaint();

    usbWrite(); //tx via usb to pc
    usbRead(); //rx from via usb from pc


    gRepaint();
    while (1);
}

void romPath() {

    u8 resp;
    u8 rom_path[32];

    resp = ed_cmd_file_open("EDN8/sysdata/registry.bin", FA_READ);
    if (resp)return; //error
    resp = ed_cmd_file_read(rom_path, 32);
    if (resp)return; //error

    //ed_cmd_rom_path(rom_path, 0); //buffer size should be not less than 512B

    gConsPrint("rom: ");
    gAppendString_ML(rom_path, 26);

}

void romRead() {

    u8 buff[10];

    gConsPrint("chr read : ");
    ed_cmd_mem_rd(ADDR_CHR + 0x210, buff, sizeof (buff)); //read chr rom at offset 0x210
    gAppendHex(buff, sizeof (buff));

    gConsPrint("prg read : ");
    ed_cmd_mem_rd(ADDR_PRG + 0, buff, sizeof (buff)); //read chr rom at offset 0
    gAppendHex(buff, sizeof (buff));

}

void fileRead() {

    u8 resp;
    u8 buff[10];
    u32 size;

    resp = ed_cmd_file_open("edn8/nesos.nes", FA_READ);
    if (resp)return; //error
    size = ed_cmd_file_available();
    resp = ed_cmd_file_read(buff, sizeof (buff));
    if (resp)return; //error
    resp = ed_cmd_file_close();
    if (resp)return; //error

    gConsPrint("file read: ");
    gAppendHex(buff, sizeof (buff));
    gConsPrint("file size: 0x");
    gAppendHex32(size);

}

void fileWrite() {

    u8 resp;
    u8 buff[] = {'h', 'e', 'l', 'l', 'o', ' ', 't', 'e', 'x', 't'};

    gConsPrint("file write...");
    //create "test_file.txt" in the root of SD and write buff to the file.
    resp = ed_cmd_file_open("test_file.txt", FA_WRITE | FA_CREATE_ALWAYS);
    if (resp)return; //error
    resp = ed_cmd_file_write(buff, sizeof (buff));
    if (resp)return; //error
    resp = ed_cmd_file_close();
    if (resp)return; //error
    gAppendString("ok");

}

void fileToRom() {

    u8 resp;
    u32 size;

    gConsPrint("read file to rom...");

    resp = ed_cmd_file_open("edn8/nesos.nes", FA_READ);
    if (resp)return; //error
    size = ed_cmd_file_available();
    //write whole file to the rom memory at offset 0x20000
    //offset needed because it will override current program otherwise
    resp = ed_cmd_file_read_mem(ADDR_PRG + 0x20000, size);
    if (resp)return; //error
    resp = ed_cmd_file_close();
    if (resp)return; //error

    gAppendString("ok");

}

void folderList() {

    u8 resp;
    u16 size;
    u8 i;
    FileInfo inf;
    u8 name_buff[16 + 1];

    inf.file_name = name_buff;

    gConsPrint("");
    gConsPrint("get folder list...");

    resp = ed_cmd_dir_load("edn8", 0); //get list of files in system folder
    if (resp)return; //error
    ed_cmd_dir_get_size(&size);

    gAppendString("dir size: ");
    gAppendNum(size);

    ed_cmd_dir_get_recs(0, size, sizeof (name_buff) - 1);

    for (i = 0; i < size && i < 8; i++) {

        resp = ed_rx_next_rec(&inf);
        if (resp)return; //error
        gConsPrint("[");
        gAppendString(inf.file_name);
        gAppendString("]");

        if (inf.is_dir) {
            gAppendString("...dir");
        } else {
            gAppendString("...file");
        }
    }

    gConsPrint("");
}

void usbWrite() {//send strings to the virtual com-port. Use any serial terminal app to receive strings.

    gConsPrint("send test string to usb...");
    //gRepaint();

    //listen virtual com port to receive this string on PC side
    ed_cmd_usb_wr("test string\n", 12);

}

void usbRead() {//receive strings from virtual-com and print to the screen. use string-read.bat for string sending

    u8 char_val;

    gConsPrint("waiting input text from usb...");
    gConsPrint("time to run string-tx.bat");
    gConsPrint("");
    gRepaint();

    while (1) {

        //single byte communication is very slow. 
        //use larger blocks for real applications but not more than SIZE_FIFO

        if (ed_fifo_busy()) {
            gRepaint();
        }

        ed_fifo_rd(&char_val, 1);

        if (char_val == '\n') {
            gConsPrint("");
        } else {
            gAppendChar(char_val);
        }

    }
}

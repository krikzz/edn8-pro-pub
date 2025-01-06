using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;

namespace edlink_n8
{
    class NesRom
    {

        public const int ROM_TYPE_NES = 0;
        public const int ROM_TYPE_FDS = 1;
        public const int ROM_TYPE_OS = 2;

        public const char MIR_HOR = 'H';
        public const char MIR_VER = 'V';
        public const char MIR_4SC = '4';
        public const char MIR_1SC = '1';

        const int FDS_DISK_SIZE = 65500;

        const int MAX_ID_CALC_LEN = 0x100000;

        string rom_path;
        byte[] prg;
        byte[] chr;
        byte[] ines;
        int crc;
        int srm_size;
        byte mapper;
        char mirroring;
        bool bat_ram;
        int dat_base;
        int size;
        int rom_type;


        int prg_addr;
        int chr_addr;

        public NesRom(string path)
        {

            if (path == null) throw new Exception("ROM is not specified");
            int prg_size = 0;
            int chr_size = 0;
            prg_addr = Edio.ADDR_PRG;
            chr_addr = Edio.ADDR_CHR;

            rom_path = path;

            byte[] rom = File.ReadAllBytes(path);
            size = rom.Length;

            ines = new byte[32];
            Array.Copy(rom, 0, ines, 0, ines.Length);

            bool nes = ines[0] == 'N' && ines[1] == 'E' && ines[2] == 'S';
            bool fds00 = ines[11] == 'H' && ines[12] == 'V' && ines[13] == 'C';
            bool fds16 = ines[11 + 16] == 'H' && ines[12 + 16] == 'V' && ines[13 + 16] == 'C';

            if (nes)
            {
                rom_type = ROM_TYPE_NES;
                dat_base = 16;
                prg_addr = Edio.ADDR_PRG;
                prg_size = rom[4] * 1024 * 16;
                chr_size = rom[5] * 1024 * 8;
                srm_size = 8192;
                if (prg_size == 0) prg_size = 0x400000;
                mapper = (byte)((rom[6] >> 4) | (rom[7] & 0xf0));
                mirroring = (rom[6] & 1) == 0 ? 'H' : 'V';
                bat_ram = (rom[6] & 2) == 0 ? false : true;
                if ((rom[6] & 8) != 0) mirroring = '4';
                
                if (mapper == 255)
                {
                    rom_type = ROM_TYPE_OS;
                    prg_addr = Edio.ADDR_MENU_PRG;
                    chr_addr = Edio.ADDR_MENU_CHR;
                }


                prg = new byte[prg_size];
                chr = new byte[chr_size];
                Array.Copy(rom, dat_base, prg, 0, prg.Length);
                Array.Copy(rom, dat_base + prg.Length, chr, 0, chr.Length);
            }
            else if (fds00 | fds16)
            {
                rom_type = ROM_TYPE_FDS;
                dat_base = fds00 ? 0 : 16;
                prg_addr = Edio.ADDR_SRM;
                chr_size = 0;
                prg_size = (rom.Length - dat_base) / FDS_DISK_SIZE * 0x10000;
                if (prg_size < rom.Length) prg_size += 0x10000;
                srm_size = 32768;
                mapper = 254;

                prg = new byte[prg_size];
                chr = new byte[chr_size];
                for (int i = 0; i < prg_size / 0x10000; i++)
                {
                    int block = FDS_DISK_SIZE;
                    int src = dat_base + i * FDS_DISK_SIZE;
                    int dst = i * 0x10000;
                    if (src + block > rom.Length) block = rom.Length - src;
                    Array.Copy(rom, src, prg, dst, block);
                }
                
            }
            else
            {
                throw new Exception("Unknown ROM format.");
            }

                       

            int crc_len = Math.Min(rom.Length - dat_base, MAX_ID_CALC_LEN);
            crc = (int)CRC32.calc(0, rom, dat_base, crc_len);
        }

        public void print()
        {
            Console.WriteLine("Mapper   : " + mapper);
            Console.WriteLine("PRG SIZE : " + prg.Length / 1024 + "K (" + prg.Length / 1024 / 16 + " x 16K)");
            Console.WriteLine("CHR SIZE : " + chr.Length / 1024 + "K (" + chr.Length / 1024 / 8 + " x 8K)");
            Console.WriteLine("SRM SIZE : " + srm_size / 1024 + "K");
            Console.WriteLine("Mirroring: " + mirroring);
            Console.WriteLine("BAT RAM  : " + (bat_ram ? "Yes" : "No"));
            Console.WriteLine("ROM ID   : 0x{0:X8}", crc);
        }


        public int PrgSize
        {
            get { return prg.Length; }
        }

        public int ChrSize
        {
            get { return chr.Length; }
        }

        public int SrmSize
        {
            get { return srm_size; }
        }


        public int PrgAddr
        {
            get { return prg_addr; }
        }

        public int ChrAddr
        {
            get { return chr_addr; }
        }


        public byte Mapper
        {
            get { return mapper; }
        }

        public char Mirroring
        {
            get { return mirroring; }
        }

        public int Type
        {
            get { return rom_type; }
        }

        public string Name
        {
            get { return Path.GetFileName(rom_path); }
        }

        public byte[] PrgData
        {
            get { return prg; }
        }

        public byte[] ChrData
        {
            get { return chr; }
        }

        

        public byte[] getRomID()
        {
            byte[] bin = new byte[ines.Length + 4 * 3];
            int ptr = 0;

            Array.Copy(ines, 0, bin, ptr, ines.Length);
            ptr += ines.Length;

            Array.Copy(BitConverter.GetBytes(size), 0, bin, ptr, 4);
            ptr += 4;
            Array.Copy(BitConverter.GetBytes(crc), 0, bin, ptr, 4);
            ptr += 4;
            Array.Copy(BitConverter.GetBytes(dat_base), 0, bin, ptr, 4);
            ptr += 4;

            return bin;
        }

    }
}

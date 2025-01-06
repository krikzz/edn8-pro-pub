using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace edlink_n8
{
    internal class CmdProcessor
    {

        static Usbio usb;
        static Edio edio;

        public static void start(string[] args, Edio io)
        {

            edio = io;
            usb = new Usbio(edio);

            string rom_path = null;
            string map_path = null;


            for (int i = 0; i < args.Length; i++)
            {
                string cmd = args[i].ToLower().Trim();

                if (cmd.Equals("-recovery"))
                {
                    cmd_recovery();
                }

                if (cmd.Equals("-appmode"))
                {
                    cmd_exitServiceMode();
                }

                if (cmd.Equals("-sermode"))
                {
                    cmd_enterServiceMode();
                }

                if (cmd.Equals("-diag"))
                {
                    cmd_diagnosics();
                }


                if (cmd.Equals("-mkdir"))
                {
                    usb.makeDir(args[i + 1]);
                    i += 1;
                    continue;
                }

                if (cmd.Equals("-rtcset"))
                {
                    cmd_setTime();
                    continue;
                }

                if (cmd.Equals("-rtcget"))
                {
                    cmd_rtcGet();
                    continue;
                }

                if (cmd.Equals("-cp"))
                {
                    usb.copyFile(args[i + 1], args[i + 2]);
                    i += 2;
                    continue;
                }

                if (cmd.Equals("-flawr"))
                {
                    cmd_flashWrite(args[i + 1], args[i + 2]);
                    i += 2;
                    continue;
                }


                if (cmd.EndsWith(".nes") || cmd.EndsWith(".fds"))
                {
                    rom_path = args[i];
                    continue;
                }

                if (cmd.EndsWith(".rbf"))
                {
                    map_path = args[i];
                    continue;
                }

                if (cmd.StartsWith("-memwr"))
                {
                    cmd_memWrite(args[i + 1], args[i + 2]);
                    i += 2;
                }

                if (cmd.StartsWith("-memrd"))
                {
                    cmd_memRead(args[i + 1], args[i + 2], args[i + 3]);
                    i += 3;
                }

                if (cmd.StartsWith("-fpginit"))
                {
                    edio.fpgInit(File.ReadAllBytes(args[i + 1]), null);
                    i += 1;
                }

                if (cmd.Equals("-testvdc"))
                {
                    cmd_testVDC();
                    continue;
                }

                if (cmd.Equals("-update"))//as recovery, but executed from bootloader. works without power down down
                {
                    cmd_update();
                    return;//usb link will be lost. no more commands can be executed
                }

                if (cmd.Equals("-rtccal"))
                {
                    cmd_rtcCal(args[i + 1]);
                    i += 1;
                    continue;
                }

                if (cmd.Equals("-stest"))
                {
                    cmd_stest();
                    continue;
                }

                if (cmd.Equals("-screen"))
                {
                    //this stuff only for taking screenshots for using in manual
                    cmd_screenshot();
                    continue;
                }
            }


            if (rom_path != null)
            {
                //edio.getConfig().print();
                cmd_loadApp(rom_path, map_path);
            }

            Console.WriteLine("");

        }

        static int getNum(string num)
        {

            if (num.ToLower().Contains("0x"))
            {
                return Convert.ToInt32(num, 16);
            }
            else
            {
                return Convert.ToInt32(num);
            }

        }

        static byte[] getFileData(string path)
        {
            byte[] data = null;

            if (path.ToLower().StartsWith("efu:"))
            {
                string efu_path = path.Substring(4);
                efu_path = efu_path.Substring(0, efu_path.IndexOf("//"));

                string file_path = path.Substring(path.IndexOf("//") + 2);
                file_path = file_path.Replace("\\", "/");

                data = new Datafile(efu_path).getFileData(file_path);

            }
            else
            {
                data = File.ReadAllBytes(path);
            }


            return data;
        }

        static void cmd_recovery()
        {
            Console.Write("EDIO core recovery...");
            edio.recovery();
            Console.WriteLine("ok");
        }

        static void cmd_exitServiceMode()
        {
            Console.Write("Exit service mode...");
            edio.exitServiceMode();
            Console.WriteLine("ok");
        }

        static void cmd_enterServiceMode()
        {
            Console.Write("Enter service mode...");
            edio.enterServiceMode();
            Console.WriteLine("ok");
        }

        static void cmd_diagnosics()
        {
            Diagnostics diag = new Diagnostics(edio);
            diag.start();
        }


        static void cmd_flashWrite(string addr_str, string path)
        {
            int addr = 0;

            Console.Write("Flash programming...");

            if (addr_str.ToLower().Contains("0x"))
            {
                addr = Convert.ToInt32(addr_str, 16);
            }
            else
            {
                addr = Convert.ToInt32(addr_str);
            }

            byte[] data = getFileData(path);

            edio.flaWR(addr, data, 0, data.Length);

            Console.WriteLine("ok");
        }


        static void cmd_memWrite(string path, string addr_str)
        {
            int addr = 0;
            Console.Write("Memory write...");

            addr = getNum(addr_str);

            byte[] data = File.ReadAllBytes(path);
            edio.memWR(addr, data, 0, data.Length);

            Console.WriteLine("ok");
        }

        static void cmd_memRead(string path, string addr_str, string len_str)
        {
            int addr;
            int len;
            Console.Write("Memory read...");

            addr = getNum(addr_str);
            len = getNum(len_str);

            byte[] data = new byte[len];
            edio.memRD(addr, data, 0, data.Length);
            File.WriteAllBytes(path, data);

            Console.WriteLine("ok");
        }


        static void cmd_testVDC()
        {
            Diagnostics diag = new Diagnostics(edio);
            diag.testVDC();
        }

        static void cmd_rtcGet()
        {
            edio.rtcGet().print();
            RtcTime sys_time = new RtcTime(DateTime.Now);
            sys_time.print("SYS");
        }

        static void cmd_update()
        {
            Console.Write("EDIO core update...");

            byte[] buff = new byte[4];
            edio.flaRD(Edio.ADDR_FLA_ICOR + 4, buff, 0, buff.Length);

            int crc = (buff[0] << 0) | (buff[1] << 8) | (buff[2] << 16) | (buff[3] << 24);
            edio.updExec(Edio.ADDR_FLA_ICOR, crc);

            Console.WriteLine("ok");
        }

        static void cmd_loadApp(string rom_path, string map_path)
        {
            Console.WriteLine("ROM loading...");
            long time = DateTime.Now.Ticks;

            NesRom rom = new NesRom(rom_path);
            rom.print();
            Console.WriteLine("********************************");

            if (rom.Type == NesRom.ROM_TYPE_OS)
            {
                loadApp_menu(rom, map_path);
            }
            else
            {
                loadApp_game(rom_path, map_path);
            }

            time = (DateTime.Now.Ticks - time) / 10000;
            Console.WriteLine("loading time: " + time);

            Console.WriteLine();
        }

        static void loadApp_menu(NesRom rom, string map_path)
        {
            if (map_path == null)
            {
                map_path = usb.getTestMapper(255, null);
            }
            Console.WriteLine("Map path : " + (map_path == null ? "internal" : map_path));

            byte[] prg = rom.PrgData;
            byte[] chr = rom.ChrData;
            MapConfig cfg = new MapConfig();
            cfg.map_idx = 0xff;
            cfg.Ctrl = MapConfig.ctrl_unlock;

            usb.reset();

            edio.memWR(rom.PrgAddr, prg, 0, prg.Length);
            edio.memWR(rom.ChrAddr, chr, 0, chr.Length);

            edio.getStatus();

            if (map_path == null)
            {
                usb.mapLoadSDC(255, cfg);
            }
            else
            {
                byte[] map = File.ReadAllBytes(map_path);
                edio.fpgInit(map, cfg);
            }
        }

        static void loadApp_game(string rom_path, string map_path)
        {
            string usb_dir = "sd:usb-games";
            bool fpg_rom = false;

            usb.makeDir(usb_dir);

            if (map_path != null || usb.getTestMapper(0, rom_path) != null)
            {
                //for rom with rbf file name is usb-games/romname.nes.fpgrom
                usb_dir += "/" + Path.GetFileName(rom_path) + ".fpgrom";
                fpg_rom = true;
            }

            usb.makeDir(usb_dir);

            string rom_dst = usb_dir + "/" + Path.GetFileName(rom_path);
            usb.copyFile(rom_path, rom_dst);


            int map_idx = usb.appInstall(rom_dst.Substring(3));

            if (map_path == null && fpg_rom)
            {
                map_path = usb.getTestMapper(map_idx, rom_path);
            }
            //Console.WriteLine("Map path : " + (map_path == null ? "internal" : map_path));

            string rbf_dst = usb_dir + "/mapper.rbf";

            if (map_path != null)
            {
                usb.copyFile(map_path, rbf_dst);
            }

            usb.appStart();
        }

        static void cmd_setTime()
        {

            int sec = DateTime.Now.Second;
            while (DateTime.Now.Second == sec) ;

            edio.rtcSet(DateTime.Now);
        }

        static void cmd_stest()
        {
            byte[] buff = new byte[0x100000];
            DateTime t;
            long t_ms;

            Console.Write("Read....");
            t = DateTime.Now;
            edio.memRD(Edio.ADDR_CHR, buff, 0, buff.Length);
            t_ms = (DateTime.Now.Ticks - t.Ticks) / 10000;
            Console.WriteLine(buff.Length * 1000 / t_ms / 1024 + "KB/s");

            Console.Write("Write...");
            t = DateTime.Now;
            edio.memWR(Edio.ADDR_CHR, buff, 0, buff.Length);
            t_ms = (DateTime.Now.Ticks - t.Ticks) / 10000;
            Console.WriteLine(buff.Length * 1000 / t_ms / 1024 + "KB/s");
        }


        static void cmd_rtcCal(string arg_str)
        {
            //arg-0: set time and abort calibraion
            //arg-1: start calibration
            //arg-2: finish calibration
            //arg-3: get current calibration value
            //arg-4: get estimated calibration value
            //arg-5: get time deviation in ms
            //arg-6: set any calibration value via rtc.yar

            byte arg = (byte)Convert.ToInt32(arg_str);
            int resp;

            int sec = DateTime.Now.Second;
            while (DateTime.Now.Second == sec) ;

            resp = edio.rtcCal(DateTime.Now, arg);

            string sig = resp > 0 ? "+" : "";

            if (arg == 5)
            {
                Console.WriteLine("rtc deviation: " + sig + resp + "ms");
            }
            else
            {
                Console.WriteLine("rtc calibration: " + sig + resp);
            }
        }

        static void cmd_screenshot()
        {
            byte[] vram = new byte[2048];
            byte[] palette = new byte[16];
            byte[] chr = new byte[8192];

            usb.vramDump(vram, palette);
            edio.memRD(Edio.ADDR_MENU_CHR, chr, 0, chr.Length);


            MenuImage.makeImage(DateTime.Now.ToString().Replace(":", "").Replace(" ", "_").Replace(".", "-").Replace("/", "-") + ".png", chr, vram, palette);
        }
    }
}

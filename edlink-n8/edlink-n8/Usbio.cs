using System;
using System.Text;
using System.IO;

namespace edlink_n8
{
    class Usbio
    {

        Edio edio;
        const char cmd_test = 't';
        const char cmd_reboot = 'r';
        const char cmd_halt = 'h';
        const char cmd_sel_game = 'n';
        const char cmd_run_game = 's';


        public Usbio(Edio edio)
        {
            this.edio = edio;
        }

        public int appInstall(string path)
        {
            int resp;
            cmd(cmd_sel_game);
            txString(path);
            resp = edio.rx8();//game select status
            if (resp != 0)
            {
                throw new Exception("Game select error 0x" + resp.ToString("X2"));
            }

            int map_idx = edio.rx16();
            return map_idx;
        }

        public void appStart()
        {
            cmd(cmd_run_game);
        }

        void copyFolder(string src, string dst)
        {
            if (!src.EndsWith("/")) src += "/";
            if (!dst.EndsWith("/")) dst += "/";

            string[] dirs = Directory.GetDirectories(src);

            for (int i = 0; i < dirs.Length; i++)
            {
                copyFolder(dirs[i], dst + Path.GetFileName(dirs[i]));
            }


            string[] files = Directory.GetFiles(src);


            for (int i = 0; i < files.Length; i++)
            {
                copyFile(files[i], dst + Path.GetFileName(files[i]));
            }
        }

        public void copyFile(string src, string dst)
        {
            byte[] src_data;
            src = src.Trim();
            dst = dst.Trim();

            if (File.GetAttributes(src).HasFlag(FileAttributes.Directory))
            {
                copyFolder(src, dst);
                return;
            }

            if (dst.EndsWith("/") || dst.EndsWith("\\"))
            {
                dst += Path.GetFileName(src);
            }

            Console.WriteLine("copy file: " + src + " to " + dst);

            if (src.ToLower().StartsWith("sd:"))
            {
                src = src.Substring(3);
                src_data = new byte[edio.fileInfo(src).size];

                edio.fileOpen(src, Edio.FAT_READ);
                edio.fileRead(src_data, 0, src_data.Length);
                edio.fileClose();
            }
            else
            {
                src_data = File.ReadAllBytes(src);
            }

            /*
            if (src_data.Length > Edio.MAX_ROM_SIZE)
            {
                throw new Exception("File is too big");
            }*/


            if (dst.ToLower().StartsWith("sd:"))
            {
                dst = dst.Substring(3);
                edio.fileOpen(dst, Edio.FAT_CREATE_ALWAYS | Edio.FAT_WRITE);
                edio.fileWrite(src_data, 0, src_data.Length);
                edio.fileClose();
            }
            else
            {
                File.WriteAllBytes(dst, src_data);
            }

        }

        public void makeDir(string path)
        {
            path = path.Trim();

            if (path.ToLower().StartsWith("sd:") == false)
            {
                throw new Exception("incorrect dir path: " + path);
            }
            Console.WriteLine("make dir: " + path);
            path = path.Substring(3);
            edio.dirMake(path);
        }

        void cmd(char cmd)
        {
            byte[] buff = new byte[2];
            buff[0] = (byte)'*';
            buff[1] = (byte)cmd;
            edio.fifoWR(buff, 0, buff.Length);
        }

        void txString(string str)
        {
            byte[] bytes = Encoding.ASCII.GetBytes(str);
            UInt16 str_len = (UInt16)bytes.Length;
            edio.fifoWR(BitConverter.GetBytes(str_len), 0, 2);
            edio.fifoWR(bytes, 0, bytes.Length);
        }


        public void mapLoadSDC(int map_id, MapConfig cfg)
        {
            string map_path = "EDN8/MAPS/";
            int map_pkg;
            byte[] map_rout = new byte[4096];


            edio.fileOpen("EDN8/MAPROUT.BIN", Edio.FAT_READ);
            edio.fileRead(map_rout, 0, map_rout.Length);
            edio.fileClose();

            map_pkg = map_rout[map_id];
            if (map_pkg == 0xff && map_id != 0xff)
            {

                cfg = new MapConfig();
                cfg.map_idx = 255;
                cfg.Ctrl = MapConfig.ctrl_unlock;
                edio.fpgInit("EDN8/MAPS/255.RBF", cfg);
                throw new Exception("Unsupported mapper: " + map_id);
            }

            if (map_pkg < 100) map_path += "0";
            if (map_pkg < 10) map_path += "0";
            map_path += map_pkg + ".RBF";

            Console.WriteLine("int mapper: " + map_path);
            edio.fpgInit(map_path, cfg);
        }

        string getTestPath(string rom_path)
        {
            string testpath = null;

            try
            {
                testpath = File.ReadAllText("testpath.txt");
            }
            catch (Exception)
            {

                try
                {
                    testpath = Path.GetDirectoryName(rom_path) + "/testpath.txt";
                    testpath = testpath.Replace("\\", "/");
                    testpath = File.ReadAllText(testpath);
                }
                catch (Exception)
                {
                    return "E:/projects/edn8-pro/fpga";
                }
            };

            testpath = testpath.Replace("\\", "/");
            testpath = testpath.Trim();
            if (testpath.EndsWith("/"))
            {
                testpath = testpath.Substring(0, testpath.Length - 1).Trim();
            }

            return testpath;
        }

        public string getTestMapper(int mapper, string rom_path)
        {
            string testpath = getTestPath(rom_path);

            try
            {
                string map_path = testpath;

                byte[] maprout = File.ReadAllBytes(testpath + "/MAPROUT.BIN");

                int pack = maprout[mapper];
                if (pack == 255 && mapper != 255)
                {
                    throw new Exception("Mapper is not supported");
                }


                map_path += "/" + pack.ToString("d3") + "/output_files";

                string[] rbf_list = Directory.GetFiles(map_path, "*.rbf");

                if (rbf_list.Length < 1)
                {
                    throw new Exception("rbf files not found");
                }


                if (rbf_list.Length > 1)
                {
                    Console.WriteLine("WARNING: multiple rbf files found");
                }

                rbf_list[0] = rbf_list[0].Replace("\\", "/");

                return rbf_list[0];

            }
            catch (Exception)
            {
                return null;
            }
        }

        public void reset()
        {
            cmd(cmd_reboot);
            edio.rx8();//exec
        }

        public void vramDump(byte[] vram, byte[] palette)
        {
            edio.fifoWR("*v");
            edio.rxData(vram, 2048);
            edio.rxData(palette, 16);
        }
    }


}

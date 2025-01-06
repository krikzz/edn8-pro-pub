using System;
using System.IO;
using System.Reflection;

namespace edlink_n8
{
    class Program
    {

        static Edio edio;
        static void Main(string[] args)
        {

            Console.OutputEncoding = System.Text.Encoding.UTF8;

            Console.WriteLine("edlink-n8 v" + Assembly.GetEntryAssembly().GetName().Version);

            try
            {
                edlink(args);
            }
            catch (Exception x)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("");
                Console.WriteLine("ERROR: " + x.Message);
                Console.ResetColor();
            }

        }

        static void edlink(string[] args)
        {

            edio = new Edio();
            Console.WriteLine("EverDrive found at " + edio.PortName);
            Console.WriteLine("EDIO status: " + edio.getStatus().ToString("X4"));
            Console.WriteLine("");


            bool force_app_mode = true;
            for (int i = 0; i < args.Length; i++)
            {
                if (args[i].Equals("-appmode")) force_app_mode = false;
                if (args[i].Equals("-sermode")) force_app_mode = false;
            }
            if (force_app_mode)
            {
                edio.exitServiceMode();
            }


            if (args.Length == 0)
            {
                edio.getConfig().printFull();
                Console.WriteLine("");
                printState();
                Console.WriteLine("");
                edio.getPort().Close();
                Console.WriteLine("Press any key");
                Console.ReadKey();
                return;
            }



            CmdProcessor.start(args, edio);
        }

        static void printState()
        {
            byte[] ss = new byte[256];
            int cons_y = Console.CursorTop;


            edio.memRD(Edio.ADDR_SSR, ss, 0, ss.Length);
            Console.SetCursorPosition(0, cons_y);

            for (int i = 0; i < ss.Length; i += 16)
            {
                if (i == 128) Console.WriteLine("");
                if (i % 256 == 0) Console.WriteLine("");

                Console.ForegroundColor = ConsoleColor.White;

                if (i >= 128 + 0 && i < 128 + 32)
                {
                    Console.ForegroundColor = ConsoleColor.Yellow;
                }

                if (i >= 128 + 32 && i < 128 + 64)
                {
                    Console.ForegroundColor = ConsoleColor.Green;
                }

                if (i >= 128 + 64 && i < 256)
                {
                    Console.ForegroundColor = ConsoleColor.Cyan;
                }

                Console.WriteLine("" + BitConverter.ToString(ss, i, 8) + "  " + BitConverter.ToString(ss, i + 8, 8));
            }

            /*
            Console.ForegroundColor = ConsoleColor.White;
            Console.Write("Mapper regs, ");
            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.Write("APU regs, ");
            Console.ForegroundColor = ConsoleColor.Green;
            Console.Write("PPU pal, ");
            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.WriteLine("PPU regs + sst request src");*/

            Console.ForegroundColor = ConsoleColor.White;

        }
    }
}

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Threading;

namespace edlink_n8
{
    class Diagnostics
    {

        Edio edio;

        public Diagnostics(Edio edio)
        {
            this.edio = edio;
        }

        public void start()
        {
            int resp;

            Console.WriteLine("EverDrive diagnostics begins...");
            if (edio.isServiceMode())
            {
                throw new Exception("device in service mode");
            }

            resp = testMEM("PRG", Edio.ADDR_PRG, Edio.SIZE_PRG);
            printResp(resp);

            resp = testMEM("CHR", Edio.ADDR_CHR, Edio.SIZE_CHR);
            printResp(resp);

            resp = testMEM("SRM", Edio.ADDR_SRM, Edio.SIZE_SRM);
            printResp(resp);

            resp = testRTC();
            printResp(resp);

            testVDC();


            edio.rtcGet().print();

            Console.WriteLine("Diagnostics complete");

        }

        void printResp(int resp)
        {
            ConsoleColor old = Console.ForegroundColor;

            if (resp == 0)
            {
                Console.ForegroundColor = ConsoleColor.Green;
                Console.WriteLine("OK");
            }
            else
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("ERROR: 0x"+ resp.ToString("X2"));
            }

            Console.ForegroundColor = old;
        }

        int printVDC(string name, UInt16 vdc, int min, int max)
        {

            bool ok = vdc >= min && vdc <= max;
            Console.Write(name + " - " + (vdc >> 8).ToString("X2") + "." + (vdc & 0xff).ToString("X2"));
            ConsoleColor old = Console.ForegroundColor;

            if (ok)
            {
                Console.ForegroundColor = ConsoleColor.Green;
                Console.WriteLine(" OK");
            }
            else
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine(" ERROR");
            }


            Console.ForegroundColor = old;

            return ok ? 0 : 1;
        }

        int testMEM(string name, int addr, int size)
        {
            byte[] buff;
            Console.Write("Testing " + name + "...");

            //simple data bus test
            buff = new byte[] {0xAA};
            edio.memWR(addr, buff, 0, buff.Length);
            edio.memRD(addr, buff, 0, buff.Length);
            if (buff[0] != 0xAA) return 0x01;
            buff = new byte[] { 0x55 };
            edio.memWR(addr, buff, 0, buff.Length);
            edio.memRD(addr, buff, 0, buff.Length);
            if (buff[0] != 0x55) return 0x01;


            //full data bus + partial address bus test
            buff = new byte[256];
            for (int i = 0; i < buff.Length; i++) buff[i] = (byte)i;
            edio.memWR(addr, buff, 0, buff.Length);
            edio.memRD(addr, buff, 0, buff.Length);
            for(int i = 0;i < buff.Length; i++)
            {
                if (buff[i] != i) return 0x02;
            }

            //full address bus test
            for (int i = 0; i < size; i *= 2)
            {
                buff = BitConverter.GetBytes(i);
                edio.memWR(addr + i, buff, 0, buff.Length);
                if (i == 0) i = 2;
            }
            for (int i = 0; i < size; i *= 2)
            {
                edio.memRD(addr + i, buff, 0, buff.Length);
                int val = BitConverter.ToInt32(buff, 0);
                if (val != i) return 0x03;
                if (i == 0) i = 2;
            }

            //random data test
            Random rnd = new Random((int)DateTime.Now.Ticks);
            byte[] rnd_dat = new byte[0x10000];
            buff = new byte[rnd_dat.Length];
            rnd.NextBytes(rnd_dat);
            edio.memWR(addr, rnd_dat, 0, rnd_dat.Length);
            edio.memRD(addr, buff, 0, buff.Length);
            for(int i = 0;i < buff.Length; i++)
            {
                if (buff[i] != rnd_dat[i]) return 0x04;
            }

            return 0;
        }


        public void testVDC()
        {
            Vdc vdc;

            edio.GetVdc();
            vdc = edio.GetVdc();

            printVDC("Battery ", vdc.vbt, 0x200, 0x345);
            printVDC("VCC 5.0v", vdc.v50, 0x440, 0x510);
            printVDC("VCC 2.5v", vdc.v25, 0x240, 0x260);
            printVDC("VCC 1.2v", vdc.v12, 0x110, 0x130);

        }

        int testRTC()
        {
            RtcTime rtc_old;
            RtcTime rtc_now;
            Console.Write("Testing RTC...");

            //check if rtc working at all
            rtc_old = edio.rtcGet();
            Thread.Sleep(1100);
            if (edio.rtcGet().sec == rtc_old.sec) return 0x01;

            //check accuracy
            rtc_old = edio.rtcGet();
            rtc_now = rtc_old;


            while (rtc_now.sec == rtc_old.sec)
            {
                rtc_now = edio.rtcGet();
            }
            rtc_old = rtc_now;

            long ticks = DateTime.Now.Ticks;
            while (rtc_old.sec == edio.rtcGet().sec) ;

            ticks = (DateTime.Now.Ticks - ticks) / 10000;
            if (ticks > 1020) return 0x02;
            if (ticks < 980) return 0x03;

            return 0;

        }

        
    }
}

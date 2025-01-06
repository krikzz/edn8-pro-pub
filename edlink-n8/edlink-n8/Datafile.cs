using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;

namespace edlink_n8
{


    class Datafile
    {
        const int MAX_EFU_SIZE = 0x700000;
        const int MAX_RECS = 0x10000;

        DataRecord[] recs;
        int rec_num;
        int file_num;
        int dir_num;
        DateTime curtime = DateTime.Now;

        public Datafile(string src, string dst)
        {
            recs = new DataRecord[MAX_RECS];
            rec_num = 0;
            file_num = 0;
            dir_num = 0;
            scanPath(src, dst, src);
        }

        public Datafile(string efu_path)
        {
            makeFromEfu(efu_path);
        }

        public Datafile(byte[] datafile)
        {
            makeFromEfu(datafile);
        }

        void makeFromEfu(string efu_path)
        {
            byte[] datafile = File.ReadAllBytes(efu_path);
            makeFromEfu(datafile);
        }

        void makeFromEfu(byte[] datafile)
        {
            dir_num = read32(datafile, 4 * 4);
            file_num = read32(datafile, 4 * 5);
            rec_num = dir_num + file_num;

            getEfuRecs(datafile);
        }

        void getEfuRecs(byte[] datafile)
        {
            int data_start = read32(datafile, 4 * 2);
            int data_size = read32(datafile, 4 * 3);
            int data_crc = read32(datafile, 4 * 6);
            int hdr_crc = read32(datafile, 4 * 7);

            int hdr_crc_calc = (int)CRC32.calc(0, datafile, 0, 28);
            if (hdr_crc_calc != hdr_crc)
            {
                throw new Exception("hdr crc " + hdr_crc.ToString("X8"));
            }

            int data_crc_calc = (int)CRC32.calc(0, datafile, data_start, data_size);
            if (data_crc_calc != data_crc)
            {
                throw new Exception("data crc " + data_crc.ToString("X8"));
            }

            recs = new DataRecord[rec_num];

            for (int i = 0; i < rec_num; i++)
            {
                recs[i] = new DataRecord(datafile, data_start);
                data_start += recs[i].getRecSize();
            }

        }

        void scanPath(string src, string dst, string path)
        {

            recs[rec_num++] = new DataRecord(src, dst, path, true);
            dir_num++;

            string[] dirs = Directory.GetDirectories(path);

            for (int i = 0; i < dirs.Length; i++)
            {
                scanPath(src, dst, dirs[i]);
            }

            string[] files = Directory.GetFiles(path);

            for (int i = 0; i < files.Length; i++)
            {
                recs[rec_num++] = new DataRecord(src, dst, files[i], false);
                file_num++;
            }
        }

        public byte[] getData(int dev_target)
        {
            int hdr_size = 64;
            int ptr = 0;
            byte[] buff = new byte[MAX_EFU_SIZE];

            //************************************************** dirs
            for (int i = 0; i < rec_num; i++)
            {
                if (recs[i].IsDir == false) continue;

                byte[] rec_data = recs[i].getRecData();
                Array.Copy(rec_data, 0, buff, ptr, rec_data.Length);
                ptr += rec_data.Length;
            }
            //************************************************** files
            for (int i = 0; i < rec_num; i++)
            {
                if (recs[i].IsDir == true) continue;

                byte[] rec_data = recs[i].getRecData();
                Array.Copy(rec_data, 0, buff, ptr, rec_data.Length);
                ptr += rec_data.Length;
            }

            int df_size = ptr;
            if (df_size % 16 != 0)
            {
                df_size = df_size / 16 * 16 + 16;
            }
            df_size += hdr_size;
            byte[] datafile = new byte[df_size];
            df_size = ptr;

            for (int i = 0; i < datafile.Length; i++)
            {
                datafile[i] = 0xff;
            }

            int crc = (int)CRC32.calc(0, buff, 0, df_size);

            UInt16 date;
            UInt16 time;
            date = (UInt16)(curtime.Day | (curtime.Month << 5) | (curtime.Year - 1980 << 9));
            time = (UInt16)((curtime.Second / 2 | (curtime.Hour << 11) | (curtime.Minute << 5)));

            ptr = 0;

            //******************************************************** header
            copy32(datafile, ptr, dev_target);
            ptr += 4;

            datafile[ptr++] = (byte)(date & 0xff);
            datafile[ptr++] = (byte)(date >> 8);
            datafile[ptr++] = (byte)(time & 0xff);
            datafile[ptr++] = (byte)(time >> 8);

            copy32(datafile, ptr, hdr_size);//df start
            ptr += 4;
            copy32(datafile, ptr, df_size);//df size
            ptr += 4;
            copy32(datafile, ptr, dir_num);
            ptr += 4;
            copy32(datafile, ptr, file_num);
            ptr += 4;

            copy32(datafile, ptr, crc);//datafile crc
            ptr += 4;

            crc = (int)CRC32.calc(0, datafile, 0, ptr);
            copy32(datafile, ptr, crc);//header crc
            ptr += 4;
            //********************************************************

            Array.Copy(buff, 0, datafile, hdr_size, df_size);

            /*
            Console.WriteLine("dir num : " + dir_num);
            Console.WriteLine("file num: " + file_num);
            Console.WriteLine("size    : " + df_size);*/

            return datafile;
        }

        void copy32(byte[] dst, int offset, int val)
        {
            dst[offset++] = (byte)(val >> 0);
            dst[offset++] = (byte)(val >> 8);
            dst[offset++] = (byte)(val >> 16);
            dst[offset++] = (byte)(val >> 24);
        }

        int read32(byte[] src, int offset)
        {
            int val = 0;
            offset += 3;

            for (int i = 0; i < 4; i++)
            {
                val <<= 8;
                val |= src[offset--];
            }

            return val;
        }

        public int Recnum
        {
            get { return rec_num; }
        }

        public int Filenum
        {
            get { return file_num; }
        }

        public int Dirnum
        {
            get { return dir_num; }
        }

        public byte[] getFileData(string path)
        {
            path = path.ToLower().Trim();

            for (int i = 0; i < rec_num; i++)
            {
                string rec_path = recs[i].getRecName().ToLower().Trim();
                if (path.Equals(rec_path))
                {
                    return recs[i].getFileData();
                }
            }

            return null;
        }

        public static void setVerStamp(byte[] datafile, UInt16 date)
        {
            int ptr = 32;
            datafile[ptr++] = (byte)(date & 0xff);
            datafile[ptr++] = (byte)(date >> 8);
        }

        public static UInt16 getVerStamp(byte[] datafile)
        {
            UInt16 date = 0;
            int ptr = 32;
            date |= (UInt16)(datafile[ptr++] << 0);
            date |= (UInt16)(datafile[ptr++] << 8);

            return date;
        }

    }
}

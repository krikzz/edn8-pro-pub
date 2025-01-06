using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;

namespace edlink_n8
{
    class DataRecord
    {

        bool is_dir;
        byte[] data;
        string name;
        //string src_path;
        DateTime ftime;
        public DataRecord(string src, string dst, string path, bool is_dir)
        {


            this.is_dir = is_dir;

            if (is_dir)
            {
                data = new byte[0];
                ftime = File.GetCreationTime(path);
            }
            else
            {
                data = File.ReadAllBytes(path);
                ftime = File.GetLastWriteTime(path);
            }

            name = path.Replace(src, dst);
            name = name.Replace('\\', '/');
            //src_path = path;

        }

        public DataRecord(byte[] datafile, int offset)
        {
            byte path_len;
            UInt16 date;
            UInt16 time;
            int data_len;
            int crc;
            byte[] fname;

            is_dir = datafile[offset++] == 0 ? false : true;
            path_len = datafile[offset++];
            offset++;
            offset++;

            date = (UInt16)(datafile[offset++] << 0);
            date |= (UInt16)(datafile[offset++] << 8);
            time = (UInt16)(datafile[offset++] << 0);
            time |= (UInt16)(datafile[offset++] << 8);

            data_len = read32(datafile, offset);
            offset += 4;

            crc = read32(datafile, offset);
            offset += 4;

            fname = new byte[path_len];
            Array.Copy(datafile, offset, fname, 0, path_len);
            offset += path_len;

            int crc_calc = (int)CRC32.calc(0, datafile, offset, data_len);

            if (crc_calc != crc)
            {
                throw new Exception("rec crc" + crc.ToString("X8"));
            }

            data = new byte[data_len];
            Array.Copy(datafile, offset, data, 0, data_len);

            ftime = getDateTime(date, time);

            name = System.Text.Encoding.UTF8.GetString(fname);
        }

        DateTime getDateTime(UInt16 date, UInt16 time)
        {
            int day = date & 31;
            int mon = (date >> 5) & 15;
            int yar = (date >> 9) + 1980;

            int hur = time >> 11;
            int min = (time >> 5) & 0x3F;
            int sec = (time & 0x1F) * 2;

            return new DateTime(yar, mon, day, hur, min, sec);
        }

        UInt16 getDate(DateTime dt)
        {
            return (UInt16)(dt.Day | (dt.Month << 5) | (dt.Year - 1980 << 9));
        }

        UInt16 getTime(DateTime dt)
        {
            return (UInt16)(dt.Second / 2 | (dt.Hour << 11) | (dt.Minute << 5));
        }

        public bool IsDir
        {
            get { return is_dir; }
        }

        public string getRecName()
        {
            return name;
        }

        public int getRecSize()
        {
            byte[] fname = System.Text.Encoding.UTF8.GetBytes(name);

            int hdr_size = 4 + 1 + 1 + 2 + 4 + 4;

            return hdr_size + (byte)fname.Length + data.Length;
        }

        public byte[] getRecData()
        {

            byte[] fname = System.Text.Encoding.UTF8.GetBytes(name);
            byte path_len = (byte)fname.Length;

            UInt16 date;
            UInt16 time;
            date = getDate(ftime);
            time = getTime(ftime);

            byte[] buff = new byte[getRecSize()];
            int ptr = 0;

            buff[ptr++] = (byte)(is_dir ? 1 : 0);
            buff[ptr++] = (byte)(path_len);

            buff[ptr++] = 0;
            buff[ptr++] = 0;

            buff[ptr++] = (byte)(date & 0xff);
            buff[ptr++] = (byte)(date >> 8);
            buff[ptr++] = (byte)(time & 0xff);
            buff[ptr++] = (byte)(time >> 8);

            copy32(buff, ptr, data.Length);
            ptr += 4;

            int crc = (int)CRC32.calc(0, data, 0, data.Length);
            copy32(buff, ptr, crc);
            ptr += 4;

            Array.Copy(fname, 0, buff, ptr, path_len);
            ptr += path_len;

            Array.Copy(data, 0, buff, ptr, data.Length);

            //Console.WriteLine(name + "|" + (is_dir ? "dir" : "file") + "|" + name_len + "|" + data.Length);

            return buff;
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

        public byte[] getFileData()
        {
            return data;
        }

    }
}

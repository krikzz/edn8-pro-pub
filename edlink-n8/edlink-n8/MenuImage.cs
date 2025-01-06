using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;
using System.Drawing;
using System.Security.Policy;

namespace edlink_n8
{

    class MenuImage
    {

        static byte[] pal_nes = new byte[]
        {
            0x6A, 0x6D, 0x6A, 0x00, 0x13, 0x80, 0x1E, 0x00, 0x8A, 0x39, 0x00, 0x7A, 0x55, 0x00, 0x56, 0x5A,
            0x00, 0x18, 0x4F, 0x10, 0x00, 0x3D, 0x1C, 0x00, 0x25, 0x32, 0x00, 0x00, 0x3D, 0x00, 0x00, 0x40,
            0x00, 0x00, 0x39, 0x24, 0x00, 0x2E, 0x55, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0xB9, 0xBC, 0xB9, 0x18, 0x50, 0xC7, 0x4B, 0x30, 0xE3, 0x73, 0x22, 0xD6, 0x95, 0x1F, 0xA9, 0x9D,
            0x28, 0x5C, 0x98, 0x37, 0x00, 0x7F, 0x4C, 0x00, 0x5E, 0x64, 0x00, 0x22, 0x77, 0x00, 0x02, 0x7E,
            0x02, 0x00, 0x76, 0x45, 0x00, 0x6E, 0x8A, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0xFF, 0xFF, 0xFF, 0x68, 0xA6, 0xFF, 0x8C, 0x9C, 0xFF, 0xB5, 0x86, 0xFF, 0xD9, 0x75, 0xFD, 0xE3,
            0x77, 0xB9, 0xE5, 0x8D, 0x68, 0xD4, 0x9D, 0x29, 0xB3, 0xAF, 0x0C, 0x7B, 0xC2, 0x11, 0x55, 0xCA,
            0x47, 0x46, 0xCB, 0x81, 0x47, 0xC1, 0xC5, 0x4A, 0x4D, 0x4A, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0xFF, 0xFF, 0xFF, 0xCC, 0xEA, 0xFF, 0xDD, 0xDE, 0xFF, 0xEC, 0xDA, 0xFF, 0xF8, 0xD7, 0xFE, 0xFC,
            0xD6, 0xF5, 0xFD, 0xDB, 0xCF, 0xF9, 0xE7, 0xB5, 0xF1, 0xF0, 0xAA, 0xDA, 0xFA, 0xA9, 0xC9, 0xFF,
            0xBC, 0xC3, 0xFB, 0xD7, 0xC4, 0xF6, 0xF6, 0xBE, 0xC1, 0xBE, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
        };


        const int plan_w = 64;//512/8
        const int screen_w = 32;//320/8
        const int screen_h = 28;//224/8

        public static void makeImage(string path, byte[] chr, byte[] vram, byte[] pal)
        {


            Bitmap pic = new Bitmap(screen_w * 8, screen_h * 8);


            int[] pal32 = getPal32(pal);
            //UInt16[] plan_a = getPlan(vram, 0xC000);
            //UInt16[] plan_b = getPlan(vram, 0xE000);


            int[] pixels = getPixels(chr, vram);

            renderImg(pic, pal32, pixels);

            Console.WriteLine("path: " + path);
            pic.Save(path);
        }



        static int[] getPixels(byte[] chr, byte[] vram)
        {

            
            int w = screen_w * 8;
            int h = screen_h * 8;

            int[] pixels = new int[w * h];

            for (int i = 0; i < pixels.Length; i++)
            {
                int x = i % w;
                int y = i / w;
                int tile_ptr = x / 8 + y / 8 * screen_w;

                int tile_idx = vram[tile_ptr * 2 + 0];
                int tile_atr = vram[tile_ptr * 2 + 1];

                pixels[i] = getPixel(chr, tile_idx, tile_atr, x, y);
                
            }

            return pixels;
        }

        public static int getPixel(byte[] chr, int tile_idx, int tile_atr, int x, int y)
        {
            int pixel;
            x %= 8;
            y %= 8;

            if ((tile_atr & 4) != 0)
            {
                tile_idx += 256;
            }

            int ptr = tile_idx * 16;
            ptr += y;

            int bit_ptr = 7 - x;

            pixel = 0;
            pixel |= (chr[ptr + 8] >> bit_ptr) & 1;
            pixel <<= 1;
            pixel |= (chr[ptr + 0] >> bit_ptr) & 1;

            pixel |= (tile_atr & 3) << 2;



            return pixel;
        }

        static int[] getPal32(byte[] pal)
        {
            int[] pal32 = new int[pal.Length];
            int alpha = 0xff0000;
            alpha <<= 8;

            for (int i = 0; i < pal32.Length; i++)
            {

                int r = pal_nes[pal[i] * 3 + 0];
                int g = pal_nes[pal[i] * 3 + 1];
                int b = pal_nes[pal[i] * 3 + 2];

                pal32[i] = alpha | (r << 16) | (g << 8) | (b << 0);

            }


            return pal32;
        }

        static void renderImg(Bitmap pic, int[] pal32, int[] pixels)
        {
            int w = screen_w * 8;

            for (int i = 0; i < pixels.Length; i++)
            {
                int x = i % w;
                int y = i / w;

                int rgb = pal32[pixels[i]];

                pic.SetPixel(x, y, Color.FromArgb(rgb));
            }
        }




    }
}

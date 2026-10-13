using System;
using System.Drawing;
using ZXing;

internal static class Program
{
    [STAThread]
    private static int Main(string[] args)
    {
        if (args.Length < 1)
            return 1;
        try
        {
            using var bmp = new Bitmap(args[0]);
            var reader = new BarcodeReader { AutoRotate = true };
            reader.Options.TryHarder = true;
            reader.Options.PossibleFormats = new[] { BarcodeFormat.QR_CODE };
            var result = reader.Decode(bmp);
            if (result == null || string.IsNullOrWhiteSpace(result.Text))
                return 2;
            Console.Out.Write(result.Text.Trim());
            return 0;
        }
        catch (Exception ex)
        {
            Console.Error.Write(ex.GetType().Name + ": " + ex.Message);
            return 3;
        }
    }
}

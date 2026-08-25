// =============================================================================
// Color picker: sampling render, tracking panel
// =============================================================================
using System;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Interop;
using System.Runtime.InteropServices;
using System.Text;
using System.Xml;
using System.Reflection;
using System.Windows.Documents;
using System.Windows.Media;
using System.Windows.Markup;
using Color = System.Windows.Media.Color;

public partial class AhkWpfEngine
{
    // ===== 取色器（Picker）：预览渲染在 daemon 进程内本地完成，零 IPC =====
    // 性能设计：采样 = 一次 BitBlt 抓 9×9 区域到内存 DIB（替代 81 次 GetPixel）；
    //           渲染 = 9×9 像素 WriteableBitmap 单 Image（NearestNeighbor 放大，单元素失效）；
    //           帧率双轨：面板位置/坐标/RGB 文本 30ms 跟手（33fps），
    //                     网格内容 100ms（10fps，用户确认足够）——移动时面板跟手、颜色内容 10fps
    private class PickerState
    {
        public Window Win;
        public string WinId;
        public System.Windows.Threading.DispatcherTimer Timer;
        public int LastX = -1;
        public int LastY = -1;
        public string LastHex = "";
        public long LastGridMs = 0;   // 上次网格刷新的 TickCount（100ms 节流）
        public int GridN = 9;
        public int CellSize = 12;   // DIP
        public double PanelW = 0;
        public double PanelH = 0;
        // 采样缓冲：9×9 32bpp 顶向下 DIB
        public IntPtr HdcMem = IntPtr.Zero;
        public IntPtr Hbm = IntPtr.Zero;
        public IntPtr DibBits = IntPtr.Zero;
        public byte[] PixelBuf;      // 9*9*4 BGRA
        public System.Windows.Media.Imaging.WriteableBitmap Wb;
    }
    private readonly System.Collections.Generic.Dictionary<string, PickerState> _pickers =
        new System.Collections.Generic.Dictionary<string, PickerState>();

    private void StartPicker(string winId, Window win, string param)
    {
        StopPicker(winId);
        int gridN = 9, cellSize = 12;
        if (!string.IsNullOrEmpty(param))
        {
            string[] pp = param.Split('|');
            if (pp.Length >= 1) int.TryParse(pp[0], out gridN);
            if (pp.Length >= 2) int.TryParse(pp[1], out cellSize);
        }
        // 合法性钳制（奇数 3..63，格子 2..24 DIP），异常回退默认值
        if (gridN < 3 || gridN > 63 || gridN % 2 == 0) gridN = 9;
        if (cellSize < 2 || cellSize > 24) cellSize = 12;
        var st = new PickerState { Win = win, WinId = winId, GridN = gridN, CellSize = cellSize };
        var panel = win.FindName("InfoPanel") as FrameworkElement;
        if (panel != null)
        {
            st.PanelW = panel.ActualWidth;
            st.PanelH = panel.ActualHeight;
        }
        // 创建 9×9 32bpp 顶向下 DIB（采样缓冲）
        try
        {
            st.HdcMem = CreateCompatibleDC(IntPtr.Zero);
            var bmi = new BITMAPINFO();
            bmi.bmiHeader.biSize = (uint)System.Runtime.InteropServices.Marshal.SizeOf(typeof(BITMAPINFOHEADER));
            bmi.bmiHeader.biWidth = st.GridN;
            bmi.bmiHeader.biHeight = -st.GridN;   // 顶向下
            bmi.bmiHeader.biPlanes = 1;
            bmi.bmiHeader.biBitCount = 32;
            bmi.bmiHeader.biCompression = 0;
            st.Hbm = CreateDIBSection(st.HdcMem, ref bmi, 0, out st.DibBits, IntPtr.Zero, 0);
            st.PixelBuf = new byte[st.GridN * st.GridN * 4];
        }
        catch { }

        // 9×9 WriteableBitmap 挂在 GridImage 上（单元素渲染，NearestNeighbor 放大）
        try
        {
            st.Wb = new System.Windows.Media.Imaging.WriteableBitmap(st.GridN, st.GridN, 96, 96,
                System.Windows.Media.PixelFormats.Bgr32, null);
            var img = win.FindName("GridImage") as Image;
            if (img != null)
                img.Source = st.Wb;
        }
        catch { }

        // 30ms：面板位置/坐标跟手；网格内容在 PickerTick 内按 100ms 节流
        st.Timer = new System.Windows.Threading.DispatcherTimer { Interval = TimeSpan.FromMilliseconds(30) };
        st.Timer.Tick += (s, e) => PickerTick(st);
        st.Timer.Start();
        _pickers[winId] = st;
    }

    private void StopPicker(string winId)
    {
        PickerState st;
        if (_pickers.TryGetValue(winId, out st))
        {
            try { if (st.Timer != null) st.Timer.Stop(); } catch { }
            try { if (st.Hbm != IntPtr.Zero) DeleteObject(st.Hbm); } catch { }
            try { if (st.HdcMem != IntPtr.Zero) DeleteDC(st.HdcMem); } catch { }
            _pickers.Remove(winId);
        }
    }

    private void PickerTick(PickerState st)
    {
        try
        {
            var win = st.Win;
            if (win == null || !win.IsLoaded || st.Hbm == IntPtr.Zero || st.Wb == null)
            {
                StopPicker(st.WinId);
                return;
            }
            POINT pt;
            if (!GetCursorPos(out pt))
                return;
            int x = pt.x, y = pt.y;
            bool moved = (x != st.LastX || y != st.LastY);
            int half = (st.GridN - 1) / 2;

            // 中心色（每 tick 读 1 像素，判断静止 + RGB 文本用）
            string centerHex = "";
            IntPtr hdc1 = GetDC(IntPtr.Zero);
            if (hdc1 != IntPtr.Zero)
            {
                try
                {
                    uint v = GetPixel(hdc1, x, y);
                    centerHex = (v & 0xFF).ToString("X2") + ((v >> 8) & 0xFF).ToString("X2") + ((v >> 16) & 0xFF).ToString("X2");
                }
                finally { ReleaseDC(IntPtr.Zero, hdc1); }
            }

            // 完全静止（位置与中心色都没变）→ 零渲染
            if (!moved && centerHex == st.LastHex)
                return;

            // 高频轨（30ms）：面板位置 / 坐标 —— 移动时跟手
            if (moved)
            {
                var coord = win.FindName("CoordText") as TextBlock;
                if (coord != null)
                    coord.Text = x + "," + y;

                var panel = win.FindName("InfoPanel") as FrameworkElement;
                if (panel != null)
                {
                    double scale = 1.0;
                    try { scale = GetDpiForSystem() / 96.0; } catch { }
                    double dipX = x / scale, dipY = y / scale;
                    double pw = st.PanelW > 0 ? st.PanelW : panel.ActualWidth;
                    double ph = st.PanelH > 0 ? st.PanelH : panel.ActualHeight;
                    double px = dipX + 16, py = dipY + 16;
                    double wD = win.ActualWidth, hD = win.ActualHeight;
                    if (px + pw > wD)
                        px = dipX - 16 - pw;
                    if (py + ph > hD)
                        py = dipY - 16 - ph;
                    if (px < 0) px = 0;
                    if (py < 0) py = 0;
                    Canvas.SetLeft(panel, px);
                    Canvas.SetTop(panel, py);
                }
            }

            // RGB 文本：位置或中心色任一变化都更新（盖红窗位置不动时也实时刷新）
            if (moved || centerHex != st.LastHex)
            {
                var rgb = win.FindName("RgbText") as TextBlock;
                if (rgb != null)
                    rgb.Text = "#" + centerHex;
            }

            // 低频轨（100ms 节流）：9×9 网格内容（移动时面板 33fps 跟手，网格内容恒 10fps）
            long now = System.Environment.TickCount;
            if (now - st.LastGridMs >= 100)
            {
                IntPtr hdcScreen = GetDC(IntPtr.Zero);
                if (hdcScreen != IntPtr.Zero)
                {
                    try
                    {
                        SelectObject(st.HdcMem, st.Hbm);
                        BitBlt(st.HdcMem, 0, 0, st.GridN, st.GridN, hdcScreen, x - half, y - half, 0x00CC0020);
                    }
                    finally { ReleaseDC(IntPtr.Zero, hdcScreen); }
                }
                byte[] buf = st.PixelBuf;
                int stride = st.GridN * 4;
                for (int i = 0; i < st.GridN * st.GridN; i++)
                {
                    int off = i * 4;
                    buf[off] = System.Runtime.InteropServices.Marshal.ReadByte(st.DibBits, off);
                    buf[off + 1] = System.Runtime.InteropServices.Marshal.ReadByte(st.DibBits, off + 1);
                    buf[off + 2] = System.Runtime.InteropServices.Marshal.ReadByte(st.DibBits, off + 2);
                    buf[off + 3] = 255;
                }
                st.Wb.WritePixels(new System.Windows.Int32Rect(0, 0, st.GridN, st.GridN), buf, stride, 0);

                // 中心格高亮框（叠层）
                var cbox = win.FindName("CenterBox") as FrameworkElement;
                if (cbox != null)
                {
                    Canvas.SetLeft(cbox, half * st.CellSize - 1);
                    Canvas.SetTop(cbox, half * st.CellSize - 1);
                }
                st.LastGridMs = now;
            }

            st.LastX = x;
            st.LastY = y;
            st.LastHex = centerHex;
        }
        catch { }
    }

}

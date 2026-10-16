param(
  [string]$Action,      # tap | wheel | shot | tapwheelshot
  [int]$X = 0,
  [int]$Y = 0,
  [int]$Taps = 0,
  [int]$Delta = -120,
  [string]$Out = "",
  [int]$Hwnd = 0,
  [int]$WaitMs = 800
)
Add-Type @'
using System;
using System.Drawing;
using System.Runtime.InteropServices;
public class UxNav {
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint flags, uint dx, uint dy, int data, UIntPtr extra);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int cmd);
  public struct RECT { public int Left, Top, Right, Bottom; }
  public static void Tap(IntPtr h, int wx, int wy) {
    ShowWindow(h, 9);
    RECT r; GetWindowRect(h, out r);
    SetForegroundWindow(h); System.Threading.Thread.Sleep(250);
    SetCursorPos(r.Left + wx, r.Top + wy); System.Threading.Thread.Sleep(120);
    mouse_event(0x02,0,0,0,UIntPtr.Zero); mouse_event(0x04,0,0,0,UIntPtr.Zero);
  }
  public static void WheelTaps(IntPtr h, int wx, int wy, int taps, int delta) {
    RECT r; GetWindowRect(h, out r);
    SetForegroundWindow(h); System.Threading.Thread.Sleep(250);
    SetCursorPos(r.Left + wx, r.Top + wy); System.Threading.Thread.Sleep(100);
    for (int i = 0; i < taps; i++) { mouse_event(0x0800, 0, 0, delta, UIntPtr.Zero); System.Threading.Thread.Sleep(90); }
  }
  public static void Shot(IntPtr h, string path) {
    RECT r; GetWindowRect(h, out r);
    Bitmap bmp = new Bitmap(r.Right - r.Left, r.Bottom - r.Top);
    Graphics g = Graphics.FromImage(bmp);
    g.CopyFromScreen(r.Left, r.Top, 0, 0, bmp.Size);
    bmp.Save(path, System.Drawing.Imaging.ImageFormat.Png);
    g.Dispose(); bmp.Dispose();
  }
}
'@ -ReferencedAssemblies System.Drawing

$h = [IntPtr]$Hwnd
switch ($Action) {
  'tap' { [UxNav]::Tap($h, $X, $Y) }
  'wheel' { [UxNav]::WheelTaps($h, $X, $Y, $Taps, $Delta); Start-Sleep -Milliseconds $WaitMs }
  'shot' { [UxNav]::Shot($h, $Out) }
  'tapwheelshot' {
    [UxNav]::Tap($h, $X, $Y)
    Start-Sleep -Milliseconds $WaitMs
    [UxNav]::WheelTaps($h, 500, 400, $Taps, $Delta)
    Start-Sleep -Milliseconds 500
    [UxNav]::Shot($h, $Out)
  }
  'tapshot' {
    [UxNav]::Tap($h, $X, $Y)
    Start-Sleep -Milliseconds $WaitMs
    [UxNav]::Shot($h, $Out)
  }
}
'done'
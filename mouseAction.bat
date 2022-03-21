// 2>nul||@goto :batch
/*
:batch
@echo off
setlocal

:: find csc.exe
set "csc="
for /r "%SystemRoot%\Microsoft.NET\Framework\" %%# in ("*csc.exe") do  set "csc=%%#"

if not exist "%csc%" (
   echo no .net framework installed
   exit /b 10
)

if not exist "%~n0.exe" (
   call %csc% /nologo /warn:0 /out:"%~n0.exe" "%~dpsfnx0" || (
      exit /b %errorlevel% 
   )
)
%~n0.exe %*
endlocal & exit /b %errorlevel%

*/

// To create this I've stole code from :
// http://inputsimulator.codeplex.com/
// https://stackoverflow.com/a/8022534/388389

using System;
using System.Runtime.InteropServices;
using System.Threading;

namespace MouseMover
{
    public class MouseSimulator
    {
        [DllImport("user32.dll", SetLastError = true)]
        static extern uint SendInput(uint nInputs, ref INPUT pInputs, int cbSize);
        [DllImport("user32.dll")]
        public static extern int SetCursorPos(int x, int y);
        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool GetCursorPos(out POINT lpPoint);
        //----//
        [DllImport("user32.dll")]
        public static extern bool ClientToScreen(IntPtr hWnd, ref POINT lpPoint);
        [DllImport("user32.dll")]
        static extern void ClipCursor(ref Rect rect);
        [DllImport("user32.dll")]
        static extern void ClipCursor(IntPtr rect);
        [DllImport("user32.dll", SetLastError = true)]
        static extern IntPtr CopyImage(IntPtr hImage, uint uType, int cxDesired, int cyDesired, uint fuFlags);
        [DllImport("user32.dll")]
        static extern bool CopyRect(out Rect lprcDst, [In] ref Rect lprcSrc);
		[DllImport("user32.dll")]
		static extern int GetSystemMetrics(SystemMetric smIndex);


        [StructLayout(LayoutKind.Sequential)]
        struct INPUT
        {
            public SendInputEventType type;
            public MouseKeybdhardwareInputUnion mkhi;
        }
        [StructLayout(LayoutKind.Explicit)]
        struct MouseKeybdhardwareInputUnion
        {
            [FieldOffset(0)]
            public MouseInputData mi;

            [FieldOffset(0)]
            public KEYBDINPUT ki;

            [FieldOffset(0)]
            public HARDWAREINPUT hi;
        }
        [StructLayout(LayoutKind.Sequential)]
        struct KEYBDINPUT
        {
            public ushort wVk;
            public ushort wScan;
            public uint dwFlags;
            public uint time;
            public IntPtr dwExtraInfo;
        }
        [StructLayout(LayoutKind.Sequential)]
        struct HARDWAREINPUT
        {
            public int uMsg;
            public short wParamL;
            public short wParamH;
        }
        [StructLayout(LayoutKind.Sequential)]
        public struct POINT
        {
            public int X;
            public int Y;

            public POINT(int x, int y)
            {
                this.X = x;
                this.Y = y;
            }
        }
        struct MouseInputData
        {
            public int dx;
            public int dy;
            public uint mouseData;
            public MouseEventFlags dwFlags;
            public uint time;
            public IntPtr dwExtraInfo;
        }
        struct Rect
        {
            public long left;
            public long top;
            public long right;
            public long bottom;

            public Rect(long left,long top,long right , long bottom)
            {
                this.left = left;
                this.top = top;
                this.right = right;
                this.bottom = bottom;
            }
        }

        [Flags]
        enum MouseEventFlags : uint
        {
            MOUSEEVENTF_MOVE = 0x0001,
            MOUSEEVENTF_LEFTDOWN = 0x0002,
            MOUSEEVENTF_LEFTUP = 0x0004,
            MOUSEEVENTF_RIGHTDOWN = 0x0008,
            MOUSEEVENTF_RIGHTUP = 0x0010,
            MOUSEEVENTF_MIDDLEDOWN = 0x0020,
            MOUSEEVENTF_MIDDLEUP = 0x0040,
            MOUSEEVENTF_XDOWN = 0x0080,
            MOUSEEVENTF_XUP = 0x0100,
            MOUSEEVENTF_WHEEL = 0x0800,
            MOUSEEVENTF_VIRTUALDESK = 0x4000,
            MOUSEEVENTF_ABSOLUTE = 0x8000
        }
        enum SendInputEventType : int
        {
            InputMouse,
            InputKeyboard,
            InputHardware
        }
		
		enum SystemMetric
		{
		  SM_CXSCREEN = 0,
		  SM_CYSCREEN = 1,
		}
		
		static int CalculateAbsoluteCoordinateX(int x)
		{
		  return (x * 65536) / GetSystemMetrics(SystemMetric.SM_CXSCREEN);
		}

		static int CalculateAbsoluteCoordinateY(int y)
		{
		  return (y * 65536) / GetSystemMetrics(SystemMetric.SM_CYSCREEN);
		}

        static void DoubleClick()
        {
            ClickLeftMouseButton();
            //System.Threading.Thread.Sleep(100);
            ClickLeftMouseButton();
        }

        static void MoveMouseBy(int x, int y) {
            INPUT mouseInput = new INPUT();
            mouseInput.type = SendInputEventType.InputMouse;
            mouseInput.mkhi.mi.dwFlags = MouseEventFlags.MOUSEEVENTF_MOVE;
            mouseInput.mkhi.mi.dx = x;
            mouseInput.mkhi.mi.dy = y;
            SendInput(1, ref mouseInput, Marshal.SizeOf(mouseInput));
        }

        static void MoveMouseTo(int x, int y) {
            INPUT mouseInput = new INPUT();
            mouseInput.type = SendInputEventType.InputMouse;
            mouseInput.mkhi.mi.dwFlags = MouseEventFlags.MOUSEEVENTF_MOVE|MouseEventFlags.MOUSEEVENTF_ABSOLUTE;
            mouseInput.mkhi.mi.dx = CalculateAbsoluteCoordinateX(x);
            mouseInput.mkhi.mi.dy = CalculateAbsoluteCoordinateY(y);
            SendInput(1, ref mouseInput, Marshal.SizeOf(mouseInput));

        }
        static void DragMouseBy(int x, int y) {

            INPUT mouseInput = new INPUT();
            mouseInput.type = SendInputEventType.InputMouse;
            mouseInput.mkhi.mi.dwFlags =  MouseEventFlags.MOUSEEVENTF_LEFTDOWN;
            SendInput(1, ref mouseInput, Marshal.SizeOf(mouseInput));

            //does not work with MouseEventFlags.MOUSEEVENTF_MOVE | MouseEventFlags.MOUSEEVENTF_LEFTDOWN
            // so two consec. send inputs
            mouseInput.mkhi.mi.dwFlags = MouseEventFlags.MOUSEEVENTF_MOVE;
            mouseInput.mkhi.mi.dx = CalculateAbsoluteCoordinateX(x);
            mouseInput.mkhi.mi.dy = CalculateAbsoluteCoordinateY(y);
            SendInput(1, ref mouseInput, Marshal.SizeOf(mouseInput));

            mouseInput.mkhi.mi.dwFlags = MouseEventFlags.MOUSEEVENTF_LEFTUP;
            SendInput(1, ref mouseInput, Marshal.SizeOf(mouseInput));

        }
        static void DragMouseTo(int x, int y) {
            INPUT mouseInput = new INPUT();
            mouseInput.type = SendInputEventType.InputMouse;
            mouseInput.mkhi.mi.dwFlags = MouseEventFlags.MOUSEEVENTF_LEFTDOWN;
            SendInput(1, ref mouseInput, Marshal.SizeOf(mouseInput));

            mouseInput.mkhi.mi.dwFlags = MouseEventFlags.MOUSEEVENTF_MOVE|MouseEventFlags.MOUSEEVENTF_ABSOLUTE;
            mouseInput.mkhi.mi.dx = x;
            mouseInput.mkhi.mi.dy = y;
            SendInput(1, ref mouseInput, Marshal.SizeOf(mouseInput));

            mouseInput.mkhi.mi.dwFlags = MouseEventFlags.MOUSEEVENTF_LEFTUP;
            SendInput(1, ref mouseInput, Marshal.SizeOf(mouseInput));
        }
        

        //There's conflict between negative DWOR values and UInt32 so there are two methods
        // for scrolling
        static void ScrollUp(int amount) {
            INPUT mouseInput = new INPUT();
            mouseInput.type = SendInputEventType.InputMouse;
            mouseInput.mkhi.mi.dwFlags = MouseEventFlags.MOUSEEVENTF_WHEEL;
            mouseInput.mkhi.mi.mouseData = (UInt32)amount;
            SendInput(1, ref mouseInput, Marshal.SizeOf(mouseInput));
        }

        static void ScrollDown(int amount)
        {
            INPUT mouseInput = new INPUT();
            mouseInput.type = SendInputEventType.InputMouse;
            mouseInput.mkhi.mi.dwFlags = MouseEventFlags.MOUSEEVENTF_WHEEL;
            mouseInput.mkhi.mi.mouseData = 0-(UInt32)amount;
            SendInput(1, ref mouseInput, Marshal.SizeOf(mouseInput));
        }


        static void ClickLeftMouseButton()
        {

            INPUT mouseInput = new INPUT();

            mouseInput.type = SendInputEventType.InputMouse;
            mouseInput.mkhi.mi.dwFlags = MouseEventFlags.MOUSEEVENTF_LEFTDOWN;
            SendInput(1, ref mouseInput, Marshal.SizeOf(mouseInput));

            //mouseInput.type = SendInputEventType.InputMouse;
            mouseInput.mkhi.mi.dwFlags = MouseEventFlags.MOUSEEVENTF_LEFTUP;
            SendInput(1, ref mouseInput, Marshal.SizeOf(mouseInput));

        }
        static void ClickRightMouseButton()
        {
            INPUT mouseInput = new INPUT();

            mouseInput.type = SendInputEventType.InputMouse;
            mouseInput.mkhi.mi.dwFlags = MouseEventFlags.MOUSEEVENTF_RIGHTDOWN;
            SendInput(1, ref mouseInput, Marshal.SizeOf(mouseInput));

            //mouseInput.type = SendInputEventType.InputMouse;
            mouseInput.mkhi.mi.dwFlags = MouseEventFlags.MOUSEEVENTF_RIGHTUP;
            SendInput(1, ref mouseInput, Marshal.SizeOf(mouseInput));

        }


        static void getCursorPos()
        {
            POINT p;
            if (GetCursorPos(out p))
            {
                Console.WriteLine(Convert.ToString(p.X) + "x" + Convert.ToString(p.Y));
            }
            else
            {
                Console.WriteLine("unknown");
            }
        }

        static void ScrollCaller(string ammountStr,Boolean up)
        {
            try
            {
                int ammount = int.Parse(ammountStr);
                if (ammount < 0)
                {
                    Console.WriteLine("Scroll ammount must be positive number");
                    System.Environment.Exit(3);
                }
                if (up)
                {
                    ScrollUp(ammount);
                }
                else
                {
                    ScrollDown(ammount);
                }
            }
            catch (Exception)
            {
                Console.WriteLine("Number parsing error");
                System.Environment.Exit(2);
            }

        }

        public static void Main(String[] args) {
            while(true){
                Thread.Sleep(3000);
                ClickRightMouseButton();
                Thread.Sleep(3000);
                MoveMouseBy(10, -10);
                Thread.Sleep(3000);
                ClickLeftMouseButton();
                Thread.Sleep(3000);
                MoveMouseBy(-10, 10);
            }
        }
    }
}
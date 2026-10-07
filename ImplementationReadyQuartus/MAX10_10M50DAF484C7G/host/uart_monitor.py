"""DE10-Lite binary UART monitor; requires pyserial."""
import tkinter as tk
from tkinter import ttk, scrolledtext, messagebox
from pathlib import Path
import subprocess, sys, threading, queue

def main():
    root=tk.Tk(); root.title('IGOR - DE10-Lite MAX10 UART Lab'); root.geometry('1050x680')
    f=ttk.Frame(root,padding=18); f.pack(fill='both',expand=True)
    ttk.Label(f,text='DE10-Lite | 10M50DAF484C7G',font=('Segoe UI',18,'bold')).pack(anchor='w')
    ttk.Label(f,text='115200 8N1 | USB-UART TTL 3.3 V | TX adapter -> JP1 pin1; RX -> pin2; GND -> pin12').pack(anchor='w',pady=10)
    row=ttk.Frame(f);row.pack(fill='x');ttk.Label(row,text='COM adapter:').pack(side='left')
    port=ttk.Combobox(row,width=20);port.pack(side='left',padx=8)
    log=scrolledtext.ScrolledText(f,font=('Consolas',10),wrap='word')
    messages=queue.Queue();active=[None];busy=[False];buttons=[]
    def refresh():
        try:
            from serial.tools import list_ports
            ps=[x.device for x in list_ports.comports()];port['values']=ps
            if ps and not port.get():port.set(ps[0])
            messages.put('COM: '+(', '.join(ps) if ps else 'Tidak ada adapter terdeteksi. USB-Blaster bukan port COM UART.'))
        except ImportError:messagebox.showerror('Dependensi','Jalankan SETUP_UART.bat untuk memasang pyserial.')
    ttk.Button(row,text='Refresh COM',command=refresh).pack(side='left')
    actions=ttk.Frame(f);actions.pack(fill='x',pady=15)
    state=tk.StringVar(value='Program SOF, SW2/SW3 OFF, lepas KEY1, lalu tekan-lepas KEY0.')
    ttk.Label(f,textvariable=state).pack(anchor='w',pady=8)
    log.pack(fill='both',expand=True)
    log.insert('end','Monitor paket biner; bukan terminal ASCII. Status awal fault=5 berarti belum ada map.\nTekan KEY0 sebelum SETIAP tes DWA. NN100 dan ROM tidak membutuhkan map.\n\n')
    def run(action,scene=None):
        if busy[0]:return
        if not port.get().strip():messagebox.showerror('Port','Pilih port USB-UART.');return
        cmd=[sys.executable,'-u',str(Path(__file__).with_name('igor_uart.py')),'--port',port.get().strip(),action]
        if action=='status':cmd+=['--trace']
        if scene:cmd+=['--map',scene]
        busy[0]=True;state.set('Berjalan: '+action+(' / '+scene if scene else ''))
        for b in buttons:b.configure(state='disabled')
        def worker():
            try:
                active[0]=subprocess.Popen(cmd,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,creationflags=subprocess.CREATE_NO_WINDOW if sys.platform=='win32' else 0)
                for line in active[0].stdout:messages.put(line.rstrip())
                messages.put(('done',active[0].wait()))
            except Exception as exc:messages.put(str(exc));messages.put(('done',1))
            finally:active[0]=None
        threading.Thread(target=worker,daemon=True).start()
    for title,action,scene in [('Status / TX-RX','status',None),('ROM 6020','rom-check',None),('NN100','nn-test',None),('DWA empty','dwa-demo','empty'),('DWA blocked','dwa-demo','blocked'),('DWA unknown','dwa-demo','unknown')]:
        b=ttk.Button(actions,text=title,command=lambda a=action,s=scene:run(a,s));b.pack(side='left',padx=(0,8));buttons.append(b)
    def poll():
        for _ in range(100):
            try:item=messages.get_nowait()
            except queue.Empty:break
            if isinstance(item,tuple):
                busy[0]=False;state.set('Selesai' if item[1]==0 else 'Gagal; periksa log dan reset KEY0.')
                for b in buttons:b.configure(state='normal')
                item='EXIT CODE: '+str(item[1])
            log.insert('end',item+'\n');log.see('end')
        root.after(75,poll)
    def close():
        if active[0] is not None:
            if not messagebox.askyesno('Tes aktif','Hentikan tes? Reset KEY0 sebelum percobaan berikutnya.'):return
            active[0].terminate()
        root.destroy()
    root.protocol('WM_DELETE_WINDOW',close);refresh();poll();root.mainloop()

if __name__=='__main__':main()

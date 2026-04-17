import tkinter as tk
import sys
import os

def main():
    if len(sys.argv) < 2:
        print("Usage: python post.py <input_file_path>")
        sys.exit(1)

    input_file = sys.argv[1]

    root = tk.Tk()
    root.title("和露薇说话")
    root.geometry("460x80")
    root.resizable(False, False)
    root.attributes("-topmost", True)

    root.update_idletasks()
    x = (root.winfo_screenwidth() - 460) // 2
    y = (root.winfo_screenheight() - 80) // 2
    root.geometry(f"460x80+{x}+{y}")

    frame = tk.Frame(root, padx=10, pady=10)
    frame.pack(fill=tk.BOTH, expand=True)

    tk.Label(frame, text="说：").pack(side=tk.LEFT)

    entry = tk.Entry(frame, width=30, font=("Microsoft YaHei", 11))
    entry.pack(side=tk.LEFT, padx=5)

    status_label = tk.Label(frame, text="", fg="gray", font=("Microsoft YaHei", 9))
    status_label.pack(side=tk.LEFT, padx=5)

    def update_status(text, color="gray"):
        status_label.config(text=text, fg=color)
        root.update()

    def submit(event=None):
        text = entry.get().strip()
        if not text:
            update_status("输入不能为空", "red")
            root.after(1000, lambda: update_status(""))
            return

        update_status("发送中...", "orange")

        try:
            with open(input_file, "w", encoding="utf-8") as f:
                f.write(text)
                f.flush()
                os.fsync(f.fileno())

            update_status("✓ 已发送", "green")
            root.after(800, root.destroy)

        except Exception as e:
            update_status(f"发送失败", "red")
            root.after(2000, lambda: update_status(""))

    def cancel(event=None):
        root.destroy()

    btn = tk.Button(frame, text="发送", command=submit, width=6)
    btn.pack(side=tk.LEFT, padx=2)

    entry.bind("<Return>", submit)
    entry.bind("<Escape>", cancel)
    root.bind("<Escape>", cancel)

    root.protocol("WM_DELETE_WINDOW", cancel)

    root.after(100, lambda: entry.focus_force())

    root.mainloop()

if __name__ == "__main__":
    main()
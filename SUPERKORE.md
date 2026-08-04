# SuperKore OpenKore Release

แพ็ก OpenKore สำเร็จรูปสำหรับลูกค้า SuperKore (มีปลั๊กอิน `wsbridge` แล้ว)

## ติดตั้ง / กู้คืนเมื่อไฟล์หาย

```bash
git clone https://github.com/thanakon228/SuperKore-OpenKore.git
# หรือถ้ามีสิทธิ์ private:
# git clone git@github.com:thanakon228/SuperKore-OpenKore.git
```

ใน Pilot UI ตั้ง **โฟลเดอร์ OpenKore** เป็น path ที่ clone มา เช่น:

`/home/you/SuperKore-OpenKore`

จากนั้นใส่คีย์ · เลือกเซิร์ฟ · เพิ่มโปรไฟล์ · สตาร์ท connector แล้วเริ่มบอท

## สิ่งที่รวมอยู่

- OpenKore upstream (snapshot)
- `plugins/wsbridge/` — อุโมงค์ผ่าน SuperKore connector
- `control/sys.txt` — โหลด `wsbridge` ใน `loadPlugins_list`
- `control/config.superkore.example.txt` — ตัวอย่างคีย์ bridge (ไม่มีรหัสผ่าน)

## ความปลอดภัย

- ห้าม commit `username` / `password` / คีย์เช่า `sk_...`
- config จริงของแต่ละ ID อยู่ใน Pilot: `~/.superkore/pilot/ok-profiles/<id>/control/`

## อัปเดต

```bash
cd SuperKore-OpenKore
git pull
```

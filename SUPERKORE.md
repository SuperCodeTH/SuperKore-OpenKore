# SuperKore OpenKore Release

แพ็ก OpenKore สำเร็จรูปสำหรับลูกค้า SuperKore (มีปลั๊กอิน `wsbridge`)

## ดาวน์โหลด / กู้คืนเมื่อไฟล์หาย

**Clone (แนะนำ)**

```bash
git clone https://github.com/SuperCodeTH/SuperKore-OpenKore.git
cd SuperKore-OpenKore
```

**ดาวน์โหลด ZIP**

- ล่าสุดบน `main`: https://github.com/SuperCodeTH/SuperKore-OpenKore/archive/refs/heads/main.zip
- หน้า Releases (ถ้ามีแท็ก): https://github.com/SuperCodeTH/SuperKore-OpenKore/releases

ใน Pilot UI ตั้ง **โฟลเดอร์ OpenKore** เป็น path ที่แตก/clone มา เช่น `/home/you/SuperKore-OpenKore`

## สิ่งที่รวมอยู่

- OpenKore upstream (snapshot)
- `plugins/wsbridge/` — อุโมงค์ผ่าน SuperKore connector
- `control/sys.txt` — โหลด `wsbridge`
- `control/config.superkore.example.txt` — ตัวอย่างคีย์ bridge (ไม่มีรหัสผ่าน)

## แพ็กเกจต่อเซิร์ฟ

เซิร์ฟ RoPlay แต่ละตัวอาจต้องจูน tables / packetver คนละแบบ  
เจ้าของเก็บลิงก์แพ็กเกจใน Owner Admin ต่อเซิร์ฟ และอัปเดต repo/branch/release นี้เมื่อแก้

## ความปลอดภัย

- ห้าม commit `username` / `password` / คีย์เช่า `sk_...`
- config จริงของแต่ละ ID อยู่ใน Pilot: `~/.superkore/pilot/ok-profiles/<id>/control/`

## อัปเดต

```bash
cd SuperKore-OpenKore
git pull
```

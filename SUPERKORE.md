# SuperKore OpenKore Release

โครงสร้าง repo:

```text
SuperKore-OpenKore/
  README.md
  SUPERKORE.md
  openkore/          ← ไฟล์ OpenKore ทั้งหมด (ชี้ Pilot มาที่นี่)
    openkore.pl
    control/
    plugins/wsbridge/
    tables/
    ...
```

## ดาวน์โหลด / กู้คืนเมื่อไฟล์หาย

**Clone**

```bash
git clone https://github.com/SuperCodeTH/SuperKore-OpenKore.git
```

ใน Pilot UI ตั้ง **โฟลเดอร์ OpenKore** เป็น:

`/path/to/SuperKore-OpenKore/openkore`

**ดาวน์โหลด ZIP**

- https://github.com/SuperCodeTH/SuperKore-OpenKore/archive/refs/heads/main.zip  
  แตกแล้วใช้โฟลเดอร์ `SuperKore-OpenKore-main/openkore`
- Releases: https://github.com/SuperCodeTH/SuperKore-OpenKore/releases

## สิ่งที่รวมใน `openkore/`

- OpenKore upstream (snapshot)
- `plugins/wsbridge/` — อุโมงค์ SuperKore connector
- `control/sys.txt` — โหลด `wsbridge`
- `control/config.superkore.example.txt` — ตัวอย่างคีย์ bridge (ไม่มีรหัสผ่าน)

## แพ็กเกจต่อเซิร์ฟ

เซิร์ฟ RoPlay แต่ละตัวอาจจูน tables / packetver คนละแบบ  
เจ้าของเก็บลิงก์แพ็กเกจใน Owner Admin ต่อเซิร์ฟ และอัปเดต repo นี้เมื่อแก้

## ความปลอดภัย

- ห้าม commit `username` / `password` / คีย์เช่า `sk_...`
- config จริงของแต่ละ ID อยู่ใน Pilot: `~/.superkore/pilot/ok-profiles/<id>/control/`

## อัปเดต

```bash
cd SuperKore-OpenKore
git pull
```

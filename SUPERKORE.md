# SuperKore OpenKore Release

โครงสร้าง repo:

```text
SuperKore-OpenKore/
  README.md
  SUPERKORE.md
  openkore/              ← ไฟล์ OpenKore ทั้งหมด (ชี้ Pilot มาที่นี่)
  serverconfig/          ← recvpackets / จูนต่อเซิร์ฟ
    _template/
    eternal-origin.com/
    ro-ronin.com/
```

## ดาวน์โหลด / กู้คืน

```bash
git clone https://github.com/SuperCodeTH/SuperKore-OpenKore.git
```

Pilot **โฟลเดอร์ OpenKore** = `/path/to/SuperKore-OpenKore/openkore`

ZIP: https://github.com/SuperCodeTH/SuperKore-OpenKore/archive/refs/heads/main.zip  
Releases: https://github.com/SuperCodeTH/SuperKore-OpenKore/releases

## serverconfig (recvpackets ต่อเซิร์ฟ)

ดูรายละเอียดใน [`serverconfig/README.md`](./serverconfig/README.md)  
เจ้าของอัปไฟล์จูนของแต่ละเซิร์ฟเข้าโฟลเดอร์ย่อย แล้วลูกค้าคัดลอกไปใช้กับ OpenKore

## ความปลอดภัย

ห้าม commit username / password / คีย์ `sk_...`

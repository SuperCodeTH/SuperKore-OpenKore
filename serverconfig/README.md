# serverconfig — recvpackets ต่อเซิร์ฟ

แต่ละเซิร์ฟ RoPlay ใช้ `recvpackets` คนละชุด  
วางไฟล์จูนของเซิร์ฟไว้ในโฟลเดอร์ย่อย (แนะนำใช้ชื่อโดเมนเซิร์ฟ)

```text
serverconfig/
  README.md
  _template/
    recvpackets.txt      ← ตัวอย่างว่าง / คัดลอกไปใช้
  eternal-origin.com/
    recvpackets.txt
  ro-ronin.com/
    recvpackets.txt
```

## วิธีใช้กับ OpenKore

1. คัดลอก `recvpackets.txt` ของเซิร์ฟที่เล่นไปใส่ใน `openkore/tables/` (หรือ tables ตาม serverType ที่ใช้)
2. หรือใน Pilot ใช้ config ต่อโปรไฟล์ชี้ tables ที่ถูกต้อง

ห้ามใส่รหัสผ่านบัญชีในโฟลเดอร์นี้

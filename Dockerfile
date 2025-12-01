# เริ่มจาก Node.js รุ่นเล็ก
FROM node:18-alpine

# เข้าไปทำงานในโฟลเดอร์ /app
WORKDIR /app

# ก๊อปไฟล์ package.json ไปก่อนเพื่อลงโปรแกรม
COPY package*.json ./

# สั่งลงโปรแกรม (express)
RUN npm install

# ก๊อปไฟล์ที่เหลือ (server.js) ตามไป
COPY . .

# บอกว่าจะใช้พอร์ต 3000
EXPOSE 3000

# คำสั่งรันเมื่อกล่องเริ่มทำงาน
CMD ["node", "server.js"]
const fs = require('fs');

const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6NSwidXNlcm5hbWUiOiJtYW1hZCIsInJvbGUiOiJjcmV3IiwiaWF0IjoxNzg3NDAwOTg0LCJleHAiOjE3ODgwMDU3ODR9.CNsN-o1u6yjFT2EVGwNebLQ-uqIefo9GW0-7n9CoDzs';

const form = new FormData();
form.append('lat', '-7.953539');
form.append('lng', '112.632111');
form.append('foto', new Blob([fs.readFileSync('test-foto.jpg')], { type: 'image/jpeg' }), 'test-foto.jpg');

fetch('http://localhost:3000/api/attendance/masuk', {
  method: 'POST',
  headers: { Authorization: `Bearer ${token}` },
  body: form,
})
  .then((res) => res.json())
  .then((data) => console.log(data))
  .catch((err) => console.error('Gagal:', err));
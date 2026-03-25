// Minimal Express mock server to support local dev mode
const express = require('express');
const multer = require('multer');
const cors = require('cors');
const app = express();
const upload = multer();
app.use(cors());
app.use(express.json());

let categories = [{ id: 1, nameKh: 'រង្វិល', nameEn: 'Lights', active: true }];
let items = [{ id: 1, categoryId: 1, key: 'headlight', nameKh: 'ភ្លើងមុខ', nameEn: 'Headlight', requiresPhotoOnFail: true, active: true }];
let checks = [];
let issues = [];

app.post('/auth/login', (req, res) => {
    const { username } = req.body;
    // Provide a long-lived refresh token for dev mode (non-secure)
    const refreshToken = 'mock-refresh-' + Date.now();
    res.json({ token: 'mock-token', refreshToken, user: { id: 1, username }, roles: ['SUPER_ADMIN'] });
});

app.post('/auth/refresh', (req, res) => {
    const { refreshToken } = req.body;
    if (!refreshToken || !refreshToken.startsWith('mock-refresh-')) return res.status(401).json({ error: 'invalid_refresh' });
    // issue a new token and rotate refresh token in dev
    const newRefresh = 'mock-refresh-' + Date.now();
    res.json({ token: 'mock-token-' + Date.now(), refreshToken: newRefresh, user: { id: 1, username: 'mock' }, roles: ['SUPER_ADMIN'] });
});

app.get('/safety/categories', (req, res) => res.json(categories));
app.post('/safety/categories', (req, res) => { const c = { id: Date.now(), ...req.body }; categories.push(c); res.json(c); });

app.get('/safety/items', (req, res) => res.json(items));
app.post('/safety/items', (req, res) => { const it = { id: Date.now(), ...req.body }; items.push(it); res.json(it); });

app.get('/safety/checks', (req, res) => {
    const { page = 0, size = 10, status, driverId, vehicleId, dateFrom, dateTo } = req.query;
    let filtered = checks.slice();
    if (status) filtered = filtered.filter(c => String(c.status) === String(status));
    if (driverId) filtered = filtered.filter(c => String(c.driverId) === String(driverId));
    if (vehicleId) filtered = filtered.filter(c => String(c.vehicleId) === String(vehicleId));
    if (dateFrom) filtered = filtered.filter(c => new Date(c.date) >= new Date(dateFrom));
    if (dateTo) filtered = filtered.filter(c => new Date(c.date) <= new Date(dateTo));
    const p = parseInt(page, 10) || 0; const s = parseInt(size, 10) || 10;
    const start = p * s; const content = filtered.slice(start, start + s);
    res.json({ content, totalElements: filtered.length, page: p, size: s });
});
app.post('/safety/checks', (req, res) => { const c = { id: Date.now(), ...req.body }; checks.push(c); res.json(c); });

app.get('/safety/issues', (req, res) => {
    const { page = 0, size = 10, status, severity, driverId, vehicleId } = req.query;
    let filtered = issues.slice();
    if (status) filtered = filtered.filter(i => String(i.status) === String(status));
    if (severity) filtered = filtered.filter(i => String(i.severity) === String(severity));
    if (driverId) filtered = filtered.filter(i => String(i.driverId) === String(driverId));
    if (vehicleId) filtered = filtered.filter(i => String(i.vehicleId) === String(vehicleId));
    const p = parseInt(page, 10) || 0; const s = parseInt(size, 10) || 10;
    const start = p * s; const content = filtered.slice(start, start + s);
    res.json({ content, totalElements: filtered.length, page: p, size: s });
});
app.post('/files/upload', upload.single('file'), (req, res) => { res.json({ url: 'https://mock.files/' + (req.file ? req.file.originalname : 'file.jpg') }); });

// simple export endpoint returning a dummy blob (PDF or XLSX) for dev
app.get('/safety/checks/export', (req, res) => {
    const { format = 'pdf' } = req.query;
    const content = `Mock export (${format}) generated at ${new Date().toISOString()}`;
    const filename = encodeURIComponent(`របាយការណ៍_សុវត្ថិភាព_${new Date().toISOString()}.${format}`);
    res.setHeader('Content-Type', 'application/octet-stream');
    // signal filename in content-disposition (UTF-8)
    res.setHeader('Content-Disposition', `attachment; filename*=UTF-8''${filename}`);
    res.send(Buffer.from(content));
});

app.listen(4000, () => console.log('Mock API listening on http://localhost:4000'));

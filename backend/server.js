// Backend REST API untuk Pastel Shop.
// Tanpa dependensi: cukup Node.js 18+ (`node server.js`).
// Data disimpan permanen di data/products.json.
// Saat pertama jalan, data awal diambil dari DummyJSON (butuh internet sekali saja).

const http = require('http');
const fs = require('fs');
const path = require('path');
const { URL } = require('url');

const PORT = process.env.PORT || 3000;
const DATA_DIR = path.join(__dirname, 'data');
const DATA_FILE = path.join(DATA_DIR, 'products.json');

let products = [];
let nextId = 1;

// ---------- Penyimpanan ----------
function save() {
  fs.mkdirSync(DATA_DIR, { recursive: true });
  const tmp = DATA_FILE + '.tmp';
  fs.writeFileSync(tmp, JSON.stringify(products, null, 2));
  fs.renameSync(tmp, DATA_FILE); // tulis atomik agar file tidak rusak
}

function computeNextId() {
  nextId = products.reduce((m, p) => Math.max(m, p.id), 0) + 1;
}

async function loadOrSeed() {
  if (fs.existsSync(DATA_FILE)) {
    products = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
    console.log(`Memuat ${products.length} produk dari ${DATA_FILE}`);
  } else {
    console.log('Belum ada data, mengambil data awal dari DummyJSON...');
    try {
      const res = await fetch('https://dummyjson.com/products?limit=0');
      const json = await res.json();
      products = json.products;
      save();
      console.log(`Seed selesai: ${products.length} produk.`);
    } catch (e) {
      console.warn('Gagal seed dari DummyJSON (' + e.message + '). Mulai dengan data kosong.');
      products = [];
      save();
    }
  }
  computeNextId();
}

// ---------- Validasi ----------
function availability(stock) {
  if (stock <= 0) return 'Out of Stock';
  if (stock <= 5) return 'Low Stock';
  return 'In Stock';
}

function str(v) {
  return typeof v === 'string' ? v.trim() : '';
}

/** Validasi & normalisasi body. Mengembalikan { errors, value }. */
function validate(body, partialFrom) {
  const errors = [];
  const b = { ...(partialFrom || {}), ...body };

  const title = str(b.title);
  if (!title) errors.push('title wajib diisi');

  const category = str(b.category);
  if (!category) errors.push('category wajib diisi');

  const price = Number(b.price);
  if (!Number.isFinite(price) || price < 0) errors.push('price harus angka >= 0');

  const discount = b.discountPercentage === undefined || b.discountPercentage === '' ? 0 : Number(b.discountPercentage);
  if (!Number.isFinite(discount) || discount < 0 || discount > 100)
    errors.push('discountPercentage harus 0-100');

  const stock = b.stock === undefined || b.stock === '' ? 0 : Number(b.stock);
  if (!Number.isInteger(stock) || stock < 0) errors.push('stock harus bilangan bulat >= 0');

  const thumbnail = str(b.thumbnail);
  if (!thumbnail) errors.push('thumbnail (URL gambar) wajib diisi');

  let images = Array.isArray(b.images) ? b.images.map(str).filter(Boolean) : [];
  if (images.length === 0 && thumbnail) images = [thumbnail];

  const value = {
    title,
    description: str(b.description),
    category,
    price,
    discountPercentage: discount,
    rating: Number.isFinite(Number(b.rating)) ? Number(b.rating) : 0,
    stock,
    brand: str(b.brand) || null,
    thumbnail,
    images,
    availabilityStatus: availability(stock),
    shippingInformation: str(b.shippingInformation) || '-',
    warrantyInformation: str(b.warrantyInformation) || '-',
    returnPolicy: str(b.returnPolicy) || '-',
    reviews: Array.isArray(b.reviews) ? b.reviews : [],
  };
  return { errors, value };
}

// ---------- HTTP helpers ----------
function send(res, status, data) {
  const body = data === undefined ? '' : JSON.stringify(data);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET,POST,PUT,PATCH,DELETE,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  });
  res.end(body);
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let raw = '';
    req.on('data', (c) => {
      raw += c;
      if (raw.length > 1e6) {
        reject(new Error('Body terlalu besar'));
        req.destroy();
      }
    });
    req.on('end', () => {
      if (!raw) return resolve({});
      try {
        const parsed = JSON.parse(raw);
        if (parsed === null || typeof parsed !== 'object' || Array.isArray(parsed))
          return reject(new Error('Body harus berupa objek JSON'));
        resolve(parsed);
      } catch {
        reject(new Error('JSON tidak valid'));
      }
    });
    req.on('error', reject);
  });
}

// ---------- Router ----------
async function handle(req, res) {
  if (req.method === 'OPTIONS') return send(res, 204);

  const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
  const parts = url.pathname.split('/').filter(Boolean); // ['products', ':id']

  if (parts.length === 0) {
    return send(res, 200, { name: 'Pastel Shop API', total: products.length });
  }
  if (parts[0] !== 'products' || parts.length > 2) {
    return send(res, 404, { message: 'Endpoint tidak ditemukan' });
  }

  // --- /products ---
  if (parts.length === 1) {
    if (req.method === 'GET') {
      const q = (url.searchParams.get('q') || '').trim().toLowerCase();
      const list = q
        ? products.filter((p) =>
            [p.title, p.description, p.category, p.brand || '']
              .join(' ')
              .toLowerCase()
              .includes(q))
        : products;
      return send(res, 200, { products: list, total: list.length });
    }
    if (req.method === 'POST') {
      const body = await readBody(req);
      const { errors, value } = validate(body);
      if (errors.length) return send(res, 400, { message: 'Data tidak valid', errors });
      const product = { id: nextId++, ...value };
      products.unshift(product); // produk baru tampil paling atas
      save();
      return send(res, 201, product);
    }
    return send(res, 405, { message: 'Method tidak diizinkan' });
  }

  // --- /products/:id ---
  const id = Number(parts[1]);
  if (!Number.isInteger(id)) return send(res, 400, { message: 'ID tidak valid' });
  const idx = products.findIndex((p) => p.id === id);
  if (idx === -1) return send(res, 404, { message: `Produk ${id} tidak ditemukan` });

  if (req.method === 'GET') return send(res, 200, products[idx]);

  if (req.method === 'PUT' || req.method === 'PATCH') {
    const body = await readBody(req);
    // PATCH/PUT sama-sama menggabungkan dengan data lama, jadi field yang tak dikirim tetap aman.
    const { errors, value } = validate(body, products[idx]);
    if (errors.length) return send(res, 400, { message: 'Data tidak valid', errors });
    products[idx] = { ...products[idx], ...value, id };
    save();
    return send(res, 200, products[idx]);
  }

  if (req.method === 'DELETE') {
    const [removed] = products.splice(idx, 1);
    save();
    return send(res, 200, removed);
  }

  return send(res, 405, { message: 'Method tidak diizinkan' });
}

const server = http.createServer((req, res) => {
  handle(req, res).catch((e) => {
    const status = /JSON|Body/.test(e.message) ? 400 : 500;
    send(res, status, { message: e.message });
  });
});

loadOrSeed().then(() => {
  server.listen(PORT, '0.0.0.0', () => {
    console.log(`Pastel Shop API berjalan di http://0.0.0.0:${PORT}`);
  });
});

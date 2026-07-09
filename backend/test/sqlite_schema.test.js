const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const Database = require('better-sqlite3');
const { selectTechniciansForBooking } = require('../controllers/bookingController');

const backendDir = path.join(__dirname, '..');
const dbPath = path.join(backendDir, 'data', 'schema-test.sqlite');

function resetDb() {
  if (fs.existsSync(dbPath)) {
    fs.unlinkSync(dbPath);
  }
}

test('sqlite initialization creates the booking-related tables', () => {
  resetDb();

  execFileSync(process.execPath, ['create_sqlite_tables.js'], {
    cwd: backendDir,
    env: { ...process.env, SQLITE_PATH: dbPath },
    stdio: 'pipe',
  });

  const db = new Database(dbPath);
  try {
    const tables = db.prepare("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name").all();
    const names = tables.map((row) => row.name);

    assert(names.includes('bookings'));
    assert(names.includes('jobs'));
    assert(names.includes('earnings'));
    assert(names.includes('resale_requests'));
    assert(names.includes('services'));
  } finally {
    db.close();
    resetDb();
  }
});

test('selectTechniciansForBooking prefers the closest skill-matching technician', () => {
  const technicians = [
    { id: 1, skills: 'Air Conditioner', latitude: 12.971598, longitude: 77.594562 },
    { id: 2, skills: 'Air Conditioner', latitude: 12.930000, longitude: 77.580000 },
    { id: 3, skills: 'Refrigerator', latitude: 12.960000, longitude: 77.620000 },
  ];

  const ranked = selectTechniciansForBooking(technicians, 'Air Conditioner', 12.971000, 77.594000, 20);

  assert.equal(ranked[0].id, 1);
  assert.equal(ranked[1].id, 2);
  assert.equal(ranked.length, 2);
});

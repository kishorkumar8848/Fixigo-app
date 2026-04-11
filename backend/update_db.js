const mysql = require('mysql2/promise');
require('dotenv').config();

const config = {
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'fixigo'
};

async function fixDb() {
    try {
        const connection = await mysql.createConnection(config);
        console.log('Adding id_proof_url column...');
        const query = 'ALTER TABLE technicians ADD COLUMN id_proof_url VARCHAR(255)';
        try {
            await connection.query(query);
            console.log('Successfully added id_proof_url to technicians!');
        } catch (e) {
            if (e.code === 'ER_DUP_FIELDNAME') {
                console.log('Column id_proof_url already exists.');
            } else {
                console.error('Error:', e.message);
            }
        }
        await connection.end();
    } catch (err) {
        console.error('Connection error:', err.message);
    }
}
fixDb();

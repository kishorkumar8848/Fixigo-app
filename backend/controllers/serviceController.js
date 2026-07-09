const pool = require('../config/db');

// ======== SERVICES MANAGEMENT ========

exports.getAllServices = async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM services ORDER BY category, name');
        res.json(result.rows);
    } catch (err) {
        console.error('Fetch services error:', err);
        res.status(500).json({ message: 'Server error fetching services' });
    }
};

exports.createService = async (req, res) => {
    try {
        const { name, category, description } = req.body;

        if (!name || !category) {
            return res.status(400).json({ message: 'Name and category are required' });
        }

        const result = await pool.query(
            'INSERT INTO services (name, category, description) VALUES ($1, $2, $3) RETURNING id',
            [name, category, description || '']
        );

        const serviceId = result.rows[0].id;

        res.status(201).json({
            message: 'Service created successfully',
            serviceId,
            name,
            category
        });
    } catch (err) {
        console.error('Create service error:', err);
        res.status(500).json({ message: 'Server error creating service' });
    }
};

exports.updateService = async (req, res) => {
    try {
        const serviceId = req.params.serviceId;
        const { name, category, description } = req.body;

        // Check if exists
        const existingResult = await pool.query('SELECT * FROM services WHERE id = $1', [serviceId]);
        if (existingResult.rows.length === 0) {
            return res.status(404).json({ message: 'Service not found' });
        }

        const existing = existingResult.rows[0];

        await pool.query(
            'UPDATE services SET name = $1, category = $2, description = $3 WHERE id = $4',
            [
                name || existing.name,
                category || existing.category,
                description !== undefined ? description : existing.description,
                serviceId
            ]
        );

        res.json({ message: 'Service updated successfully' });
    } catch (err) {
        console.error('Update service error:', err);
        res.status(500).json({ message: 'Server error updating service' });
    }
};

exports.deleteService = async (req, res) => {
    try {
        const serviceId = req.params.serviceId;

        const existingResult = await pool.query('SELECT * FROM services WHERE id = $1', [serviceId]);
        if (existingResult.rows.length === 0) {
            return res.status(404).json({ message: 'Service not found' });
        }

        await pool.query('DELETE FROM services WHERE id = $1', [serviceId]);
        res.json({ message: 'Service deleted successfully' });
    } catch (err) {
        console.error('Delete service error:', err);
        res.status(500).json({ message: 'Server error deleting service' });
    }
};

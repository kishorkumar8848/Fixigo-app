const pool = require('../config/db');

// ======== SERVICES MANAGEMENT ========

exports.getAllServices = async (req, res) => {
    try {
        const [services] = await pool.query('SELECT * FROM services ORDER BY category, name');
        res.json(services);
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

        const [result] = await pool.query(
            'INSERT INTO services (name, category, description) VALUES (?, ?, ?)',
            [name, category, description || '']
        );

        res.status(201).json({
            message: 'Service created successfully',
            serviceId: result.insertId,
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
        const [existing] = await pool.query('SELECT * FROM services WHERE id = ?', [serviceId]);
        if (existing.length === 0) {
            return res.status(404).json({ message: 'Service not found' });
        }

        await pool.query(
            'UPDATE services SET name = ?, category = ?, description = ? WHERE id = ?',
            [
                name || existing[0].name,
                category || existing[0].category,
                description !== undefined ? description : existing[0].description,
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

        const [existing] = await pool.query('SELECT * FROM services WHERE id = ?', [serviceId]);
        if (existing.length === 0) {
            return res.status(404).json({ message: 'Service not found' });
        }

        await pool.query('DELETE FROM services WHERE id = ?', [serviceId]);
        res.json({ message: 'Service deleted successfully' });
    } catch (err) {
        console.error('Delete service error:', err);
        res.status(500).json({ message: 'Server error deleting service' });
    }
};

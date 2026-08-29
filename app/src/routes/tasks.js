const express = require('express');
const db = require('../db');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

router.use(requireAuth);

// READ (list) — the dashboard
router.get('/dashboard', (req, res) => {
  const tasks = db
    .prepare('SELECT * FROM tasks WHERE user_id = ? ORDER BY created_at DESC')
    .all(req.user.id);
  res.render('dashboard', { user: req.user, tasks, error: null });
});

// CREATE
router.post('/tasks', (req, res) => {
  const { title, description } = req.body;
  if (!title || !title.trim()) {
    const tasks = db.prepare('SELECT * FROM tasks WHERE user_id = ? ORDER BY created_at DESC').all(req.user.id);
    return res.status(400).render('dashboard', { user: req.user, tasks, error: 'Title is required.' });
  }
  db.prepare('INSERT INTO tasks (user_id, title, description) VALUES (?, ?, ?)')
    .run(req.user.id, title.trim(), (description || '').trim());
  res.redirect('/dashboard');
});

// EDIT form
router.get('/tasks/:id/edit', (req, res) => {
  const task = db.prepare('SELECT * FROM tasks WHERE id = ? AND user_id = ?').get(req.params.id, req.user.id);
  if (!task) return res.status(404).send('Task not found');
  res.render('edit-task', { user: req.user, task, error: null });
});

// UPDATE
router.post('/tasks/:id', (req, res) => {
  const { title, description, status } = req.body;
  const task = db.prepare('SELECT * FROM tasks WHERE id = ? AND user_id = ?').get(req.params.id, req.user.id);
  if (!task) return res.status(404).send('Task not found');

  if (!title || !title.trim()) {
    return res.status(400).render('edit-task', { user: req.user, task, error: 'Title is required.' });
  }

  db.prepare(
    `UPDATE tasks SET title = ?, description = ?, status = ?, updated_at = datetime('now')
     WHERE id = ? AND user_id = ?`
  ).run(title.trim(), (description || '').trim(), status || 'pending', req.params.id, req.user.id);

  res.redirect('/dashboard');
});

// DELETE
router.post('/tasks/:id/delete', (req, res) => {
  db.prepare('DELETE FROM tasks WHERE id = ? AND user_id = ?').run(req.params.id, req.user.id);
  res.redirect('/dashboard');
});

module.exports = router;

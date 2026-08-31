const express = require('express');
const bcrypt = require('bcryptjs');
const db = require('../db');
const { signToken } = require('../middleware/auth');

const router = express.Router();

const COOKIE_OPTIONS = {
  httpOnly: true,
  sameSite: 'lax',
  secure: process.env.COOKIE_SECURE === 'true',
  maxAge: 7 * 24 * 60 * 60 * 1000
};

router.get('/register', (req, res) => {
  if (req.user) return res.redirect('/dashboard');
  res.render('register', { error: null });
});

router.post('/register', async (req, res) => {
  const { email, password, confirm_password } = req.body;

  if (!email || !password) {
    return res.status(400).render('register', { error: 'Email and password are required.' });
  }
  if (password.length < 8) {
    return res.status(400).render('register', { error: 'Password must be at least 8 characters.' });
  }
  if (password !== confirm_password) {
    return res.status(400).render('register', { error: 'Passwords do not match.' });
  }

  const existing = db.prepare('SELECT id FROM users WHERE email = ?').get(email.toLowerCase());
  if (existing) {
    return res.status(409).render('register', { error: 'An account with that email already exists.' });
  }

  const passwordHash = await bcrypt.hash(password, 10);
  const result = db
    .prepare('INSERT INTO users (email, password_hash) VALUES (?, ?)')
    .run(email.toLowerCase(), passwordHash);

  const user = { id: result.lastInsertRowid, email: email.toLowerCase() };
  const token = signToken(user);
  res.cookie('token', token, COOKIE_OPTIONS);
  res.redirect('/dashboard');
});

router.get('/login', (req, res) => {
  if (req.user) return res.redirect('/dashboard');
  res.render('login', { error: null });
});

router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).render('login', { error: 'Email and password are required.' });
  }

  const user = db.prepare('SELECT * FROM users WHERE email = ?').get(email.toLowerCase());
  if (!user) {
    return res.status(401).render('login', { error: 'Invalid email or password.' });
  }

  const match = await bcrypt.compare(password, user.password_hash);
  if (!match) {
    return res.status(401).render('login', { error: 'Invalid email or password.' });
  }

  const token = signToken(user);
  res.cookie('token', token, COOKIE_OPTIONS);
  res.redirect('/dashboard');
});

router.post('/logout', (req, res) => {
  res.clearCookie('token');
  res.redirect('/login');
});

module.exports = router;

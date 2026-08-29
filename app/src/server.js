require('dotenv').config();
const express = require('express');
const cookieParser = require('cookie-parser');
const path = require('path');

const { attachUser } = require('./middleware/auth');
const authRoutes = require('./routes/auth');
const taskRoutes = require('./routes/tasks');

const app = express();
const PORT = process.env.PORT || 3000;

app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, '..', 'views'));

app.use(express.urlencoded({ extended: true }));
app.use(express.json());
app.use(cookieParser());
app.use(express.static(path.join(__dirname, '..', 'public')));
app.use(attachUser);

// Health check — useful for readiness/liveness probes in Kubernetes later.
app.get('/health', (req, res) => res.status(200).json({ status: 'ok' }));

app.get('/', (req, res) => res.redirect(req.user ? '/dashboard' : '/login'));

app.use('/', authRoutes);
app.use('/', taskRoutes);

app.use((req, res) => res.status(404).send('Not found'));

app.listen(PORT, () => {
  console.log(`taskboard-app listening on port ${PORT}`);
});

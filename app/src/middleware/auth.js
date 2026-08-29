const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'dev_secret_change_me';

// Attaches req.user if a valid token cookie is present, but never blocks the request.
function attachUser(req, res, next) {
  const token = req.cookies && req.cookies.token;
  if (!token) return next();
  try {
    const payload = jwt.verify(token, JWT_SECRET);
    req.user = { id: payload.sub, email: payload.email };
  } catch (err) {
    res.clearCookie('token');
  }
  next();
}

// Blocks the request unless req.user is set.
function requireAuth(req, res, next) {
  if (!req.user) return res.redirect('/login');
  next();
}

function signToken(user) {
  return jwt.sign({ sub: user.id, email: user.email }, JWT_SECRET, { expiresIn: '7d' });
}

module.exports = { attachUser, requireAuth, signToken, JWT_SECRET };

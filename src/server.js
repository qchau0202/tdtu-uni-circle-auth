const app = require('./app');
const config = require('./config');

const PORT = config.port || 3001;

app.listen(PORT, () => {
  console.log(`Auth Service running on port ${PORT}`);
  console.log(`Environment: ${config.env}`);
});

const express = require('express');
const os = require('os');
const app = express();
const port = process.env.PORT || 3000;

// Middleware to parse JSON
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Readiness check endpoint
app.get('/ready', (req, res) => {
  res.status(200).json({
    status: 'ready',
    timestamp: new Date().toISOString()
  });
});

// Main application endpoint
app.get('/', (req, res) => {
  const podInfo = {
    hostname: os.hostname(),
    platform: os.platform(),
    nodeVersion: process.version,
    environment: process.env.NODE_ENV || 'development',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    podName: process.env.POD_NAME || 'unknown',
    podNamespace: process.env.POD_NAMESPACE || 'unknown',
    podIP: process.env.POD_IP || 'unknown'
  };

  const html = `
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Argo CD Demo App</title>
        <style>
            body {
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                margin: 0;
                padding: 20px;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                min-height: 100vh;
            }
            .container {
                max-width: 800px;
                margin: 0 auto;
                background: rgba(255, 255, 255, 0.1);
                padding: 30px;
                border-radius: 15px;
                backdrop-filter: blur(10px);
                box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
            }
            h1 {
                text-align: center;
                margin-bottom: 30px;
                font-size: 2.5em;
                text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
            }
            .info-grid {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
                gap: 20px;
                margin-top: 20px;
            }
            .info-card {
                background: rgba(255, 255, 255, 0.2);
                padding: 20px;
                border-radius: 10px;
                border: 1px solid rgba(255, 255, 255, 0.3);
            }
            .info-card h3 {
                margin-top: 0;
                color: #FFD700;
            }
            .status {
                display: inline-block;
                padding: 5px 15px;
                background: #28a745;
                border-radius: 20px;
                font-weight: bold;
                margin: 10px 0;
            }
            .refresh-btn {
                display: block;
                margin: 20px auto;
                padding: 10px 20px;
                background: #FFD700;
                color: #333;
                border: none;
                border-radius: 25px;
                cursor: pointer;
                font-size: 16px;
                font-weight: bold;
                transition: all 0.3s ease;
            }
            .refresh-btn:hover {
                background: #FFC107;
                transform: translateY(-2px);
            }
            pre {
                background: rgba(0, 0, 0, 0.3);
                padding: 15px;
                border-radius: 5px;
                overflow-x: auto;
                font-size: 14px;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🚀 Argo CD Demo Application</h1>
            <div class="status">✅ Application is running successfully!</div>
            
            <div class="info-grid">
                <div class="info-card">
                    <h3>🐳 Pod Information</h3>
                    <p><strong>Pod Name:</strong> ${podInfo.podName}</p>
                    <p><strong>Namespace:</strong> ${podInfo.podNamespace}</p>
                    <p><strong>Pod IP:</strong> ${podInfo.podIP}</p>
                    <p><strong>Hostname:</strong> ${podInfo.hostname}</p>
                </div>
                
                <div class="info-card">
                    <h3>⚙️ Runtime Info</h3>
                    <p><strong>Platform:</strong> ${podInfo.platform}</p>
                    <p><strong>Node Version:</strong> ${podInfo.nodeVersion}</p>
                    <p><strong>Environment:</strong> ${podInfo.environment}</p>
                    <p><strong>Uptime:</strong> ${Math.floor(podInfo.uptime)}s</p>
                </div>
                
                <div class="info-card">
                    <h3>📊 Memory Usage</h3>
                    <p><strong>RSS:</strong> ${Math.round(podInfo.memory.rss / 1024 / 1024)}MB</p>
                    <p><strong>Heap Used:</strong> ${Math.round(podInfo.memory.heapUsed / 1024 / 1024)}MB</p>
                    <p><strong>Heap Total:</strong> ${Math.round(podInfo.memory.heapTotal / 1024 / 1024)}MB</p>
                </div>
                
                <div class="info-card">
                    <h3>🕒 Timestamp</h3>
                    <p><strong>Current Time:</strong></p>
                    <p>${podInfo.timestamp}</p>
                </div>
            </div>
            
            <button class="refresh-btn" onclick="window.location.reload()">🔄 Refresh</button>
            
            <div class="info-card" style="margin-top: 20px;">
                <h3>🔍 Raw Pod Info (JSON)</h3>
                <pre>${JSON.stringify(podInfo, null, 2)}</pre>
            </div>
        </div>
        
        <script>
            // Auto-refresh every 30 seconds
            setTimeout(() => {
                window.location.reload();
            }, 30000);
        </script>
    </body>
    </html>
  `;

  res.send(html);
});

// API endpoint for JSON response
app.get('/api/info', (req, res) => {
  res.json({
    hostname: os.hostname(),
    platform: os.platform(),
    nodeVersion: process.version,
    environment: process.env.NODE_ENV || 'development',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    podName: process.env.POD_NAME || 'unknown',
    podNamespace: process.env.POD_NAMESPACE || 'unknown',
    podIP: process.env.POD_IP || 'unknown'
  });
});

// Start the server
app.listen(port, () => {
  console.log(`Demo app listening at http://localhost:${port}`);
  console.log(`Health check available at http://localhost:${port}/health`);
  console.log(`API info available at http://localhost:${port}/api/info`);
});

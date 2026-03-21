const express = require('express');
const path = require('path'); // NEW: Helps us build foolproof file paths
const http = require('http');
const { Server } = require("socket.io");
const fs = require('fs'); // NEW: Import the built-in File System module

const app = express();
const server = http.createServer(app);
const io = new Server(server);

// NEW: Setup the CSV file and write the column headers when the server starts
// Force the file to save exactly where server.js lives
const logFileName = path.join(__dirname, 'flight_data.csv');
fs.writeFileSync(logFileName, 'Altitude,Velocity,Acceleration,Pitch,Yaw,Roll\n');
console.log(`📁 Created new log file: ${logFileName}`);

// Serve the web page
app.get('/', (req, res) => {
    res.sendFile(__dirname + '/index.html');
});

// Handle browser connections
io.on('connection', (socket) => {
    console.log('💻 A web browser connected to the GUI!');
});

// Dummy Rocket Data Generator
setInterval(() => {
    // 1. Generate purely RAW NUMBERS for the math/logging
    const rawData = {
        altitude: Math.floor(Math.random() * 5000),
        velocity: Math.floor(Math.random() * 300),
        acceleration: (Math.random() * 50).toFixed(2),
        pitch: (Math.random() * 10 - 5).toFixed(2),
        yaw: (Math.random() * 10 - 5).toFixed(2),
        roll: (Math.random() * 360).toFixed(2)
    };
    
    // 2. Add the units ONLY for the Web GUI broadcast
    const guiTelemetry = {
        altitude: rawData.altitude + " m",
        velocity: rawData.velocity + " m/s",
        acceleration: rawData.acceleration + " m/s²",
        pitch: rawData.pitch + "°",
        yaw: rawData.yaw + "°",
        roll: rawData.roll + "°"
    };
    
    // Broadcast the pretty data to the web browser
    io.emit('telemetry_update', guiTelemetry);
    
    // 3. Save only the RAW numbers to the CSV file
    const csvRow = `${rawData.altitude},${rawData.velocity},${rawData.acceleration},${rawData.pitch},${rawData.yaw},${rawData.roll}\n`;
    fs.appendFileSync(logFileName, csvRow);
    
    console.log("Logged raw data and Broadcasted GUI data!"); 
}, 1000);

// Start the server
server.listen(3000, () => {
    console.log('🚀 STAR Ground Station running at http://localhost:3000');
});
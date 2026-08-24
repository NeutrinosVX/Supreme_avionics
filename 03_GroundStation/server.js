const express = require('express');
const http = require('http');
const { Server } = require("socket.io");
const fs = require('fs');
const path = require('path');

// 1. Import the new SerialPort library
const { SerialPort } = require('serialport');
const { ReadlineParser } = require('@serialport/parser-readline');

const app = express();
const server = http.createServer(app);
const io = new Server(server);

// Setup the CSV Logger
const logFileName = path.join(__dirname, 'flight_data.csv');
fs.writeFileSync(logFileName, 'Altitude,Velocity,Acceleration,Pitch,Yaw,Roll\n');

app.get('/', (req, res) => {
    res.sendFile(__dirname + '/index.html');
});

io.on('connection', (socket) => {
    console.log('💻 Web browser connected to the GUI!');
});

// ==========================================
// LIVE HARDWARE CONNECTION
// ==========================================

// 2. Open the USB Port (CHANGE 'COM3' TO YOUR ACTUAL ARDUINO PORT!)
// The baudRate must exactly match the Serial.begin(115200) in your C++ code.
const port = new SerialPort({ path: 'COM7', baudRate: 115200 });

// 3. Create a parser that reads the data line-by-line
const parser = port.pipe(new ReadlineParser({ delimiter: '\r\n' }));

console.log("🔌 Waiting for MPU6050 hardware data...");

// 4. Listen for incoming data
parser.on('data', (line) => {
    // The Arduino sends a string like: "0.00,0.00,9.81,45.2,-10.5,180.0"
    const dataArray = line.split(','); 

    // Safety check: ensure we got all 6 numbers
    if (dataArray.length === 6) {
        
        const rawData = {
            altitude: dataArray[0],
            velocity: dataArray[1],
            acceleration: dataArray[2],
            pitch: dataArray[3],
            yaw: dataArray[4],
            roll: dataArray[5]
        };
        
        // Add the units for the Web GUI
        const guiTelemetry = {
            altitude: rawData.altitude + " m",
            velocity: rawData.velocity + " m/s",
            acceleration: rawData.acceleration + " m/s²",
            pitch: rawData.pitch + "°",
            yaw: rawData.yaw + "°",
            roll: rawData.roll + "°"
        };
        
        // Broadcast to your 3D webpage
        io.emit('telemetry_update', guiTelemetry);
        
        // Log to CSV
        const csvRow = `${rawData.altitude},${rawData.velocity},${rawData.acceleration},${rawData.pitch},${rawData.yaw},${rawData.roll}\n`;
        fs.appendFileSync(logFileName, csvRow);
    }
});

server.listen(3000, () => {
    console.log('🚀 STAR Ground Station running at http://localhost:3000');
});
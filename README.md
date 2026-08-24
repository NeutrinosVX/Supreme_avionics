# 0.3M_avionics — 探空火箭航电项目

0.3 米级探空火箭的**航电与地面站**项目：包括火箭结构设计、姿态控制仿真、
以及基于 Arduino/MPU6050 的遥测地面站（实时 3D 显示 + 数据记录）。

> 说明：本仓库按「模拟 / 实际设计 / 控制与显示」三大模块重组，**未改动任何源代码**，
> 只做了目录整理。`server.js` 内部相对路径（`__dirname`）在 `03_GroundStation` 内依然成立。

---

## 📁 目录结构

```
0.3M_avionics/
├── README.md                  ← 本文件（项目架构说明）
├── 01_Simulation/             ← 【模拟】飞行控制算法仿真（MATLAB）
│   ├── PD_simulation.m        ← Gestalt GNC：PID + RBF 神经网络自适应姿态控制，抗高斯噪声
│   └── PD_simulation.asv      ← MATLAB 自动保存的早期纯 PID 版本
│
├── 02_Design/                 ← 【实际设计】火箭结构与电子设计
│   ├── X-1.ork                ← OpenRocket 设计文件（火箭 "Star-1"，0.45m / 66mm）
│   └── PCB design/            ← 电路板设计（当前为空，待补充）
│
└── 03_GroundStation/          ← 【控制与显示】地面站软件（Node.js + Web）
    ├── server.js              ← Express + Socket.IO + serialport 遥测服务器
    ├── index.html             ← Three.js 3D 火箭实时姿态显示 + HUD 遥测面板
    ├── package.json           ← 依赖：express / serialport / socket.io
    ├── package-lock.json
    ├── flight_data.csv        ← 飞行数据记录（高度/速度/加速度/俯仰/偏航/横滚）
    └── node_modules/
```

---

## 🏗️ 系统架构

```
┌─────────────────────┐        ┌──────────────────────────┐
│   箭上（飞行段）       │        │       地面站（控制显示段）    │
│  Arduino + MPU6050   │ 串口   │ 03_GroundStation          │
│  采集 6 路遥测        │ ─────► │ server.js (Node)          │
│  高度/速度/加速度      │ COM7   │  ├─ serialport 读串口      │
│  俯仰/偏航/横滚       │115200  │  ├─ Socket.IO 广播         │
└─────────────────────┘        │  └─ 写 flight_data.csv     │
                               │         │  WebSocket        │
                               │         ▼                  │
                               │  index.html (Three.js)     │
                               │  3D 火箭姿态 + HUD 遥测      │
                               └──────────────────────────┘
        ▲                                          ▲
        │                                          │
┌───────┴──────────┐                    ┌──────────┴─────────┐
│ 01_Simulation    │                    │ 02_Design          │
│ 控制算法仿真      │                    │ 火箭结构/PCB 设计     │
│ (MATLAB)         │                    │ (OpenRocket)       │
└──────────────────┘                    └────────────────────┘
```

### 三大模块职责

| 模块 | 职责 | 关键文件 | 状态 |
|------|------|----------|------|
| **01_Simulation** | 飞行控制算法验证：PID 基准 + 神经网络自适应补偿，在噪声扰动下稳定姿态 | `PD_simulation.m` | ✅ 可运行 |
| **02_Design** | 火箭结构设计（OpenRocket）+ 航电电路板设计 | `X-1.ork`, `PCB design/` | ⚠️ PCB 待补充 |
| **03_GroundStation** | 实时遥测接收、3D 可视化、数据记录 | `server.js`, `index.html` | ✅ 可运行 |

### 数据流（一次飞行任务）
1. **箭上**：MPU6050 采样 6 路遥测 → Arduino 通过串口以 `115200` 波特率发送
   （格式：`altitude,velocity,acceleration,pitch,yaw,roll`）
2. **地面站**：`server.js` 经 serialport 读取 → 解析校验 → ① Socket.IO 实时广播到网页 ② 追加写入 CSV
3. **显示**：`index.html` 用 Three.js 渲染 3D 火箭，按 pitch/yaw/roll 实时旋转，HUD 显示各遥测值
4. **闭环控制**（仿真侧）：`PD_simulation.m` 验证姿态控制律，为箭上主动稳定提供算法依据

---

## 🚀 运行方式

```bash
cd 03_GroundStation
npm install        # 首次安装依赖（express / serialport / socket.io）
node server.js     # 启动地面站，浏览器打开 http://localhost:3000
```

> ⚠️ 注意：`server.js` 中串口 `COM7` 为硬编码，换机器/换端口需修改。

---

## 🧰 工程标准（GitHub 行业实践）

- `.gitignore` — 排除 `node_modules/`、飞行日志 `*.csv`、MATLAB 自动保存 `*.asv`、系统/编辑器文件
- `.gitattributes` — 统一 LF 行尾，`.ork` 等二进制文件标记
- `.editorconfig` — 全项目统一缩进/编码（JS/HTML 2 空格，MATLAB 4 空格）
- `.github/workflows/ci.yml` — 推送到 main/master 自动跑：装依赖 + 语法检查 + 依赖安全审计
- `LICENSE` — MIT 协议
- `package.json` — 修正入口 `main: server.js`，新增 `npm start` / `npm run check` 脚本

## 📌 待办 / 建议（未改动，仅记录）

- [ ] **02_Design/PCB design** 目前为空——补上航电电路板设计（MPU6050 + 电源 + 串口）
- [ ] 串口端口改为**自动检测**（遍历可用端口，而非硬编码 COM7）
- [ ] `flight_data.csv` 长时间飞行用 `appendFileSync` 逐行写，可改为流式写入提升性能
- [ ] 仿真侧可增加：飞行弹道仿真（结合 OpenRocket 气动参数）与控制器联合仿真

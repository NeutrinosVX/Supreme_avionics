% Gestalt GNC: Neural-Adaptive Control with Stochastic Void (Gaussian Noise)
clear; clc; close all;

%% 1. Configuration of the Void (Simulation Setup)
tspan = [0 15]; 
dt_noise = 0.01; % 噪声的频率分辨率 (100Hz)
t_noise = tspan(1):dt_noise:tspan(2);

% --- Generate the Gaussian White Noise (The Entropy) ---
noise_mean = 0;
noise_std = 8.0; % 标准差 (噪声强度)
% 预生成噪声向量 (Pre-generated Entropy)
noise_vector = noise_mean + noise_std * randn(size(t_noise));

% 将噪声打包进结构体，传给 ODE 函数
env.t_noise = t_noise;
env.noise_vector = noise_vector;
env.N_neurons = 5;

%% 2. Initialization
% Initial state: [theta; omega; integral; weights(1:5)]
y_initial = [1; 0; 0];          
w_initial = zeros(env.N_neurons, 1); 
initial_state = [y_initial; w_initial]; 

%% 3. Run Simulation (The Struggle Against Entropy)
% 使用匿名函数将 'env' 结构体传入
options = odeset('RelTol', 1e-5, 'AbsTol', 1e-6);
[t, sol] = ode45(@(t, S) gestalt_system(t, S, env), tspan, initial_state, options);

%% 4. Visualization (The Archive)
figure('Color', 'w', 'Position', [100, 100, 1000, 800]);

% Subplot 1: State & Noise
subplot(3,1,1);
plot(t, sol(:,1), 'LineWidth', 2, 'Color', [0 0.447 0.741]); 
hold on;
% 绘制实际施加的噪声（为了可视化，需要插值回仿真时间 t）
noise_at_t = interp1(env.t_noise, env.noise_vector, t, 'linear');
plot(t, noise_at_t/10, 'Color', [0.7 0.7 0.7, 0.5]); % 噪声按比例缩小显示作为背景
yline(0, '--r', 'Target');
title('Gestalt GNC: Stabilization in Stochastic Environment');
ylabel('Angle (rad)');
legend('Theta (Error)', 'Background Noise (Scaled)');
grid on;

% Subplot 2: Neural Weights
subplot(3,1,2);
plot(t, sol(:, 4:end), 'LineWidth', 1.5); 
grid on;
title('Hidden Layer Adaptation (Weights fighting the Chaos)');
ylabel('Weight Value');

% Subplot 3: Control Effort vs Disturbance
subplot(3,1,3);
% 重建控制量 (Reconstruct Control Effort)
u_pid_hist = zeros(size(t));
u_nn_hist = zeros(size(t));
disturbance_hist = zeros(size(t));
centers = linspace(-1, 1, env.N_neurons)';

for i = 1:length(t)
    theta = sol(i,1); omega = sol(i,2); integral = sol(i,3);
    W = sol(i, 4:end)';
    phi = exp(-(theta - centers).^2 / (2 * 0.5^2));
    
    u_pid_hist(i) = -10*theta - 5*omega - 4*integral;
    u_nn_hist(i) = W' * phi;
    disturbance_hist(i) = interp1(env.t_noise, env.noise_vector, t(i), 'previous');
end

plot(t, u_pid_hist, 'b--', 'LineWidth', 1); hold on;
plot(t, u_nn_hist, 'm-', 'LineWidth', 2);
plot(t, disturbance_hist, 'k-', 'LineWidth', 0.5);
legend('PID Output (Linear)', 'Neural Output (Adaptive)', 'Gaussian Disturbance');
title('Control Allocation: PID vs Neural Net');
xlabel('Time (s)'); grid on;

%% 5. The Dynamics Function (The System)
function dSdt = gestalt_system(t, S, env)
    % 1. Unpack Environment
    N = env.N_neurons;
    t_noise_data = env.t_noise;
    noise_data = env.noise_vector;
    
    % 2. Unpack States
    theta = S(1); 
    omega = S(2); 
    integral = S(3);
    W = S(4 : 4+N-1);
    
    % 3. Hidden Layer Activation (RBF Neurons)
    centers = linspace(-1, 1, N)';
    sigma = 0.5;
    phi = exp(-(theta - centers).^2 / (2 * sigma^2));
    
    % 4. Control Law (The Brain)
    % Base PID (The Reflex)
    u_pid = -10*theta - 5*omega - 4*integral;
    
    % Neural Adaptive (The Learning)
    u_nn = W' * phi; 
    
    % Total Control
    u_total = u_pid + u_nn;
    
    % 5. "Poisoned" Physics (Stochastic Disturbance)
    % 使用 interp1 获取当前时刻的噪声
    % 'previous' 模拟零阶保持 (ZOH)，更接近数字控制系统的行为
    current_disturbance = interp1(t_noise_data, noise_data, t, 'previous');
    
    % Dynamics: Inertia * alpha = Torque
    % Torque = Control_Torque + Disturbance_Torque
    alpha = u_total + current_disturbance; 
    
    % 6. Learning Law (Update Weights - MIT Rule / Gradient Descent)
    % 增加学习率以应对快速变化的噪声
    learning_rate = 50; 
    
    % 核心：神经网络试图消除由“非线性”引起的误差
    % 在这里，它试图抵抗噪声
    dW = learning_rate * (theta + 0.1*omega) * phi; 
    
    % 7. Pack Derivatives
    dSdt = [omega; alpha; theta; dW];
end
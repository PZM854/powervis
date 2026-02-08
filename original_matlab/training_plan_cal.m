clear;
clc;
yalmip('clear');

T = 7;%单批次周期
C_max = 2;%最大重叠批次
core = 3;%核心机械训练
combine = 2;%组合任务训练
L = 2*T; %模拟窗口长度

S = [1: T]; %允许放置任务的日期编号，从1开始
day_tra_max = 2; % 每日训练次数上限。
day_type_max = 2; %每日允许处理的最大的知识批次数目
combine_after = 1; %规定第一次组合任务训练必须在第几次核心机械训练之后

x_core = intvar(core, 1, 'full'); % 核心训练安排
x_combine = intvar(combine, 1, 'full'); % 组合任务训练安排
x_day_plan = intvar(L, 1,'full'); % 每日训练次数。一般而言，不得超过2次
x_day_type = intvar(L, 1, 'full'); % 每日处理的知识批次数目。一般而言，最好不超过2批

x_del = intvar(1, 1, 'full'); %开启新批次任务间隔

C = [];

%至少训练一次
C = [C, sum(x_day_plan) >= 1];

%delta 范围
C = [C, 1 <= x_del <= T];

% 任务安排顺序约束
C = [C, x_core(1) == 1];

% 训练次数顺序约束。第三次一定在第二次后面
for i = 2:core
    C = [C, x_core(i-1)+1 <= x_core(i)]; 
end

%时间间隔约束，训练时间间隔应该越来越长才对
if core >= 3
    for i = 3:core
        C = [C, x_core(i)-x_core(i-1) >= x_core(i-1)-x_core(i-2)+1]; 
    end
end

% 训练次数顺序约束。第三次一定在第二次后面
for i = 2:combine
    C = [C, x_combine(i-1)+1 <= x_combine(i)]; 
end

%时间间隔约束，训练时间间隔应该越来越长才对
if combine >= 3
    for i = 3:combine
        C = [C, x_combine(i)-x_combine(i-1) >= x_combine(i-1)-x_combine(i-2)+1]; 
    end
end

%组合任务训练要等核心训练过几次再来
C = [C, x_combine(1) >= x_core(combine_after)]; 

%所有训练需在周期T内结束
C = [C, x_core(core) <= T];
C = [C, x_combine(combine) <= T];

max_batches = T;        % 上界（Δ>=1 时，窗口内批次数不超过 L）
M = 100;                  % Big-M（天数范围内的一个安全上界）

% 3D 二进制变量：y_core(b,i,t), y_comb(b,j,t)
y_core  = binvar(max_batches, core,   L);
y_comb  = binvar(max_batches, combine, L);

% 每日是否有某批训练：z_active(b,t)
z_active = binvar(max_batches, L);

% 绑定“y=1 <=> 某训练事件落在第 t 天”，并做每日统计
for b = 1:max_batches
    start_day = 1 + (b-1)*x_del;   % 本批次学习日（模板平移）

    % —— 核心训练：y_core(b,i,t) = 1 ⇒ start_day + x_core(i) == t
    for i = 1:core
        % y 栈中恰有一天被选中（该事件必然落在窗口内的某一天）
        C = [C, sum(y_core(b,i,:)) == 1];

        for t = 1:L
            % y=1 ⇒ 等式成立（双向夹逼）
            C = [C,  start_day + x_core(i) - t <= M*(1 - y_core(b,i,t))];
            C = [C,  t - (start_day + x_core(i)) <= M*(1 - y_core(b,i,t))];

            % 若该事件在 t 日发生，则该批当天为活跃
            C = [C, z_active(b,t) >= y_core(b,i,t)];
        end
    end

    % —— 组合训练：同理
    for j = 1:combine
        C = [C, sum(y_comb(b,j,:)) == 1];

        for t = 1:L
            C = [C,  start_day + x_combine(j) - t <= M*(1 - y_comb(b,j,t))];
            C = [C,  t - (start_day + x_combine(j)) <= M*(1 - y_comb(b,j,t))];

            C = [C, z_active(b,t) >= y_comb(b,j,t)];
        end
    end
end

% 每个(b,t)上，把 z_active(b,t) 用“≤ 总事件数”收紧（紧化有助于求解）
for b = 1:max_batches
    for t = 1:L
        C = [C, z_active(b,t) <= sum(y_core(b,:,t)) + sum(y_comb(b,:,t))];
    end
end

% —— 每日“训练次数”与“活跃批次数”上限
for t = 1:L
    train_count_t = sum(sum(y_core(:,:,t))) + sum(sum(y_comb(:,:,t)));  % 当天训练事件总数
    C = [C, train_count_t <= day_tra_max];                              % 每日训练次数上限

    C = [C, sum(z_active(:,t)) <= day_type_max];                        % 每日活跃批次数上限
end

obj = x_del;
ops = sdpsettings('solver', 'cplex', 'verbose', 0);
sol = optimize(C, obj, ops);

if sol.problem == 0
    fprintf('\n✅ 优化成功！\n');
    fprintf('最优批次间隔 Δ = %d 天\n', value(x_del));
    fprintf('核心训练日期(相对学习日): %s\n', mat2str(value(x_core)));
    fprintf('组合训练日期(相对学习日): %s\n', mat2str(value(x_combine)));
else
    fprintf('\n❌ 优化失败: %s\n', sol.info);
end



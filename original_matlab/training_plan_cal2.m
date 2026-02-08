

clear;
clc;
yalmip('clear');

T = 7;%单批次周期
core = 2;%核心机械训练
combine = 1;%组合任务训练
L = 2*T; %模拟窗口长度
delta = 3; %开启任务时间间隔。在这是一个定值

N = 1 + floor((L-1)/delta); %测试周期内有这么多批次的知识开启

S = [1:T]; %允许放置任务的日期编号，从1开始
day_task_max = 2; % 每日任务次数上限。
day_type_max = 2; %每日允许处理的最大的知识批次数目
combine_after = 1; %规定第一次组合任务训练必须在第几次核心机械训练之后

x_core = binvar(core, T); % 核心训练安排细节
x_combine = binvar(combine, T); % 组合任务训练安排细节

y_core = binvar(1, T); % 核心训练最终安排
y_combine = binvar(1, T); % 组合任务训练最终安排

x_pos_core = intvar(1, core);
x_pos_combine = intvar(1, combine);

x_day_times = intvar(1, L); % 每日训练次数。一般而言，不得超过2次
x_day_type = intvar(1, L); % 每日处理的知识批次数目。一般而言，最好不超过2批

x_start = binvar(1, L); % 当天是否学习新知识
x_plan_core = binvar(N, L); %每一批次的 核心机械 练习计划，一行对应一批次知识
x_plan_combine = binvar(N, L); %每一批次的 组合任务 练习计划，一行对应一批次知识
x_plan_sign = binvar(N, L); %任务标签。只要当天有第n批次的任意一种训练，就置1

C = [];

% 每次训练必选一天
for i = 1:core
    C = [C, sum(x_core(i, :)) == 1];
end

% 若某天发生训练，则对应到唯一一个第k次
for t = 1:T
    C= [C, sum(x_core(:, t)) == y_core(t)];
end

% 保证训练顺序。如果已经指定D0第一次训练，则不需要这个
for t = 1:T
    for i = 2:core
        C = [C, sum(x_core(i,1:t)) <= sum(x_core(i-1,1:t))];
    end
end

% 指定D0第一次机械训练
C = [C, x_core(1, 1) == 1];


%时间间隔约束，训练时间间隔应该越来越长才对
for i = 1:core
    C = [C, x_pos_core(i) == (1:T)*x_core(i,:)'];
end

if core >= 3
    for i = 3:core
        C = [C, x_pos_core(i) - x_pos_core(i-1) >= x_pos_core(i-1) - x_pos_core(i-2) + 1];
    end
end

% 每次训练必选一天
for i = 1:combine
    C = [C, sum(x_combine(i, :)) == 1];
end

% 若某天发生训练，则对应到唯一一个第k次
for t = 1:T
    C= [C, sum(x_combine(:, t)) == y_combine(t)];
end

% 保证训练顺序。如果已经指定D0第一次训练，则不需要这个
for t = 1:T
    for i = 2:combine
        C = [C, sum(x_combine(i,1:t)) <= sum(x_combine(i-1,1:t))];
    end
end

%时间间隔约束，训练时间间隔应该越来越长才对
for i = 1:combine
    C = [C, x_pos_combine(i) == (1:T)*x_combine(i,:)'];
end

if combine >= 3
    for i = 3:combine
        C = [C, x_pos_combine(i) - x_pos_combine(i-1) >= x_pos_combine(i-1) - x_pos_combine(i-2) + 1];
    end
end
%组合任务训练要等核心训练过几次再来。两个约束只能启用一个
C = [C, x_pos_combine(1) >= x_pos_core(combine_after) + 1]; % 不允许当天再训
%C = [C, x_pos_combine(1) >= x_pos_core(combine_after)]; % 允许当天接着训


% 根据训练间隔计划，确定训练日程

%第一批知识的训练计划，直接向常规训练安排看齐
for t = 1:T
    C = [C, x_plan_core(1, t) == y_core(t)];
end
for t = T+1:L
    C = [C, x_plan_core(1, t) == 0];
end

%其他批次的知识，向第一批次知识看齐
if N >= 2
    for n = 2:N
        % 学习开始前是不可能训练的
        for t = 1:(n-1)*delta
            C = [C, x_plan_core(n, t) == 0];
        end

        % 往后的计划，平移第一批次知识的安排
        for t = (n-1)*delta + 1 : L
            C = [C, x_plan_core(n, t) == x_plan_core(1, t-(n-1)*delta)];
        end
    end
end

%第一批知识的训练计划，直接向常规训练安排看齐
for t = 1:T
    C = [C, x_plan_combine(1, t) == y_combine(t)];
end
for t = T+1:L
    C = [C, x_plan_combine(1, t) == 0];
end

%其他批次的知识，向第一批次知识看齐
if N >= 2
    for n = 2:N
        % 学习开始前是不可能训练的
        for t = 1:(n-1)*delta
            C = [C, x_plan_combine(n, t) == 0];
        end

        % 往后的计划，平移第一批次知识的安排
        for t = (n-1)*delta + 1 : L
            C = [C, x_plan_combine(n, t) == x_plan_combine(1, t-(n-1)*delta)];
        end
    end
end

% 重叠批次限制
C = [C, x_plan_sign >= x_plan_core];

C = [C, x_plan_sign >= x_plan_combine]; %只要有相关任务就置1
for t = 1:L
    C = [C, x_day_type(t) == sum(x_plan_sign(:,t))];
end
C = [C, x_day_type <= day_type_max]; %重叠批次限制

% 学习日期约束。计算开启新批次知识的日期
C = [C, x_start(1) == 1];
for t = 2:L
    if mod(t-1, delta) == 0
        C = [C, x_start(t) == 1];
    else
        C = [C, x_start(t) == 0];
    end
end

%最大任务数目限制
for t = 1:L
    C = [C, x_day_times(t) == sum(x_plan_core(:,t)) + sum(x_plan_combine(:,t)) + x_start(t)];
end
C = [C, x_day_times <= day_task_max];


ave_day_task = x_day_times/L;
obj = sum((x_day_times - ave_day_task).^2);
ops = sdpsettings('solver', 'cplex', 'verbose', 0);
sol = optimize(C, obj, ops);

if sol.problem == 0
    fprintf('\n✅ 优化成功！\n');
    fprintf('核心训练日期(相对学习日): %s\n', mat2str(value(x_core)));
    fprintf('组合训练日期(相对学习日): %s\n', mat2str(value(x_combine)));
else
    fprintf('\n❌ 优化失败: %s\n', sol.info);
end



%% ========================= 0.Preparation =========================
P_inject = 1; 
%clear;                  
%define_constants;       

%rng(0);
%% ========================= 1. Data Preparation and Network Construction =========================
%CaseName = 'pglib_opf_case73_ieee_rts';
CaseName = 'E:\MATLAB\R2018b\bin\matpower6.0\case300';
BaseCase = loadcase(CaseName);   

% pglib_opf_case14_ieeeprac 
% pglib_opf_case30_as
% pglib_opf_case30_ieee
% ...
%TestCase = runpf(BaseCase);
TestCase = ext2int(runpf(BaseCase)); % runpf: MATPOWER

OperatingVoltages = (TestCase.bus(TestCase.branch(:, F_BUS), BASE_KV) + TestCase.bus(TestCase.branch(:, T_BUS), BASE_KV))/2;

IsEdgeTransformer = (TestCase.bus(TestCase.branch(:, F_BUS), BASE_KV) ~= TestCase.bus(TestCase.branch(:, T_BUS), BASE_KV));

SysEdgeTableCapWeights = table([TestCase.branch(:, F_BUS), TestCase.branch(:, T_BUS)], ... % 1. 两端节点编号，N×2数组
    [1:size(TestCase.branch, 1)]', ... 
    TestCase.branch(:, RATE_A), ... 
    abs(TestCase.branch(:, BR_X)), ... 
    OperatingVoltages, ... 
    IsEdgeTransformer, ... 
    'VariableNames',["EndNodes", "EdgeIndex", "Cap", "Weight", "OpVolt", "IsTrafo"]);

NominalGraph = graph(SysEdgeTableCapWeights);

NominalGraph.Nodes.Voltages = TestCase.bus(:, BASE_KV);

NominalDiGraph = digraph(SysEdgeTableCapWeights);
NominalDiGraph.Nodes.Voltages = TestCase.bus(:, BASE_KV);

%% ========================= 2. Network Topological Analysis =========================
tic
GeodesicMatrix = distances(NominalGraph,'Method','unweighted');
toc

HighestVoltagesNodes = find(NominalGraph.Nodes.Voltages == max(NominalGraph.Nodes.Voltages));
LowestVoltagesNodes = find(NominalGraph.Nodes.Voltages == min(NominalGraph.Nodes.Voltages));

NodeRemoteness = sum(GeodesicMatrix,1);

RemotestNode = find(NodeRemoteness == max(NodeRemoteness));
RemotestNode = RemotestNode(1);

TopPilotnode = HighestVoltagesNodes(find(NodeRemoteness(HighestVoltagesNodes) == max(NodeRemoteness(HighestVoltagesNodes))));
TopPilotnode = TopPilotnode(1);

NodalDistanceFromPilot = GeodesicMatrix(:, TopPilotnode);

BottomPilotNode = LowestVoltagesNodes(find(NodalDistanceFromPilot(LowestVoltagesNodes) == min(NodalDistanceFromPilot(LowestVoltagesNodes))));
BottomPilotNode = BottomPilotNode(1);

%% ========================= 3. PTDF Matrix Analysis and Minimum Set Cover =========================

CurPTDFMatrix = makePTDF(TestCase.baseMVA, TestCase.bus, TestCase.branch, TopPilotnode); 

binaryMatrix = (abs(CurPTDFMatrix) > 0.001);


coveredRows = false(size(binaryMatrix, 1), 1);%Rows:branch    Clm:bus
selectedCols = [];   
counter = 0;
% Greedy method
while ~all(coveredRows)
    coverage = sum(binaryMatrix(~coveredRows, :), 1);    
    [cov_max, bestCol] = max(coverage); 
    if cov_max == 0
        warning('No further branches can be covered by any bus. Terminating selection.');
        break;
    end
    selectedCols = [selectedCols; bestCol];                
    coveredRows = coveredRows | binaryMatrix(:, bestCol); 
    counter = counter + 1;
end

%% ========================= 4. Synthetic Flow Scenario Construction and Edge Direction Processing =========================

FlowTestCase = BaseCase;                
FlowTestCase.bus(:, PD) = 0;            
FlowTestCase.gen(:, PG) = 0;



FlowTestCase.bus(TopPilotnode, PD) = -P_inject * size(selectedCols,1);  
FlowTestCase.bus(selectedCols, PD) = P_inject;                         

%case_WT = ext2int(runpf(FlowTestCase)); % case of waterfall
case_WT = ext2int(rundcpf(FlowTestCase)); % case of waterfall

% num_step_max = 10;
% mpopt = mpoption('pf.nr.max_it', num_step_max); 
% [case_WT, success] = runpf(FlowTestCase, mpopt);
% while(~success)
%     num_step_max = num_step_max + 20;
%     mpopt = mpoption('pf.nr.max_it', num_step_max);
%     [case_WT, success] = runpf(FlowTestCase, mpopt);
% end
% case_WT = ext2int(case_WT);

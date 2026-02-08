function [volt_branch_ope, bool_branch_trans, table_branch_ope] = powerflow_to_table(case_WT)

    define_constants;       

    volt_branch_ope = (case_WT.bus(case_WT.branch(:,F_BUS), BASE_KV) + ...
        case_WT.bus(case_WT.branch(:,T_BUS), BASE_KV))/2;
    
    bool_branch_trans = (case_WT.bus(case_WT.branch(:, F_BUS), BASE_KV) ~= ...
        case_WT.bus(case_WT.branch(:, T_BUS), BASE_KV));
    
    table_branch_ope = table([case_WT.branch(:, F_BUS), case_WT.branch(:, T_BUS)], [1:size(case_WT.branch,1)]' , ...
        case_WT.branch(:, RATE_A), abs(case_WT.branch(:, BR_X)), volt_branch_ope, ...
        bool_branch_trans, case_WT.branch(:, PF), ...
        'VariableNames',["EndNodes", "EdgeOrigIndex", "Cap", "BR_X", "OpVolt", "IsTrafo", "SendingMW"]);

end


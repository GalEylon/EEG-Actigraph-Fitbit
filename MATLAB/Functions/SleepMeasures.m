function [Sensitivity_Sleep,PPV_Sleep,SensitivityLog,...
    Sensitivity_Wake,PPV_Wake, SpecificityLog, ConfMat] = SleepMeasures(DataTable, subTable)
%returns:
%   sensitivity (sensor = sleep when PSG = sleep)
%   specificity (sensor = wake when EEG = wake)
%   accuracy    (total portion correct)

% turn eeg and fitbit to binary
logicTable = DataTable;
logFunc = @(x) ~isnan(x) & x>1;
logicTable.EEG(logFunc(logicTable.EEG)) = 0;
logicTable.FB(logFunc(logicTable.FB)) = 0;
% convert nan at the edges to wake.
logicTable(:,2:5) = fillmissing(logicTable(:,2:5),'constant',1);
ConfMat = cell(4,1);

% sensitivity and specificity
for s = 1:3
    startTime = min(subTable.("Start Time")(1),subTable.("Start Time")(s+1));
    startInd = find(logicTable.Time == startTime);
    endTime = max(subTable.("End Time")(1),subTable.("End Time")(s+1));
    endInd = find(logicTable.Time == endTime);

    ConfMat{s+1,1} = confusionmat(logicTable.('EEG')(startInd:endInd), logicTable.(s+2)(startInd:endInd));
    PPV_Sleep(s) = ConfMat{s+1,1}(1,1)/sum(ConfMat{s+1,1}(:,1));
    Sensitivity_Sleep(s) = ConfMat{s+1,1}(1,1)/sum(ConfMat{s+1,1}(1,:));
    PPV_Wake(s) = ConfMat{s+1,1}(2,2)/sum(ConfMat{s+1,1}(:,2));
    Sensitivity_Wake(s) = ConfMat{s+1,1}(2,2)/sum(ConfMat{s+1,1}(2,:));

    % time range- start as the earliest time from both and ean as the
    % latest time from both. 
    SensitivityLog{1,s} = [zeros(startInd-1,1);logicTable.('EEG')(startInd:endInd) ==0 &...
        logicTable.(s+2)(startInd:endInd) == 0; zeros(height(DataTable)-endInd,1)];
%     PPV_Sleep(s) = sum(SensitivityLog{1,s})/sum(logicTable.(s+2)(startInd:endInd) == 0);
%     Sensitivity_Sleep(s) = sum(SensitivityLog{1,s})/sum(logicTable.("EEG")(startInd:endInd) == 0);

    SpecificityLog{1,s} = [zeros(startInd-1,1);logicTable.('EEG')(startInd:endInd) ==1 &...
        logicTable.(s+2)(startInd:endInd) == 1;zeros(height(DataTable)-endInd,1)];
%     PPV_Wake(s) = sum(SpecificityLog{1,s})/sum(logicTable.(s+2)(startInd:endInd) == 1);
%     Sensitivity_Wake(s) = sum(SpecificityLog{1,s})/sum(logicTable.("EEG")(startInd:endInd) == 1);
    
    %old!
%     SensitivityLog{1,s} = logicTable.EEG ==0 & logicTable.(s+2) == 0;
%     Sensitivity(s) = sum(SensitivityLog{1,s})/sum(logicTable.(s+2) ==0);
%     
%     SpecificityLog{1,s} = logicTable.EEG ==1 & logicTable.(s+2) == 1;
%     Specificity(s) = sum(SpecificityLog{1,s})/sum(logicTable.(s+2) ==1);
    
    if isnan(Sensitivity_Wake(s))
        Sensitivity_Wake(s) = 0;
    end
     if isnan(PPV_Wake(s))
        PPV_Wake(s) = 0;
    end
end
Sensitivity_Sleep = [nan,Sensitivity_Sleep]'; Sensitivity_Wake = [nan,Sensitivity_Wake]';
PPV_Sleep = [nan,PPV_Sleep]'; PPV_Wake = [nan,PPV_Wake]';
end



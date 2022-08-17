function [tt] = CreatSubDataTable(DataTables,EEG,FB,ACTI)
%This function creats one table with all 3 sensors and time.

for d = 1:length(DataTables)
    % get raw vectors for time and data
    [Data{1,d},Time{1,d},seqVal(d)] = genVectors(DataTables,d,EEG,FB,ACTI);
end

%% creat time vector for all data

Startdur = arrayfun(@(x) Time{1,x}(1),1:length(Time));  %first timestamp from all 3
% check for earliest report
if all(Startdur<duration(12,00,00)) | all(Startdur>duration(12,00,00))
    % all before or after midnight
    timeS = min(Startdur);
else
    % get the earliest before midnight
    timeS = min(Startdur(Startdur>duration(12,00,00)));
end

Enddur = arrayfun(@(x) Time{1,x}(end),1:length(Time));  %last timestamp from all 3
timeE = max(Enddur);

if timeS>duration(12,00,00)
    timeVec = [timeS:seconds(30):duration(23,59,30),...
        duration(0,0,0):seconds(30):timeE];
else
    timeVec = [timeS:seconds(30):timeE];
end
tt = table(timeVec',NaN(1,length(timeVec))',NaN(1,length(timeVec))',NaN(1,length(timeVec))',...
    NaN(1,length(timeVec))','VariableNames',['Time';DataTables]);

% insert data sccording to time
for d = 1:length(DataTables)
    tt.(DataTables{d})(ismember(tt.Time,Time{1,d})) = Data{1,d};
%     tt.(DataTables{d})(tt.Time == Time{1,d}) = Data{1,d};
%     tt.(DataTables{d})(discretize(Time{1,d},tt.Time)) = Data{1,d};
end
% fill missing for ACTI
tt.ACTI_CK = fillmissing(tt.ACTI_CK,'previous','MaxGap',2);
tt.ACTI_S = fillmissing(tt.ACTI_S,'previous','MaxGap',2);

end




function [Sen_Light,Sen_SWS,Sen_REM,ConfMat] = SleepMeasuresStages(DataTable, subTable)

DataTable.('EEG')(DataTable.('EEG')==3) = 4;
Stages = [4,5,2];
ConfMat = cell(4,1);

% StagesSensitivity = cell(3,3);
% [StagesSensitivity{:,1}] = deal('Light','SWS','REM');

startTime = min(subTable.("Start Time")(1),subTable.("Start Time")(2));
startInd = find(DataTable.Time == startTime);
endTime = max(subTable.("End Time")(1),subTable.("End Time")(2));
endInd = find(DataTable.Time == endTime);

ConfMat{2,1} = confusionmat( DataTable.('EEG')(startInd:endInd), DataTable.('FB')(startInd:endInd));
for i = 1:numel(Stages)
    ind = DataTable.('EEG')(startInd:endInd) ==Stages(i) &...
        DataTable.('FB')(startInd:endInd) == Stages(i);
    StagesSensitivity(i,:) = [sum(ind)/sum(DataTable.('EEG')(startInd:endInd) == Stages(i)),...
        sum(ind)/sum(DataTable.('FB')(startInd:endInd) == Stages(i))];
%     StagesSensitivity(i,2) = {sum(ind)/sum(DataTable.('EEG')(startInd:endInd) == Stages(i))};
%     StagesSensitivity(i,3) = {sum(ind)/sum(DataTable.('FB')(startInd:endInd) == Stages(i))};
end
Sen_Light = table([nan;StagesSensitivity(1,1);nan(2,1)],[nan;StagesSensitivity(1,2);nan(2,1)]);
Sen_SWS = table([nan;StagesSensitivity(2,1);nan(2,1)],[nan;StagesSensitivity(2,2);nan(2,1)]);
Sen_REM = table([nan;StagesSensitivity(3,1);nan(2,1)],[nan;StagesSensitivity(3,2);nan(2,1)]);

% Sen_Light = [nan(1,2);StagesSensitivity(1,:);nan(1,2);nan(1,2)];
% Sen_SWS = [nan(1,2);StagesSensitivity(2,:);nan(1,2);nan(1,2)];
% Sen_REM = [nan(1,2);StagesSensitivity(3,:);nan(1,2);nan(1,2)];

end



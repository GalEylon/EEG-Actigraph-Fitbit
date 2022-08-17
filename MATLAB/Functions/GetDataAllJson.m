function [EEG,FB,ACTI] = GetDataAllJson(actiIndDate, actiFiles, path, SubStr, dates,i,fbmode,ActMode)
%output 3 tables for 3 sensors (for onr day)

%% load relevent EEG file
opts = detectImportOptions([path '\EEG', num2str(i),'.csv']);
opts.SelectedVariableNames = {'epoch','time','stage'};
EEG = readtable([path '\EEG', num2str(i),'.csv'],opts);
%% load acti data new
% get index (in actiFiles) of file matching to fitbit date
actiInd = find(arrayfun(@(x) ismember(dates(i),actiIndDate{x,1}), 1:size(actiIndDate,1)));
if isempty(actiInd) %if still empty
    ACTI = table();
    EEG = [];
    FB = [];
    return
end
opts = detectImportOptions(actiFiles(actiInd*2).name);
opts = setvaropts(opts,'Date','InputFormat','MM/dd/yy');

% read to table (1 for S and 1 for CK) and then merge them. dates and
% down are the same. only sleep is different.
actiFileCK = readtable(actiFiles((actiInd*2)-1).name,opts);
actiFileS = readtable(actiFiles((actiInd*2)).name,opts);
actiFile = actiFileS(:,[1:5 8]);
actiFile = addvars(actiFile,actiFileCK.Sleep, actiFileS.Sleep,...
    'NewVariableNames',{'SleepCK','SleepS'});

% extract only relevant night from big acti file
% startInd = find(actiFile.Date == datetime(dates(i))-days(1) &...
%     actiFile.Time >= duration(21,0,0) &...
%     (actiFile.SleepCK==0 |actiFile.SleepCK==0 ),1,'first');
% if isempty(startInd)
%     startInd = find(actiFile.Date == datetime(dates(i)) &...
%         (actiFile.SleepCK==0 |actiFile.SleepCK==0 ),1,'first');
% end
% 
% endInd = find(actiFile.Date == datetime(dates(i)) & ...
%     actiFile.Time <= EEG.time(end)+hours(2) &...
%     (actiFile.SleepCK==0 |actiFile.SleepCK==0 ),1,'last');
% 
% % get only data range matching eeg time (and fb date)
if EEG.time(1) > duration(12,0,0) % strated before midnight
    startInd = find(actiFile.Date == datetime(dates(i))-days(1) & ...
        actiFile.Time == floor(EEG.time(1),'minutes'));
else %started after midnight
    startInd = find(actiFile.Date == datetime(dates(i)) & ...
        actiFile.Time == floor(EEG.time(1),'minutes'));
end
endInd = find(actiFile.Date == datetime(dates(i)) & ...
    actiFile.Time == floor(EEG.time(end),'minutes'));

ACTI = actiFile(startInd:endInd,{'Date','Time','Down','SleepCK','SleepS'});
%% actigraph algoritms

if strcmp(ActMode,'Webster')
    s = sprintf('%d',ACTI.SleepCK);
    t1=textscan(s,'%s','delimiter','1','multipleDelimsAsOne',1);
    SeqLen = cellfun('length',t1{:});
    SeqLen = SeqLen(SeqLen>3);
    for j = 1:length(SeqLen)
        ind = strfind(s,[t1{:}{j,1} '1']);
        if SeqLen(j)<10 %1 after 4 w - 1 s to w
            ACTI.SleepCK(ind+SeqLen(j):ind+SeqLen(j)) = 0;
        elseif SeqLen(j) < 15 %2 after 10 w - 3 s to w
            ACTI.SleepCK(ind(1)+SeqLen(j):ind(1)+SeqLen(j)+2) = 0;
        elseif SeqLen(j) < 20 
            %4 if surounded on both sides with 15 min w- s to w
            if all(ACTI.SleepCK(ind+SeqLen(j)+6:ind+SeqLen(j)+20) == 0)
                ACTI.SleepCK(ind+SeqLen(j):ind+SeqLen(j)+5) = 0;
            else %3 after 15 w - 4 s to w
                ACTI.SleepCK(ind+SeqLen(j):ind+SeqLen(j)+3) = 0;
            end
        elseif SeqLen(j) >19
             %5 if surounded on both sides with 20 min w- s to w
            if all(ACTI.SleepCK(ind+SeqLen(j)+10:ind+SeqLen(j)+29) == 0)
                ACTI.SleepCK(ind+SeqLen(j):ind+SeqLen(j)+9) = 0;
            else %3 after 15 w - 4 s to w
                ACTI.SleepCK(ind+SeqLen(j):ind+SeqLen(j)+3) = 0;
            end
        end
    end

    s = sprintf('%d',ACTI.SleepS);
    t1=textscan(s,'%s','delimiter','1','multipleDelimsAsOne',1);
    SeqLen = cellfun('length',t1{:});
    SeqLen = SeqLen(SeqLen>3);
    for j = 1:length(SeqLen)
        ind = strfind(s,[t1{:}{j,1} '1']);
        if SeqLen(j)<10 %1 after 4 w - 1 s to w
            ACTI.SleepS(ind+SeqLen(j):ind+SeqLen(j)) = 0;
        elseif SeqLen(j) < 15 %2 after 10 w - 3 s to w
            ACTI.SleepS(ind(1)+SeqLen(j):ind(1)+SeqLen(j)+2) = 0;
        elseif SeqLen(j) < 20 
            %4 if surounded on both sides with 15 min w- s to w
            if all(ACTI.SleepS(ind+SeqLen(j)+6:ind+SeqLen(j)+20) == 0)
                ACTI.SleepS(ind+SeqLen(j):ind+SeqLen(j)+5) = 0;
            else %3 after 15 w - 4 s to w
                ACTI.SleepS(ind+SeqLen(j):ind+SeqLen(j)+3) = 0;
            end
        elseif SeqLen(j) >19
             %5 if surounded on both sides with 20 min w- s to w
             if height(ACTI)>=ind+SeqLen(j)+29
                 if all(ACTI.SleepS(ind+SeqLen(j)+10:ind+SeqLen(j)+29) == 0)
                     ACTI.SleepS(ind+SeqLen(j):ind+SeqLen(j)+9) = 0;
                 else 
                     ACTI.SleepS(ind+SeqLen(j):ind+SeqLen(j)+3) = 0;
                 end
            else %3 after 15 w - 4 s to w
                ACTI.SleepS(ind+SeqLen(j):ind+SeqLen(j)+3) = 0;
            end
        end
    end
    ACTI(length(s)+1:end,:) = [];
end

varInd = find(contains(ACTI.Properties.VariableNames,'Sleep'));

if strcmp(ActMode,'10min')
    for var = 1:numel(varInd)
        vec = ACTI.(varInd(var));
        start = find(vec==1,1,'first');
        flag = 1;
        while flag
            s = sprintf('%d',vec(start:start+4));
            if all(s == '1')
                sleepStart = start;
                flag = 0;
            else
                start = start +1;
            end
        end

        vecflp = flipud(vec);
        startflp = find(vecflp==1,1,'first');
        flag = 1;
        while flag
            s = sprintf('%d',vecflp(startflp:startflp+4));
            if all(s == '1')
                sleepEnd = length(vecflp)-startflp+1;
                flag = 0;
            else
                startflp = startflp +1;
            end
        end

        ACTI.(varInd(var))(1:sleepStart-1) = 0;
        ACTI.(varInd(var))(sleepEnd+1:end) = 0;
    end
end

ACTI.SleepCK = ~ACTI.SleepCK;
ACTI.SleepS = ~ACTI.SleepS;  

%% load relevent fitbit file
FB = SubStr(i).SleepData;
FB.Properties.VariableNames={'Time','stages'};
FB.Time = duration(FB.Time);

%% remove awakening under 1 minute
if fbmode == 1
    for i = 1:height(FB)-1
        if FB.stages(i) == 1 & i>1  %if encountered wake
            if FB.stages(i-1) ~= 1 & FB.stages(i+1) ~= 1
                FB.stages(i) = FB.stages(i-1);
            end
        end
    end
    for i = 1:height(EEG)-1
        if EEG.stage(i) == 1 & i>1 %if encountered wake
            if EEG.stage(i-1) ~= 1 & EEG.stage(i+1) ~= 1
                EEG.stage(i) = EEG.stage(i-1);
            end
        end
    end
end

end


function [subTable,CountWakeMat] = GetTimesData2(tt,mode,DataTables,name, CountWakeMat)
%returns aleep time, wake time, and time of waking up and falling asleep.
%if mode ==1- raw data, if mode ==2, 20 minutes processing
%% mode 2 is not updated!!!!
%%

if mode ==1
    
    %for eeg and fb- no algorithm, just take the first and kast ind.
    
    %sleep start - first index that is not '1' or nan.
    vars = find(contains(tt.Properties.VariableNames,{'EEG','FB'}));
    sleepStartInd = varfun(@(x) find(x ~=1 & ~isnan(x),1,'first'),tt,...
        'InputVariables',vars,'OutputFormat','uni');
    sleepStartTime = tt.Time(sleepStartInd);
    
    %sleep end- last index ~=1
    sleepEndInd = varfun(@(x) find(x ~=1 & ~isnan(x),1,'last'),tt,...
        'InputVariables',vars,'OutputFormat','uni');
    sleepEndTime = tt.Time(sleepEndInd);
    
    % for acti- apply algoritm
    % algorithm for sleep atrt and end (start when there are at least 15
    % minutes of sleep with no more than 2 minutes awake.
    varInd = find(contains(tt.Properties.VariableNames,'ACTI'));
    
    % run through windows 17 length and check if there are no more than 2 times
    % '1'. of so, break and mark starting.
    for var = 1:numel(varInd)
        vec = tt.(varInd(var));
        sleepStart = find(vec==0,1,'first');
        sleepEnd = find(vec==0,1,'last');
        sleepStartInd = [sleepStartInd, sleepStart];
        sleepEndInd = [sleepEndInd,sleepEnd];
        sleepStartTime = [sleepStartTime;tt.Time(sleepStart)];
        sleepEndTime = [sleepEndTime;tt.Time(sleepEnd)];
    end

%     for var = 1:numel(varInd)
%         vec = tt.(varInd(var));
%         start = find(vec==0,1,'first');
%         flag = 1;
%         while flag
%             s = sprintf('%d',vec(start:start+16));
%             if count(s,'0')>=15
%                 sleepStart = start;
%                 flag = 0;
%             else
%                 start = start +1;
%             end
%         end
%         
%         vecflp = flipud(vec);
%         startflp = find(vecflp==0,1,'first');
%         flag = 1;
%         while flag
%             s = sprintf('%d',vecflp(startflp:startflp+16));
%             if count(s,'0')>=15
%                 sleepEnd = length(vecflp)-startflp+1;
%                 flag = 0;
%             else
%                 startflp = startflp +1;
%             end
%         end
%         sleepStartInd = [sleepStartInd, sleepStart];
%         sleepEndInd = [sleepEndInd,sleepEnd];
%         sleepStartTime = [sleepStartTime;tt.Time(sleepStart)];
%         sleepEndTime = [sleepEndTime;tt.Time(sleepEnd)];
%     end
    
    
else % mode = 2 - 20 minutes criteria
    
    % creat a logical vector : 1= sleep, 0= wake/nan
    s = varfun(@(x) sprintf('%d', x ~=1 & ~isnan(x)),tt,...
        'InputVariables',2:width(tt),'OutputFormat','cell');
    % searching for a sequence of '1' longer than 40.
    tx = cellfun(@(x) textscan(x,'%s','delimiter','0','multipleDelimsAsOne',1),s);
    sleepSeq = arrayfun(@(x) cellfun('length', tx{1,x}),1:length(tx),'uni',0);
    maxSeq = cellfun(@(x) find(x>=40) ,sleepSeq ,'UniformOutput' ,false);
    for i = 1:length(maxSeq)
        seqLenStart = sleepSeq{1,i}(maxSeq{1,i}(1));
        strLenStart = strcat('1{', num2str(seqLenStart),'}');
        sleepStart = regexp(s{1,i}, strLenStart);
        sleepStartInd(i) = sleepStart(1);
        sleepStartTime(i,:) = tt.Time(sleepStartInd(i));
        
        seqLenEnd = sleepSeq{1,i}(maxSeq{1,i}(end));
        strLenEnd = strcat('1{', num2str(seqLenEnd),'}');
        sleepEnd = regexp(s{1,i}, strLenEnd);
        sleepEndInd(i) = sleepEnd(end) + seqLenEnd-1;
        sleepEndTime(i,:) = tt.Time(sleepEndInd(i));
        
    end
    
end

%  sleep and wake time
for v = 1:length(DataTables)
    WakeTime(v) = sum(tt.(v+1)(sleepStartInd(v):sleepEndInd(v))==1)/2;
    SleepTime(v) = ((sleepEndInd(v)-sleepStartInd(v))/2)-...
        WakeTime(v);
    
    % creat logical vector: 0=sleep, 1=wake.
    s = sprintf('%d',tt.(v+1)(sleepStartInd(v):sleepEndInd(v)) ==1);
    tx = textscan(s,'%s','delimiter','0','multipleDelimsAsOne',1);
    sleepSeq = cellfun('length',tx{:});
    Waso(v) = sum(sleepSeq>=10);
    CountWakeMat = CountWake(sleepSeq,v,CountWakeMat);
end

% sleep stages (only fb and eeg) - last ones are nans for acti (S and CK)
[light,deep,rem] = deal(repmat(NaN,1,length(DataTables)));
for v = 1:2
    light(v) = sum(tt.(v+1)(sleepStartInd(v):sleepEndInd(v)) == 4)/2;
    deep(v) = sum(tt.(v+1)(sleepStartInd(v):sleepEndInd(v)) == 5)/2;
    rem(v) = sum(tt.(v+1)(sleepStartInd(v):sleepEndInd(v)) == 2)/2;
end

subTable = table(repmat(name,length(DataTables),1),convertCharsToStrings(DataTables),...
    sleepStartTime,sleepEndTime,SleepTime',WakeTime',...
    Waso',light',deep',rem',...
    'VariableNames',{'Name','Sensor','Start Time','End Time',...
    'Sleep Time','Wake Time','WASO','light','SWS','REM'});

end
%
% figure()
% plot(tt.Time,tt.EEG); hold on
% plot(tt.Time,tt.FB)
% ylim([0 6]); yticks(1:5); yticklabels({'Wake','REM','N1','N2','N3'})
% set(gca,'Fontsize',12, 'LineWidth',1,'box','off','Ydir','reverse');
% legend([p2 p3],{'EEG','Fitbit'})



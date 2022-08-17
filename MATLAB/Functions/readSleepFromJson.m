function [SubStr] = readSleepFromJson(subPath,name, ClockSub)
% this function detects all sleep json files in the subjects directory.
% arranges them in the correct order accorsing to inside date and then
% reads sleep data.
SubStr = struct();
sleepDir = dir([subPath '\*sleep*.json']);
for s = 1:numel(sleepDir)
    fid = fopen(fullfile(subPath,sleepDir(s).name));
    raw = fread(fid,inf);
    str = char(raw');
    fclose(fid);
    val = jsondecode(str);
    if size(val.sleep,1) >1
        val.sleep = val.sleep(find([val.sleep.isMainSleep]==1));
    end
    sleepDir(s).FileDate = datetime(val.sleep.dateOfSleep);
    sleepDir(s).Data = val.sleep.levels.data;
    if isfield(val.sleep.levels,'shortData')
        sleepDir(s).shortData = val.sleep.levels.shortData;
    else
       sleepDir(s).shortData = nan;
    end
end
[~,I] = sort([sleepDir.FileDate]);
sleepDir = sleepDir(I);

for s = 1:numel(sleepDir)
    fitdata = sleepDir(s).Data;
    stages = [];
    time = [];
    for i = 1:size(fitdata)
        sec = fitdata(i).seconds/30;
        d = datetime(fitdata(i).dateTime,'InputFormat','yyyy-MM-dd''T''HH:mm:ss.SSS','Format','HH:mm:ss');
        stages = [stages;repmat({fitdata(i).level},[sec,1])];
        time = [time;linspace(d,d+seconds(30)*(sec-1),sec)'];
    end
    
    if isstruct(sleepDir(s).shortData)
        shortfitdata = sleepDir(s).shortData;
        for j = 1:size(shortfitdata)
            sec = shortfitdata(j).seconds/30;
            d = datetime(shortfitdata(j).dateTime,...
                'InputFormat','yyyy-MM-dd''T''HH:mm:ss.SSS','Format','HH:mm:ss');
            ind = find(ismember(time,d));
            stages(ind:ind+(sec-1)) = repmat({'wake'},sec,1);
            
        end
    end
    
    if any(ismember(ClockSub{1,1},name))  %adds hour
        if sleepDir(s).FileDate>ClockSub{1,2} & sleepDir(s).FileDate<ClockSub{1,3}
            time = time+hours(1);
        end
    elseif any(ismember(ClockSub{3,1},name))
        if sleepDir(s).FileDate>ClockSub{3,2} & sleepDir(s).FileDate<ClockSub{3,3}
            time = time-hours(1);
        end
    elseif any(ismember(ClockSub{2,1},name))
        if sleepDir(s).FileDate>ClockSub{2,2} & sleepDir(s).FileDate<ClockSub{2,3}
            time = time+hours(1);
        end
    end
    
    timecell = cellstr(datestr(time,'HH:MM:SS'));
    int_stages = nan(length(stages),1);
    
    int_stages(ismember(stages, 'wake')) = 1;
    int_stages(ismember(stages, 'rem')) = 2;
    int_stages(ismember(stages, 'light')) = 4;
    int_stages(ismember(stages, 'deep')) = 5;
    t = table(timecell,int_stages);
    SubStr(s).Date = sleepDir(s).FileDate;
    SubStr(s).SleepData = t;
end
end


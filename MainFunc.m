function [TotTable, CountWakeMat] = MainFunc(MainPath, ClockSub, DataTables, fbmode, ActiAlg, plotFlag)


% subjects folders
subFiles = dir([MainPath 'SubjectsData']);
% get only files with 2 letters name
subFiles = subFiles(contains({subFiles.name},lettersPattern(2)) & ...
    cellfun(@length, {subFiles.name}) ==2);
% cell array of subjects folders (2 lettes name)
subjects = {subFiles.name};

% get all acti files from 'myActi' folder (only contains aci files
actiFiles = dir([MainPath 'ActiDown' '\*.csv']);
% make pauses inside (after dates) to make sure the format is 'dd/MM/uuuu'!!!
[actiIndDate] = MatchActiFileDate(actiFiles);


TotTable = table();
CountWakeMat = zeros(1,5);

if plotFlag
    pptDate = datestr(datetime('now'),'ddmmyy');
    pptname = strcat(pptDate,'FN', '.ppt');
    ppt=saveppt2(fullfile(MainPath,'Results',pptname),'init');
end

for sub = 1:numel(subjects)
    
    % get folder name and generate subjects path
    name = subjects{sub};
    subPath = [MainPath 'SubjectsData\' name];
    [SubStr] = readSleepFromJson(subPath,name, ClockSub);
    dates = [SubStr.Date];
    
%     % check fit bit file exists
%     fbFile = [subPath '\detailed_sleep_', name '.xlsx'];
%     if ~exist(fbFile)
%         disp([' no fitbit file for subject ' name])
%         continue
%     end
%     
%     % get dates from fitbit file
%     [~,dates,~] = xlsfinfo([subPath '\detailed_sleep_', name '.xlsx']);
%     dates = datetime(dates);
%     
    for i = 1:max(size(dates))
        
        if all(isnan(SubStr(i).SleepData.(2)))
            disp([' no fb sleep for subject ' name ' ' num2str(i)])
            continue
        end

        % get raw data from each sensor, remove or keep 0.5 min wake
        % (according to fbmode. 1=remove, 0-raw). 
        %also applies webster's algorithm to acti
        [EEG,FB,ACTI] = GetDataAllJson(actiIndDate, actiFiles, subPath, SubStr, dates,i,fbmode,ActiAlg);
        if isempty(ACTI)
            disp([' no Acti file for subject ' name ' ' num2str(i)])
            continue
        end
        %% MB has no json
%         TotalSteps = TotalStepsJson(subPath,dates,i);
%         TotalSteps = [TotalSteps;nan;nan;nan];
        %% try
        
        % all sensors
        [DataTable] = CreatSubDataTable(DataTables,EEG,FB,ACTI);
        % sum table (sleep start & end, time etc.)
        [subTable,CountWakeMat] = GetTimesData2(DataTable,1,DataTables,name, CountWakeMat);
%         [Sensitivity,SensitivityLog,...
%             Specificity, SpecificityLog] = SleepMeasures(DataTable, subTable);
        [Sensitivity_EEG,Sensitivity_S,SensitivityLog,...
            Specificity_EEG,Specificity_S, SpecificityLog, ConfMat] = SleepMeasures(DataTable, subTable);
%         ConfMatAll = cellfun(@plus, ConfMatAll, ConfMat, 'uni', 0);
        [Sen_Light,Sen_SWS,Sen_REM,ConfMatStg] = SleepMeasuresStages(DataTable, subTable);
%         CMat = CMat+ConfMatStg;
        
        subTable = addvars(subTable, ConfMat,ConfMatStg, ...
             'NewVariableNames',{'ConfMatAll','ConfMatStg'});

% 
%         subTable = addvars(subTable,Sensitivity_EEG,Sensitivity_S,...
%             Specificity_EEG,Specificity_S,Sen_Light,Sen_SWS,Sen_REM,TotalSteps,ConfMatStg,...
%             'NewVariableNames',{'Sensitivity_Sleep','PPV_Sleep', ...
%             'Sensitivity_Wake','PPV_Wake','Sen_Light',...
%             'Sen_SWS','Sen_REM','Total Steps','ConfMat'});

%         subTable = addvars(subTable,Sensitivity_EEG,Sensitivity_S,...
%             Specificity_EEG,Specificity_S,Sen_Light,Sen_SWS,Sen_REM,TotalSteps,...
%             'NewVariableNames',{'Sensitivity_EEG','Sensitivity_S', ...
%             'Specificity_EEG','Specificity_S','Sen_Light',...
%             'Sen_SWS','Sen_REM','Total Steps'});

        % plot the data- 1(all)|2(log)|3(both)
        if plotFlag
            plotData(DataTable,subTable,3,SensitivityLog, SpecificityLog)
            fobj = findobj('type','figure');
            arrayfun(@(x) saveppt2('ppt',ppt,'stretch', false,...
                'notes',[name ' ' num2str(i) ' ' datestr(dates(i))],'f',fobj(x)), 1:length(fobj));
            close all;
        end
        TotTable = [TotTable; subTable];
    end
end
% plotDataArticle(DataTable,subTable) %sub=7 (LY), i=1
end
%% Main Script for EEG-fitbit-Acti comparison.
% old code- EEG_acti_fit_compare2

% add releveant paths
clear; clc; close all;
MainPath = 'C:\Users\galey\Desktop\sleepstudy\EEG_acti_fitbit\';
cd(MainPath)

addpath('C:\Users\galey\Desktop\sleepstudy\MatlabCodes',... %for ppt
    'C:\Users\galey\Desktop\sleepstudy\MatlabCodes\EEGActiFitbit',... %codes
    [MainPath 'SubjectsData\'], [MainPath 'ActiDown']);   %subject folder. acti files

%define subjects that need to change time (changing clock)
ClockSub = {{'OE','PT','RE','TN'},datetime(2021,11,1),datetime(2021,12,6);
    {'YE'}, datetime(2020,10,27),datetime(2020,10,29);
    {'HP'},datetime(2021,4,2), datetime(2021,4,13)};


fbmode = 1; %(0- no condition, 1- remove 30 sec wake)
plotFlag = 0; %(0- no ppt)

% for later table creation
DataTables = {'EEG','FB','ACTI_CK','ACTI_S'}';
% 'Webster' '10min'
[TotTable,CountWakeMatfb] = MainFunc(MainPath,ClockSub, DataTables, fbmode, 'none', plotFlag);
[TotTable10,CountWakeMat10] = MainFunc(MainPath,ClockSub, DataTables, fbmode, '10min', plotFlag);

 
%% 2704 combining all to have all actigraphy.
TotTablenew = table()
for i = 1:height(TotTable)
    if TotTable.Sensor(i) == 'ACTI_CK' | TotTable.Sensor(i) == 'ACTI_S'
        row = TotTable10(i,:);
        row.Sensor = strcat(row.Sensor, 'r');
        TotTablenew = [TotTablenew;TotTable(i,:)];
        TotTablenew = [TotTablenew; row];
    else
        TotTablenew = [TotTablenew;TotTable(i,:)];
    end
end
%190622
Sen = unique(TotTablenew.Sensor);
NewTable = table();
for i = 1:length(Sen)
    col = TotTablenew{TotTablenew.Sensor == Sen(i),'Sleep Time'};
    NewTable = addvars(NewTable,col,'NewVariableNames',Sen(i));
end
anova1(table2array(NewTable))
writetable(TotTablenew,['TotTable',datestr(datetime('now'),'ddmmyy'), '.xlsx'])
%% 
writetable(TotTable,['TotTable', pptDate '.xlsx'])
saveppt2(fullfile(MainPath,'Results',pptname),'ppt',ppt,'close');
close all

%% summmary
[RepT] = TableForReport(TotTable);
writetable(RepT,['C:\Users\galey\Desktop\sleepstudy\articles\my article\Descriptives_',C pptDate '.csv'])
%% plotting ---------------------------------
% G = findgroups(cellstr(TotTable.Sensor));

pptDate = datestr(datetime('now'),'ddmmyy');
pptname = strcat(pptDate,'plots_cond', '.ppt');
ppt=saveppt2(fullfile(MainPath,'Results',pptname),'init');

var = {'Sleep Time', 'Wake Time'};
varS = {'Sensitivity', 'Specificity'};
pTitle = {'Total Sleep Time (min)','Wake After Sleep Onset (min)'};

%% BA for sleep and wake time
BlandAltmanPlot3(TotTable, var, 'EEG',{'FB','ACTI_CK','ACTI_S'}, pTitle, 'rmoutlrs' )
BlandAltmanPlot3(TotTable, var, 'EEG',{'FB','ACTI_CK','ACTI_S'}, pTitle)
BlandAltmanArticle(TotTable, var, 'EEG',{'FB','ACTI_CK','ACTI_S'}, pTitle, ...
    {'Fitbit','Actigraph (Cole-Kripke)','Actigraph (Sadeh)'})
SaveFigToPPT(ppt)

%% wake histogram
CountWakeMatfb(:,1) = CountWakeMatfb(:,1)./2;
WakeBar(CountWakeMatfb, {'PSG','Fitbit',{'Actigraph'; '(Cole-Kripke)'},{'Actigraph'; '(Sadeh)'}})
{'PSG';' ','Fitbit';' ','Actigraph'; '(Cole-Kripke)','Actigraph'; '(Sadeh)'}
{'PSG','Fitbit',{'Actigraph'; '(Cole-Kripke)'},{'Actigraph'; '(Sadeh)'}}
SaveFigToPPT(ppt)

CountWakeSorted = sortrows(CountWakeMat);
% remove first row (only zeros from first defining)
CountWakeSorted(1,:) = [];
pdx = 1:.5:max(CountWakeMat(:,1));
figure()
for p = 2:size(CountWakeSorted,2)
    pd = fitdist(CountWakeSorted(:,p),'exponential');
    pdy = pdf(pd,pdx);
    figure();
    plot(pdx,pdy); hold on;
    title(DataTables{p-1})
end
legend(DataTables)

get(gca,'Position')
%% sensitivity and apecificity
PlotSensitivitySpecificity(TotTable,'EEG',{'FB','ACTI_CK','ACTI_S'},var,varS)
PlotSensitivitySpecificity2(TotTable,'EEG',{'FB','ACTI_CK','ACTI_S'},var,varS)
SaveFigToPPT(ppt)

AccuracyBar(TotTable,varS)
AccuracyBarStages(TotTable,'Sen_')
%% sleep stages- bland altman
stages = {'Wake Time','light','SWS','REM'};
stagesTitle = {'Wake','Light','SWS','REM'};
BlandAltmanPlotSleepStages(TotTable,{'EEG','FB'}, stages,stagesTitle )
SaveFigToPPT(ppt)

%% bar
% wake vs sleep all 3 sensors
G = findgroups(cellstr(TotTable.Sensor));
barplot(TotTable,{'Sleep Time','Wake Time'},G)
StagesBarPlot(TotTable,stages,stagesTitle)
SaveFigToPPT(ppt)
splitapply(@(x) x, TotTable.('Wake Time'),G)
TotTable.('Wake Time')(TotTable.Sensor=='EEG')
anovaFunc(TotTable,DataTables(G(1:4)))
saveppt2('ppt',ppt,'stretch', false)

%% steps
StepsFunc(TotTable)
figure()
gscatter(TotTable{ismember(cellstr(TotTable.Sensor),'EEG'),'Sleep Time'},...
    TotTable{ismember(cellstr(TotTable.Sensor),'FB'),'Total Steps'},...
    findgroups(cellstr(TotTable{ismember(cellstr(TotTable.Sensor),'EEG'),'Name'})))
figure('Units','centimeters','Position',[7 5 23 10],'color','w');
tiledlayout('flow','TileSpacing','compact');
nexttile, plotCorDifEAF(TotTable{ismember(cellstr(TotTable.Sensor),'EEG'),'Sleep Time'},...
    TotTable{ismember(cellstr(TotTable.Sensor),'FB'),'Total Steps'}, '',...
    'EEG Total Sleep Time (min)', 'Fitbit Total Steps')
nexttile, plotCorDifEAF(TotTable{ismember(cellstr(TotTable.Sensor),'EEG'),'Wake Time'},...
    TotTable{ismember(cellstr(TotTable.Sensor),'FB'),'Total Steps'}, '',...
    'EEG Total Wake Time (min)', 'Fitbit Total Steps')
arrayfun(@(h) set(h,'YTickLabel',get(h,'YTick'),'unit','centimeters'), findobj('type','axes'))

%% Sleep & wake Time 

% 3 correlations 
var = {'Sleep Time', 'Wake Time'};
varS = {'Sensitivity', 'Specificity'};
pTitle = {'Total Sleep Time (min)','Wake After Sleep Onset (min)'};

fobj = findobj('type','figure');
arrayfun(@(x) saveppt2('ppt',ppt,'stretch', false, 'f', fobj(x)), 1:length(fobj))
close all


%% sleep stages- 4 subplots
stages = {'Wake Time','light','SWS','REM'};
stagesTitle = {'Wake','Light','SWS','REM'};
sensorLabel = {'EEG','FB'};
plotCorStages(EEGTable,FBTable,{'EEG','FB'}, stages,stagesTitle)
ax = findobj('type','axes');






saveppt2(fullfile(MainPath,'Results',pptname),'ppt',ppt,'close');


%% 
% T_split = splitapply( @(varargin) varargin, TotTable , G)
TotTable = readtable('Tottable071221.xlsx');
EEGTable = TotTable(1:4:end,:);
FBTable = TotTable(2:4:end,:);
ActiTableCK = TotTable(3:4:end,:);
ActiTableS = TotTable(4:4:end,:);
plotCorSubPlotAllvsEEG(TotTable,var, {'EEG'},{'FB','ACTI_CK','ACTI_S'},pTitle)
% BlandAltmanPlot2(pTitle,var, {'EEG','EEG'}, {'FB','ACTI'},...
%     EEGTable,FBTable,ActiTable)

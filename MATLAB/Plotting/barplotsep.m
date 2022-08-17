function barplotsep(DataTable,BarVars,GroupVar)
% this function creats bar chart with error bar fot TST or WASO 170622

colors = [0 .44 .74; .02 .61 1;
    1 .4 .16; .96 .6 .4;
    .4 .8 .07; .5 .2 .55];

% generate summarised matrix- first row sleep time. second row wake time.
TimeMat = splitapply(@mean,DataTable.(BarVars),GroupVar)';
stdMat = splitapply(@std,DataTable.(BarVars),GroupVar)'...
    ./sqrt(height(DataTable)/max(size(TimeMat)));

fig = figure()
b = bar(diag(TimeMat),'Stacked','FaceColor','flat'); hold on;
% when had 6 columns 
% for j = 1:length(TimeMat)
%     b(j).CData =  colors(j,:);
% end
errorbar([1:length(TimeMat)],TimeMat, stdMat, 'k','linestyle', 'none')
ylabel('Duration (minutes)'); %title('Time at Stage');
set(gca,'Fontsize',14,'FontName','Calibri Light','XTickLabel',{[]},...
    'LineWidth',1,'box','off')
figAx = gca;

%% add mean and std text to bars
xvals = [1:length(TimeMat)];
yvals = TimeMat +stdMat;
% labels = string([b.YData]);
labels = string(arrayfun(@(x) sprintf('%0.1f \n (%0.1f)',TimeMat(x),stdMat(x)),1:length(yvals),'uni',0));
text(figAx,xvals,yvals,labels,'HorizontalAlignment','center',...
    'VerticalAlignment','bottom','FontName','Calibri light','FontSize',11.5);

%% ANOVA
[~,text_tbl,stats] = anova1(DataTable.(BarVars),...
    strrep(convertStringsToChars(DataTable.Sensor),'_','\_'),'off');
text_tbl
figure()
[c,~,~,gnames] = multcompare(stats);

% find significant post hoc
% xvals = reshape([b.XEndPoints],2,length(b));
% sigTestInd = find(c(:,end)< .05);
% yval = 2;
% for i = 1:numel(sigTestInd)
%     var1 = find(gnames(c(sigTestInd(i),1)) ==  strrep(DataTable.Sensor(GroupVar(1:4)),'_','\_'));
%     var2 = find(gnames(c(sigTestInd(i),2)) ==  strrep(DataTable.Sensor(GroupVar(1:4)),'_','\_'));
%     plot(figAx,xvals(2,[min([var1 var2]) max([var1 var2])]), [1 1]*TimeMat(2,4)*(1+yval), '-k', 'LineWidth',1.5);
%     plot(figAx,[1 1]*xvals(2,min([var1 var2])),[TimeMat(2,4)*(1+yval) TimeMat(2,4)*(1+yval)-5],'-k', 'LineWidth',1.5)
%     plot(figAx,[1 1]*xvals(2,max([var1 var2])),[TimeMat(2,4)*(1+yval) TimeMat(2,4)*(1+yval)-5],'-k', 'LineWidth',1.5)
%     plot(figAx,mean(xvals(2,[min([var1 var2]) max([var1 var2])])), TimeMat(2,4)*(1+yval+0.2), '*k')
%     yval = yval +0.5;
% end
%% ttest manually 170622
Sensors = DataTable.Sensor(1:length(TimeMat));
for i = 1:length(Sensors)
    Sens(i) = Sensors(GroupVar(1:length(TimeMat)) == i);
end
ref = find(Sens == 'EEG');
for ii = 1:length(Sens)
    if ii ~= ref
        [~,p,~,stats] = ttest(DataTable{DataTable.Sensor == Sens(ref),BarVars}, ...
            DataTable{DataTable.Sensor == Sens(ii),BarVars});
        if p < .05
            if contains(BarVars, 'Sleep')
                pl = plot(figAx,ii,yvals(ii)+.18*yvals(ii),'*k');
            else
                pl = plot(figAx,ii,yvals(ii)+.22*yvals(ii),'*k');
            end
%             stats
        end
    end
end

%% legend
[~,I] = sort(GroupVar(1:length(TimeMat)));
forlgd = cellfun(@(x) strrep(x,'_','\_'),DataTable.Sensor(I),'Uni',0);
forlgd(contains(forlgd,'CKr')) = {sprintf('Actigraph-rescored\n(Cole-Kripke)')};
forlgd(contains(forlgd,'CK')) = {sprintf('Actigraph\n(Cole-Kripke)')};
forlgd(contains(forlgd,'Sr')) = {sprintf('Actigraph-rescored\n(Sadeh)')};
forlgd(contains(forlgd,'_S')) = {sprintf('Actigraph\n(Sadeh)')};

forlgd(contains(forlgd,'EEG')) = {'PSG'};
forlgd(contains(forlgd,'FB')) = {'Fitbit'};


if contains(BarVars, 'Sleep')
    title(figAx,'TST')
else
    title(figAx,'WASO')
    legend(figAx,forlgd,'Location','bestoutside');
end

end


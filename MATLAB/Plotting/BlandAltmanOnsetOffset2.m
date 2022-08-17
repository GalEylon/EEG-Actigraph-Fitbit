function BlandAltmanOnsetOffset2(var,sensorX,sensorY,varargin)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

SensorNames = varargin{1,1};
DataTable = varargin{1,2};
DataTable.("Start Time")(DataTable.("Start Time")<duration(12,0,0)) =...
    DataTable.("Start Time")(DataTable.("Start Time")<duration(12,0,0))+hours(24);
fig = figure('Units','normalized','OuterPosition',[0 0 1 1]);
set(fig,'Units','centimeters','color','w');
tiledlayout(3,4,"TileSpacing","tight")

for f = 1:numel(var) %TST and WASO
    Data1 = minutes(DataTable{DataTable.Sensor==sensorX,var{f}});
    c = 1 + (f-1)*2;
    for s = 1:length(sensorY)
        Data2 = minutes(DataTable{DataTable.Sensor==sensorY{s},var{f}});
        lim = [min([Data1;Data1],[]',"all"),max([Data1;Data1],[]',"all")];
        durlim = duration(0,0,0)+minutes(lim);
        lim(1) = lim(1)-minutes(durlim(1)-floor(durlim(1),"hours"));
        lim(2) = lim(2)+minutes(ceil(durlim(2),"hours")-durlim(2));
        ticks = lim(1):90:lim(2);
        labels = datestr(duration(0,0,0)+minutes(ticks),'HH:MM');

        % cor plot
        [rho,pval] = corr(Data1,Data2,'Rows','complete');
        nexttile(c)
        scatter(Data1,Data2,50,'filled'); hold on; pbaspect([1 1 1]);
%         xlabel('PSG'); ylabel('Device');
        set(gca,'FontName','Calibri light', 'Tag', ['cor' num2str(f)],...
            'Xlim',lim,'Ylim',lim,'XTick',ticks,'YTick',ticks,...
            'XTickLabel',labels,'YTickLabel',labels,'FontSize',12);


        % add correlation in text
        if pval < .05
            string= sprintf(' r = %0.2g* ',rho);
        else
            string= sprintf(' r = %0.2g \n p = %0.2g ',rho, pval);
        end
%         t = text(min(xlim),max(ylim),string,...
%             'Fontsize',12,'FontName','Calibri Light'...
%             ,'Tag',['CorText' num2str(f)]);

        % Bland Altman
        Ydif = [Data2 - Data1];
        difMean = mean(Ydif);
        difSTD = std(Ydif);

        % plot according to sginificancy (reg or as mean dif)
        nexttile(c+1);
        scatter(Data1,Ydif,40); hold on; pbaspect([1 1 1]);
%         xlabel('PSG'); ylabel('Device-PSG');
        lim = xlim;
        durlim = duration(0,0,0)+minutes(lim);
        lim(1) = lim(1)-minutes(durlim(1)-floor(durlim(1),"hours"));
        lim(2) = lim(2)+minutes(ceil(durlim(2),"hours")-durlim(2));
        ticks = lim(1):90:lim(2);
        labels = datestr(duration(0,0,0)+minutes(ticks),'HH:MM');
        set(gca,'FontName','Calibri light', 'Tag', ['BA' num2str(f)],...
            'Xlim',lim,'XTick',ticks,'XTickLabel',labels,'FontSize',12);

        lm = fitlm(Data1,Ydif);
        slope = lm.Coefficients.Estimate(2);
        intcpt = lm.Coefficients.Estimate(1);

        if 0 %lm.Coefficients.pValue(2) < .05
            % regression line and Ci
            regLine = refline(flip(lm.Coefficients.Estimate));
            regLine.Color = 'k'; regLine.LineWidth = 1; regLine.Tag=['reg' num2str(f)];
            [~,Cis] = predict(lm,sort(Data1));
            ciLine = plot(sort(Data1),Cis, ':k','LineWidth',1,'Tag',['CiLine' num2str(f)]);

            % add correlation in text
            if intcpt > 0
                string= sprintf(' Bias = %0.2f x Diary + %0.2f',slope,intcpt);
            else
                string= sprintf(' Bias = %0.2f x Diary - %0.2f',slope,abs(intcpt));
            end

%             t = text(min(xlim),max(ylim),string,...
%                 'Fontsize',12,'FontName','Calibri Light'...
%                 ,'Tag',['regtxt' num2str(f)]);
        else
            %% Bland Altman
            BAax = axis(gca);
            %             BAax(3:4) = [max(abs(BAax(3:4)))*(-1) max(abs(BAax(3:4)))];
            %             set(gca,'Ylim',BAax(3:4),'XLim',BAax(1:2).*1.1,'FontName','Calibri light');

            % mean line
            bLine = refline([0 difMean]);
            bLine.Color = 'k'; bLine.LineWidth = 1; bLine.Tag=['bias' num2str(f)];
            %             plot(BAax(1:2),difMean +[0 0],'Tag',['MeanPlot' num2str(f)]);
            % CI of the bias
            CI = [mean(Ydif) - 1.96*(std(Ydif)./sqrt(numel(Ydif))),...
                mean(Ydif) + 1.96*(std(Ydif)./sqrt(numel(Ydif)))];
            Ciplot = plot(BAax(1:2),CI(1) + [0 0], ':k','LineWidth',1,'Tag',['CiLine' num2str(f)]);
            Ciplot = plot(BAax(1:2),CI(2) + [0 0], ':k','LineWidth',1,'Tag',['CiLine' num2str(f)]);

            string= sprintf(' Bias = %2.2f [%2.1f %2.1f]',difMean,CI(1), CI(2));
%             t = text(min(xlim),max(ylim),string,...
%                 'Fontsize',12,'FontName','Calibri Light'...
%                 ,'Tag',['biastxt' num2str(f)]);


        end
        c = c+4
    end
    %% arrange Corplor 030422
    % adjust cor plot limits
    ax = findobj(gcf,'Tag',['cor' num2str(f)],'Type','axes');
    minVal = min(cellfun(@min, get(ax,{'YLim','Xlim'})),[],'all');
    maxVal = max(cellfun(@max, get(ax,{'YLim','Xlim'})),[],'all');
    [~,ind] = max(cellfun(@length, get(ax,'XTick')));
    ticks = ax(ind).XTick; tickLab = ax(ind).XTickLabel;
    set(ax,'XLim',[minVal maxVal],'YLim',[minVal maxVal],...
        'Xtick', ticks,'YTick', ticks,...
        'XTickLabel',tickLab, 'YTickLabel', tickLab);

    % add unity line
    untyLine = arrayfun(@(x) line(ax(x),[minVal maxVal],[minVal maxVal]),1:length(ax));
%     set(untyLine,'LineStyle','--','color','k');


    % add lsline
    ln = arrayfun(@(x) lsline(ax(x)),1:length(ax));
    set(ln,'LineStyle','--','color','k');
    set(ax,'XLim',[minVal maxVal],'YLim',[minVal maxVal]);

    %adjust cor text location
    delta = (maxVal-minVal)*0.1;
    set(findobj(gcf,'Tag',['CorText' num2str(f)]),'Position',...
        [minVal, maxVal-delta]);


    %% arrange BA plot
    % adjust ba plot limits
    ax = findobj(gcf,'Tag',['BA' num2str(f)],'Type','axes');
    minValX = min(cellfun(@min, get(ax,'Xlim')));
    minValY = min(cellfun(@min, get(ax,'Ylim')));
    maxValX = max(cellfun(@max, get(ax,'Xlim')));
    maxValY = max(cellfun(@max, get(ax,'Ylim')));
%     if f == 1
%         sc = findobj(gcf,'Type','Scatter');
%         [dotY,ind] = max(sc(1).YData);
%         dotX = sc(1).XData(ind);
%         dotXdur = duration(0,0,0)+minutes(dotX);
% 
%         maxValY = max(ax(2).YLim);
%     end
    set(ax,'YLim',[minValY maxValY])

    ax = findobj(gcf,'Tag',['regtxt' num2str(f)],'-or','Tag',['biastxt' num2str(f)]);
    set(ax,'Position',[minValX, maxValY],...
        'VerticalAlignment','top','HorizontalAlignment','left');

%     bLines = findobj(gcf,'Tag',['bias' num2str(f)],'-or','Tag',['CiLine' num2str(f)]);
%     if ~isempty(bLines)
%         set(bLines,'XData',[minValX maxValX]);
%     end

%     if f==1
%         axx = get(gcf,'CurrentAxes');
%         a=axes(fig,'units','centimeters','Position',[24 8 8 8],'visible','off'); hold on;
%         set(gcf,'CurrentAxes',a);
%         text(.5,1, 'o', ...
%             'Color',colors{2,1},'HorizontalAlignment','center','FontSize',12);
%         text(.52,1, ['(' datestr(dotXdur,'HH:MM') ', ' num2str(dotY) ')'], ...
%             'Color','k','HorizontalAlignment','left','FontSize',8,'FontName','Calibri light');
%         hold off;
%         set(gcf,'CurrentAxes',axx);
%     end




end


% set global labels
a=axes(fig,'units','centimeters','Position',[1 .7 30 15],'visible','off'); hold on;
set(gcf,'CurrentAxes',a);
% tTST = text(a,.26,1.05,'Sleep Onset','FontName','Calibri light','FontSize',16,...
%     'FontWeight','bold');
% tWASO = text(a,.7,1.05,'Final Awakening','FontName','Calibri light','FontSize',16,...
%     'FontWeight','bold');
tFB = text(a,.055,.835,SensorNames{1},'FontName','Calibri light','FontSize',16,...
    'Rotation',90,'FontWeight','bold');
tCK = text(a,.055,.53,{'Actigraph';'(Cole-Kripke)'},'FontName','Calibri light','FontSize',16,...
    'Rotation',90,'FontWeight','bold','HorizontalAlignment','center');
tS = text(a,.055,.19,{'Actigraph';'(Sadeh)'},'FontName','Calibri light','FontSize',16,...
    'Rotation',90,'FontWeight','bold','HorizontalAlignment','center');



end

%
% Sensors = {'Fitbit','Diary','CSHQ'};
% comb = [1 2; 1 3; 2 3];
% figure('Units','normalized','OuterPosition',[0 0 1 1])
% tiledlayout(2,3)
% for v = 1:length(vars)
%     varInd = find(contains(DataTable.Properties.VariableNames,vars{v}));
%
%     for s = 1:length(comb)
%         Data1 = DataTable{:,varInd(comb(s,1))};
%         Data2 = DataTable{:,varInd(comb(s,2))};
%         x1 = minutes(Data1); x2 = minutes(Data2);
%         limX = [min([min(x1) min(x2)]) max([max(x1) max(x2)])];
%         [rho(s+3*(v-1)),pval(s+3*(v-1))] = corr(x1,x2,'Rows','complete');
%
%         ax(s+3*(v-1)) = nexttile;
%         scatter(x1,x2,[],'filled'); hold on; pbaspect([1 1 1])
%         xlabel(Sensors{comb(s,1)}); ylabel(Sensors{comb(s,2)});
%         set(gca,'Xlim',limX,'Ylim',limX,'tag',vars{v});
% %         ticks = get(gca,'YTick');
% %         set(gca,'XTick',ticks,'XTickLabel',datestr(duration(0,0,0)+minutes(ticks),'HH:MM'),...
% %             'YTickLabel',datestr(duration(0,0,0)+minutes(ticks),'HH:MM'));
%         unLine = line(limX,limX,'Color','k','LineStyle','--');
%         regLine = lsline;
%
%     end
% end
% for a = 1:2
%     axInd = [1:3]+3*(a-1);
%     Nlims = [min(cellfun(@min,{ax(axInd).XLim})) max(cellfun(@max,{ax(axInd).XLim}))];
%     % set x and y lims
%     arrayfun(@(x) set(ax(x),'Xlim',Nlims,'Ylim',Nlims),axInd);
%     Slines = findobj(ax(axInd),'type','line','-and','-not','tag','lsline');
%     arrayfun(@(x) set(Slines(x),'XData',Nlims,'YData',Nlims,'LineWidth',.5),1:3);
%     Reglines = findobj(ax(axInd),'tag','lsline');
%     arrayfun(@(x) set(Reglines(x),'Color',[0 .45 .74]),1:3);
%     ticks = get(ax(axInd(1)),'YTick');
%     labels = datestr(duration(0,0,0)+minutes(ticks),'HH:MM');
%     arrayfun(@(x) set(ax(x),'XTick',ticks,'YTick',ticks,...
%         'XTickLabel',labels,'YTickLabel',labels),axInd);
%
%     r = rho(axInd); p = pval(axInd);
%     sig = find(p<.05);
%     rtxt = arrayfun(@(x) sprintf('r = %0.2f',r(x)),1:3,'uni',0);
%     for j = 1:length(sig)
%         rtxt(j) = {[ rtxt{j} '*']};
%     end
%     arrayfun(@(x) text(ax(axInd(x)),Nlims(1)+20, Nlims(2)-20,...
%         rtxt(x),'FontWeight','bold','FontName','Calibri light'),1:3)
% end
% set(ax,'FontName','Calibri light','FontSize',12);
% a=axes(gcf,'units','centimeters','Position',[1 .7 20 14],'visible','off'); hold on;
% set(gcf,'CurrentAxes',a)
% tTST = text(a,.04,.85,'Sleep Onset','FontName','Calibri light','FontSize',16,...
%     'FontWeight','bold','Rotation',90,'HorizontalAlignment','center');
% tWASO = text(a,.04,.28,'Final Awakening','FontName','Calibri light','FontSize',16,...
%     'FontWeight','bold','Rotation',90,'HorizontalAlignment','center');
% sgtitle(Title,'FontName','Calibri light')
%
%
%
%
% %         x1Dur = DataTable{:,varInd(comb(s,1))};
% %         x2Dur = DataTable{:,varInd(comb(s,2))};
% %         x1 = minutes(x1Dur);
% %         x2 = minutes(x2Dur);
% %         [rho,pval] = corr(x1,x2,'Rows','complete');
% %         lims = [min([min(x1) min(x2)]) max([max(x1) max(x2)])];
% %         limsDur = [min([min(x1Dur) min(x2Dur)]) max([max(x1Dur) max(x2Dur)])];
% %         ticks = limsDur(1):minutes(1):limsDur(end);
% %         ticksX = lims(1):1:lims(end);
% %         uniticks = unique(round(ticks,'hours'))+seconds(30);
% %         nexttile
% %         s = scatter(x1,x2);
% %
% %         xticks([ticksX(find(ticks == uniticks(2))):60:ticksX(end)]);
% %         xticklabels(datestr(uniticks))
% %         for t = 1:length(uniticks)
% %
% %         minute(ticks)
% %
% %         set(gca,'XLim',lims,'YLim',lims,'XTickLabel')
% %         s = scatter(DataTable{:,varInd(comb(s,1))},DataTable{:,varInd(comb(s,2))});
% %         hold on;
% %         lsline;
% %         line
% %
% %
% %     for s1 = 1:length(Sensors)
% %         for s2 = s1:length(Sensors)
% %             if s1 ~= s2
% %         [rho,pval] = corr(DataTable.(,'Rows','complete');
% %     MeanMat(v,:) = mean(DataTable{:,varInd},'omitnan');
% %     SteMat(v,:) = std(DataTable{:,varInd},'omitnan')./sqrt(sum(~isnan(DataTable{:,varInd})));
% %     [p,~,stats]=anova1(DataTable{:,varInd},[],'off');
% %     if p < .05
% %         c{v} = multcompare(stats);
% %     end
% end
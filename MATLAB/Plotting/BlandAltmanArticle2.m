function [StatsTable]=BlandAltmanArticle2(DataTable,var,sensorX, sensorY,varargin)
%Draws a Bland-Altman and correlation graph.

if ~isempty(varargin)
    SensorNames = varargin{1,1};
end

StatsTable = table();
fig = figure('Units','normalized','OuterPosition',[0 0 1 1]);
set(fig,'Units','centimeters','color','w');
tiledlayout(3,4,"TileSpacing","tight")

for f = 1:numel(var) %TST and WASO
    Data1 = DataTable{DataTable.Sensor == sensorX,var{f}};
    c = 1 + (f-1)*2;
    for i = 1:numel(sensorY)
        Data2 = DataTable{DataTable.Sensor == sensorY{i},var{f}};
        % cor
        [rho,pval] = corr(Data1,Data2,'Rows','complete');
        %data for BA
        Xmean = mean([Data1,Data2],2);
        Ydif = [Data2 - Data1];
        difMean = mean(Ydif);
        difSTD = std(Ydif);

        nexttile (c);
        scatter(Data1,Data2,50,'filled'); hold on;
        xlabel('PSG'); ylabel('Device');
        Corax = axis(gca);
        set(gca,'Xlim',[min(Corax) max(Corax)], 'Ylim',[min(Corax) max(Corax)],...
            'FontName','Calibri light', 'Tag', ['cor' num2str(f)],'FontSize',12);
        pbaspect([1 1 1]);

        % add r =1 line
        line([min(Corax) max(Corax)],[min(Corax) max(Corax)],'Tag',['Sline' num2str(f)]);

        % add correlation in text
        if pval < .05
            string= sprintf(' r = %0.2g * ',rho);
        else
            string= sprintf(' r = %0.2g \n p = %0.2g ',rho, pval);
        end

        delta = (max(Corax)-min(Corax))*0.1;
        t = text(min(Corax),max(Corax),string,...
            'Fontsize',12,'FontName','Calibri Light'...
            ,'Tag',['CorText' num2str(f)]);
%         t = text(min(Corax)+delta,max(Corax)-delta,string,...
%             'Fontsize',10,'FontName','Calibri Light'...
%             ,'Tag',['CorText' num2str(f)]);
       

        %% linear model
        lm = fitlm(Data1,Ydif);
        slope = lm.Coefficients.Estimate(2);
        intcpt = lm.Coefficients.Estimate(1);

        % plot according to sginificancy (reg or as mean dif)
        nexttile(c+1);
        scatter(Data1,Ydif,40); hold on;
        xlabel('PSG'); ylabel('Device-PSG');
        %         xlabel('$PSG$','Interpreter','latex');
        %         ylabel('$PSG-Device$','Interpreter','latex')
        set(gca,'FontName','Calibri light', 'Tag', ['reg' num2str(f)],'FontSize',12);
        pbaspect([1 1 1]);

        if 0 %lm.Coefficients.pValue(2) < .05
            % regression line and Ci
            regLine = refline(flip(lm.Coefficients.Estimate));
            regLine.Color = 'k'; regLine.LineWidth = 1;
            [~,Cis] = predict(lm,sort(Data1));
            ciLine = plot(sort(Data1),Cis, ':k','LineWidth',1,'Tag',['CiLine' num2str(f)]);

            % LOA
            %             [B,I] = sort(Data1)
            %             SDres = sqrt(sum((Ydif-lm.Fitted).^2)/59);
            %             UpLOA = lm.Fitted+ 1.96*SDres;
            %             lowLOA = lm.Fitted - 1.96*SDres;
            %             LoaLine = plot(sort(Data1), [lowLOA(I),UpLOA(I)],'r')
            %             LowCI =  [lowLOA - 1.96*(std(lowLOA)./sqrt(numel(lowLOA))),...
            %                 lowLOA + 1.96*(std(lowLOA)./sqrt(numel(lowLOA)))]
            %             LowCIplot = plot(sort(Data1), LowCI(I,:),':r')

            % add correlation in text
            if intcpt > 0
                string= sprintf(' Bias = %0.2f x PSG + %0.2f',slope,intcpt);
            else
                string= sprintf(' Bias = %0.2f x PSG - %0.2f',slope,abs(intcpt));
            end

            t = text(min(xlim),max(ylim),string,...
                'Fontsize',12,'FontName','Calibri Light'...
                ,'Tag',['regtxt' num2str(f)]);

            StatsTable = [StatsTable;table(sensorY(i),{string}, {flip(coefCI(lm))})];
            
        else
            %% Bland Altman
            BAax = axis(gca);
            BAax(3:4) = [max(abs(BAax(3:4)))*(-1) max(abs(BAax(3:4)))];
            set(gca,'Ylim',BAax(3:4),'XLim',BAax(1:2).*1.1,'FontName','Calibri light');

            % mean line
            bLine = refline([0 difMean]);
            bLine.Color = 'k'; bLine.LineWidth = 1;
            %             plot(BAax(1:2),difMean +[0 0],'Tag',['MeanPlot' num2str(f)]);
            % CI of the bias
            CI = [mean(Ydif) - 1.96*(std(Ydif)./sqrt(numel(Ydif))),...
                mean(Ydif) + 1.96*(std(Ydif)./sqrt(numel(Ydif)))];
            Ciplot = plot(BAax(1:2),CI(1) + [0 0], ':k','LineWidth',1,'Tag',['CiLine' num2str(f)]);
            Ciplot = plot(BAax(1:2),CI(2) + [0 0], ':k','LineWidth',1,'Tag',['CiLine' num2str(f)]);

            string= sprintf(' Bias = %2.2f [%2.1f %2.1f]',difMean,CI(1), CI(2));
            t = text(min(xlim),max(ylim),string,...
                'Fontsize',12,'FontName','Calibri Light'...
                ,'Tag',['biastxt' num2str(f)]);

            StatsTable = [StatsTable;table(sensorY(i),{difMean}, {CI})];
            [~,pp,~,st] = ttest(Ydif)

        end
        c = c+4;

    end
    % adjust cor plot limits
    ax = findobj(gcf,'Tag',['cor' num2str(f)],'Type','axes');
    minVal = min(cellfun(@min, get(ax,'YLim')));
    maxVal = max(cellfun(@max, get(ax,'YLim')));
    set(ax,'XLim',[minVal maxVal],'YLim',[minVal maxVal]);

    %adjust unityline limits
    minVal = min(cellfun(@min, get(findobj(gcf,'Tag',['Sline' num2str(f)]),'XData')));
    maxVal = max(cellfun(@max, get(findobj(gcf,'Tag',['Sline' num2str(f)]),'XData')));
    set(findobj(gcf,'Tag',['Sline' num2str(f)]),'XData', [minVal maxVal],...
        'YData',[minVal maxVal]);

    %creat lsline
    ln = arrayfun(@(x) lsline(ax(x)),1:3);
    set(ln,'LineStyle','--','color','k');
    set(ax,'XLim',[minVal maxVal],'YLim',[minVal maxVal]);

    %adjust cor text location
    delta = (maxVal-minVal)*0.1;
%     set(findobj(gcf,'Tag',['CorText' num2str(f)]),'Position',...
%         [minVal+delta, maxVal-delta]);
    set(findobj(gcf,'Tag',['CorText' num2str(f)]),'Position',...
        [minVal, maxVal],'VerticalAlignment','top');

    ax = findobj(gcf,'Tag',['reg' num2str(f)],'Type','axes');
    minValX = min(cellfun(@min, get(ax,'Xlim')));
    minValY = min(cellfun(@min, get(ax,'Ylim')));
    maxValX = max(cellfun(@max, get(ax,'Xlim')));
    maxValY = max(cellfun(@max, get(ax,'Ylim')));
    set(ax,'Xlim',[minValX maxValX],'YLim',[minValY maxValY]);
%     minVal = min(cellfun(@min, get(ax,'YLim')));
%     maxVal = max(cellfun(@max, get(ax,'YLim')));
%     set(ax,'YLim',[minVal maxVal]);
%     minVal = min(cellfun(@min, get(ax,'XLim')));
%     maxVal = max(cellfun(@max, get(ax,'XLim')));
%     set(ax,'XLim',[minVal maxVal]);

     %adhust bias text
    ax = findobj(gcf,'Tag',['regtxt' num2str(f)],'-or','Tag',['biastxt' num2str(f)]);
%     ax(1).Position(2)=max(ylim);ax(2).Position(2)=max(ylim);
%     delta = (maxVal-minVal)*0.1;
    set(ax,'Position',[minValX, maxValY],...
        'VerticalAlignment','top','HorizontalAlignment','left');

%     bLines = findobj(gcf,'Tag',['bias' num2str(f)],'-or','Tag',['CiLine' num2str(f)]);
%     if ~isempty(bLines)
%         set(bLines,'XData',[minValX maxValX]);
%     end

end
set(findobj(gcf,'Tag','PlusSdText','-or','Tag','MinusSdText'),...
    'FontName','Calibri light', 'FontSize',8);
set(findobj('Tag','MeanText'),'FontName','Calibri light', 'FontSize',10.5);

% set global labels
a=axes(fig,'units','centimeters','Position',[1 .7 20 14],'visible','off'); hold on;
set(gcf,'CurrentAxes',a);
tTST = text(a,.42,1.1,'TST','FontName','Calibri light','FontSize',16,...
    'FontWeight','bold');
tWASO = text(a,1.1,1.1,'WASO','FontName','Calibri light','FontSize',16,...
    'FontWeight','bold');
tFB = text(a,.1,.88,SensorNames{1},'FontName','Calibri light','FontSize',16,...
    'Rotation',90,'FontWeight','bold');
tCK = text(a,.09,.57,{'Actigraph';'(Cole-Kripke)'},'FontName','Calibri light','FontSize',16,...
    'Rotation',90,'FontWeight','bold','HorizontalAlignment','center');
tS = text(a,.09,.205,{'Actigraph';'(Sadeh)'},'FontName','Calibri light','FontSize',16,...
    'Rotation',90,'FontWeight','bold','HorizontalAlignment','center');

end


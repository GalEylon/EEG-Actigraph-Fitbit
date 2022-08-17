function plotData(DataTable,subTable,whichPlot,SensitivityLog, SpecificityLog)
%plotting each night.
%   whichPlot = 1 (fullnight) | 2 (log night) | 3 (both)
% 23/11/21 - changed only first part to creat 4 cubplot (one of them is
% table). 

logicTable = DataTable;
logFunc = @(x) ~isnan(x) & x>1;
logicTable.EEG(logFunc(logicTable.EEG)) = 0;
logicTable.FB(logFunc(logicTable.FB)) = 0;
logicTable.Properties.VariableNames = ...
    cellfun(@(x) strrep(x,'_','\_'),logicTable.Properties.VariableNames,'uni',0);

xtic = find(ismember(DataTable.Time,unique(floor(DataTable.Time,'hours'))));

SenSleep = cellfun(@(x) x(1,1)/sum(x(1,:)), subTable.ConfMatAll(2:4));
PPVSleep = cellfun(@(x) x(1,1)/sum(x(:,1)), subTable.ConfMatAll(2:4));
SenWake = cellfun(@(x) x(2,2)/sum(x(2,:)), subTable.ConfMatAll(2:4));
PPVWake = cellfun(@(x) x(2,2)/sum(x(:,2)), subTable.ConfMatAll(2:4));

%% full night 3 sensors comparison
if whichPlot == 1 | whichPlot == 3
    % generate string table to use in plot
    TString = evalc('disp(subTable(:,[2:7]))');
    TString = strrep(TString,'<strong>','\bf');
    TString = strrep(TString,'</strong>','\rm');
    TString = strrep(TString,'_','\_');
    FixedWidth = get(0,'FixedWidthFontName');
    
    fig = figure('Units','normalized','OuterPosition',[0 0 1 1]);
    subplot(4,1,1)
%     plot(DataTable.Time,DataTable{:,[2 3]},'LineWidth',1);
    plot(1:height(DataTable),DataTable{:,[2 3]},'LineWidth',1);
    set(gca, 'YLim',[0 6],'YTick',[1:5],'YTickLabel',{'Wake','REM','N1','N2','N3'},...
        'Ydir','reverse');
    legend({'EEG','FB'},'Location','bestoutside');
    
    subplot(4,1,2)
    p = plot(1:height(DataTable),logicTable{:,[4 5]},'LineWidth',1);
    set(gca,'YLim',[-1 2],'YTick',[0 1],'YTickLabel',{'Sleep','Wake'});
    hold on;
    st = arrayfun(@(x) find(DataTable.Time == subTable.('Start Time')(x)),3:4);
    ed = arrayfun(@(x) find(DataTable.Time == subTable.('End Time')(x)),3:4);
    for i = 1:numel(st)
        xl = xline(st(i),'--'); xle = xline(ed(i),'--');
        set([xl xle],'FontSize',7,'color',p(i).Color);
    end
    legend(p,{'ACTI\_CK', 'ACTI\_S'},'Location','bestoutside');
    
    subplot(4,1,3)
    plot(1:height(DataTable),logicTable{:,[2 3 4 5]},'LineWidth',1);
    set(gca,'YLim',[-1 2],'YTick',[0 1],'YTickLabel',{'Sleep','Wake'});
    legend({'EEG','FB','ACTI\_CK', 'ACTI\_S'},'Location','bestoutside');
    
    ax = findobj('type','axes');
    set(ax,'XTick',xtic,...
        'XTickLabel',datestr(DataTable.Time(xtic),'HH:MM:ss'),...
        'Fontsize',12, 'LineWidth',1,'box','off','FontName','Calibri light')
    s = subplot(4,1,4);
    % Output the table using the annotation command.
    an = annotation(gcf,'Textbox','String',TString,'Interpreter','Tex',...
        'FontName',FixedWidth,'FontSize',12,...
        'Units','Normalized',...
        'LineStyle','none','Position',s.Position);
    an.Position(1) = 0.2;
    s.Visible = 'off';
end

if whichPlot == 2 | whichPlot == 3
    fig2 = figure('Units','normalized','OuterPosition',[0 0 1 1]);
    for p = 1:3
        sp = subplot(3,1,p);
        plot(1:height(DataTable),logicTable{:,[2 2+p]},'LineWidth',1); hold on; %eeg&fb
        plot(find(SensitivityLog{1,p}),...    %sensitivity
            repmat(-0.7,[1 sum(SensitivityLog{1,p})]),'o',...
            'Color',[.93 .69 .13],'MarkerSize',1.5);
        plot(find(SpecificityLog{1,p}),...    %specificity
            repmat(-0.5,[1 sum(SpecificityLog{1,p})]),'o',...
            'Color',[.12 .87 .2],'MarkerSize',1.5);
        
        % if no specificity (for acti mostly)
        % just so we can have legend entry. no data ploted.
        
        if isempty(find(SpecificityLog{1,p}))
            plot(1,1,'LineStyle','none','Color',[.12 .87 .2],'MarkerSize',1);
        end
        
        % creat copy of lines only from releavent subplot (sp)
        %         hcopy = copyobj(findobj('type','line'),findobj('type','axes'));
        hcopy = copyobj(findobj(sp,'type','line'),sp);
        
        % erase data and adjuct linestyle for legend
        arrayfun(@(h)set(h,'XData',nan(size(h.XData)),'YData',nan(size(h.YData)),...
            'LineStyle','-','Marker','none','LineWidth',1),hcopy)
%         set(hcopy(end:-1:1),{'DisplayName'},[logicTable.Properties.VariableNames([2 2+p])...
%             {['Sensitivity (' num2str(subTable.Sensitivity_S(p+1),'%.2f') ')'] }...
%             {['Specificity (' num2str(subTable.Specificity_S(p+1),'%.2f') ')'] }]');
        set(hcopy(end:-1:1),{'DisplayName'},[logicTable.Properties.VariableNames([2 2+p])...
            {['Sensitivity - Sleep (' num2str(SenSleep(p),'%.2f') ')'...
            char(10) 'PPV - Sleep (' num2str(PPVSleep(p),'%.2f') ')']}...
            {['Sensitivity - Wake (' num2str(SenWake(p),'%.2f') ')'...
            char(10) 'PPV - Wake (' num2str(PPVWake(p),'%.2f') ')'] }]');
        legend(hcopy(end:-1:1), 'Location','bestoutside');
        
    end
    ax = findobj(2,'type','axes');
    set(ax,'XTick',xtic,...
        'XTickLabel',datestr(DataTable.Time(xtic),'HH:MM:ss'),...
        'YLim',[-1 2],'YTick',[0 1],'YTickLabel',{'Sleep','Wake'},...
        'Fontsize',12, 'LineWidth',1,'box','off','FontName','Calibri light')
end

end


function AccuracyBarArticleAnova(DataTable,varS,varplot, Sensors, pval)

ACC.SensitivitySleep = @(x) x(1,1)/sum(x(1,:));
ACC.SensitivityWake = @(x) x(2,2)/sum(x(2,:));
ACC.PPVSleep = @(x) x(1,1)/sum(x(:,1));
ACC.PPVWake = @(x) x(2,2)/sum(x(:,2));

for i = 1:length(Sensors)
    AC.Sensitivity_Sleep(:,i) = cellfun(ACC.SensitivitySleep, DataTable.ConfMatAll(DataTable.Sensor == Sensors{i}));
    AC.PPV_Sleep(:,i) = cellfun(ACC.PPVSleep, DataTable.ConfMatAll(DataTable.Sensor == Sensors{i}));
    AC.Sensitivity_Wake(:,i) = cellfun(ACC.SensitivityWake, DataTable.ConfMatAll(DataTable.Sensor == Sensors{i}));
    AC.PPV_Wake(:,i) = cellfun(ACC.PPVWake, DataTable.ConfMatAll(DataTable.Sensor == Sensors{i}));
end
%%
names = DataTable.Name(DataTable.Sensor=='FB',:);
[G,ID] = findgroups(cellstr(names));
% g = findgroups(cellstr(DataTable.Name(DataTable.Sensor == Sensors{i})))
% a = splitapply(@mean,AC.Sensitivity_Sleep,G);
AC.PPV_Wake = fillmissing(AC.PPV_Wake,'constant',0);

AC.Sensitivity_Sleep = splitapply(@mean,AC.Sensitivity_Sleep,G);
AC.PPV_Sleep = splitapply(@mean,AC.PPV_Sleep,G);
AC.Sensitivity_Wake = splitapply(@mean,AC.Sensitivity_Wake,G);
AC.PPV_Wake = splitapply(@mean,AC.PPV_Wake,G);


%%
Mainfig = figure('Units','normalized','Position',[.1 .2 .6 .6]);
t = tiledlayout(Mainfig, 1,2,'TileSpacing','tight');

ACfields = fieldnames(AC);
for st = 1:numel(varplot)
    curfields = ACfields(contains(ACfields,varplot{st}));
    % get sen and ppv for current state (sleep/wake)
    SEN = AC.(curfields{contains(curfields,'Sensitivity')});
    PPV = AC.(curfields{contains(curfields,'PPV')});
    PPV = fillmissing(PPV,'constant',0);

    % calculate mean and std
    MeanMat = [mean(SEN,'omitnan')',mean(PPV,'omitnan')'];
    SteMat = [std(SEN,'omitnan')'./sqrt(length(SEN)),...
        std(PPV,'omitnan')'./sqrt(sum(~any(isnan(PPV),2)))];
    StdMat = [std(SEN,'omitnan')',std(PPV,'omitnan')'];

    %plot bar, sd and write values on top
    ax.(varplot{st}) = nexttile(t);
    b = bar( MeanMat',.92); hold on; box off;
    errorbar(reshape([b.XEndPoints],2,3),MeanMat', SteMat',...
        'k','linestyle', 'none');
    xlabel(varplot{st});xticklabels(varS(st,:)); ylim([0 1.2])
    StdMat2 = reshape(StdMat',1,6);
    xvals = [b.XEndPoints];
%     yvals = [b.YEndPoints] +StdMat2;
    yvals = [b.YEndPoints] +reshape(SteMat',1,6);
    yvalstxt = [b.YEndPoints];
    labels1 = string(arrayfun(@(x) sprintf("%0.2f ",yvalstxt(x)),1:6,'uni',0));
    labels2 = string(arrayfun(@(x) sprintf("(%.3f)",StdMat2(x)),1:6,'uni',0));
    txt = text(ax.(varplot{st}),xvals,yvals+.03,strrep(labels1,'0.','.'),'HorizontalAlignment','center',...
        'VerticalAlignment','bottom','FontName','Calibri light','FontSize',12);
    txt2 = text(ax.(varplot{st}),xvals,yvals,strrep(labels2,'0.','.'),'HorizontalAlignment','center',...
        'VerticalAlignment','bottom','FontName','Calibri light','FontSize',9);

    xvals = reshape([b.XEndPoints],2,3);
    yvals = reshape([b.YEndPoints],2,3)+reshape(SteMat',2,3);

    % perform anova- Sensitivity
    [~,text_tbl,stats] = anova1(SEN,Sensors,'off');
    disp([varplot{st} ' Sensitivity'])
    text_tbl
    %post hoc
    [c,~,~,~] = multcompare(stats,'Display','off')

    % find significant tests

    sigTestInd = find(c(:,end)< .05);
    for i = 1:numel(sigTestInd)
        var1 = c(sigTestInd(i),1); var2 = c(sigTestInd(i),2);
        if abs(var2-var1)<=1
            yval = .12;
        else
            yval = .18;
        end
        plot(ax.(varplot{st}),xvals(1,[var1 var2]), [1 1]*max(yvals(1,:))+yval, '-k', 'LineWidth',1.5);
        plot(ax.(varplot{st}),[1 1]*xvals(1,var1), [max(yvals(1,:))+yval max(yvals(1,:))+yval-.03], '-k', 'LineWidth',1.2);
        plot(ax.(varplot{st}),[1 1]*xvals(1,var2), [max(yvals(1,:))+yval max(yvals(1,:))+yval-.03], '-k', 'LineWidth',1.2);
        plot(ax.(varplot{st}),mean(xvals(1,[var1 var2])), max(yvals(1,:))+yval+.02, '*k');
    end

    % perform anova
    [~,text_tbl,stats] = anova1(PPV,Sensors,'off');
    disp([varplot{st} ' PPV'])
    text_tbl
    %post hoc
    [c,~,~,~] = multcompare(stats,'Display','off')


    %     % find significant tests
    %     xvals = reshape([b.XEndPoints],2,3);
    %     yvals = reshape([b.YEndPoints],2,3)+reshape(StdMat',2,3);

    sigTestInd = find(c(:,end)< .05);
    for i = 1:numel(sigTestInd)
        var1 = c(sigTestInd(i),1); var2 = c(sigTestInd(i),2);
        if abs(var2-var1)<=1
            yval = .12;
        else
            yval = .18;
        end
        plot(ax.(varplot{st}),xvals(2,[var1 var2]), [1 1]*max(yvals(2,:))+yval, '-k', 'LineWidth',1.5);
        plot(ax.(varplot{st}),[1 1]*xvals(2,var1), [max(yvals(2,:))+yval max(yvals(2,:))+yval-.03], '-k', 'LineWidth',1.2);
        plot(ax.(varplot{st}),[1 1]*xvals(2,var2), [max(yvals(2,:))+yval max(yvals(2,:))+yval-.03], '-k', 'LineWidth',1.2);
        plot(ax.(varplot{st}),mean(xvals(2,[var1 var2])), max(yvals(2,:))+yval+.02, '*k')
    end

end

legend(ax.(varplot{st}), {'Fitbit','Actigraph (Cole-Kripke)','Actigraph (Sadeh)'});
set(ax.Wake, 'YAxisLocation','right','YLim',ax.Sleep.YLim);
ax.Wake.YAxis.Visible = 'off';
set(findobj(Mainfig,'type','axes'),'Fontsize',14,'FontName','Calibri Light'...
    ,'LineWidth',1,'box','off','YTick',[0:0.2:1]);

end


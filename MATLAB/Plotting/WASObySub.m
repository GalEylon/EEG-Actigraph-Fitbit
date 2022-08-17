function WASObySub(DataTable)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
ACC.SensitivityWake = @(x) x(2,2)/sum(x(2,:));
ACC.PPVWake = @(x) x(2,2)/sum(x(:,2));
Sensors = {'FB','ACTI_CK','ACTI_S'};
Sensors2 = {'Fitbit','Actigraph \n(Cole-Kripke)','Actigraph \n(Sadeh)'};
names = DataTable.Name(DataTable.Sensor=='FB',:);
names2 = DataTable.Name(DataTable.Sensor=='ACTI_CK',:);
if ~all(all(names == names2))
    disp('missmatch num rows')
    return
end

for i = 1:length(Sensors)
    Sen_W(:,i) = cellfun(ACC.SensitivityWake, DataTable.ConfMatAll(DataTable.Sensor == Sensors{i}));
    PPV_W(:,i) = cellfun(ACC.PPVWake, DataTable.ConfMatAll(DataTable.Sensor == Sensors{i}));
end
PPV_W = fillmissing(PPV_W,'constant',0);

[G,ID] = findgroups(cellstr(names));
[cnt_unique, unique_a] = hist(G,unique(G));

Means = [arrayfun(@(x) splitapply(@mean, Sen_W(:,x), G), 1:3,'UniformOutput',0),...
    arrayfun(@(x) splitapply(@mean, PPV_W(:,x), G), 1:3,'UniformOutput',0)];
Stds = [arrayfun(@(x) splitapply(@std, Sen_W(:,x), G), 1:3,'UniformOutput',0),...
    arrayfun(@(x) splitapply(@std, PPV_W(:,x), G), 1:3,'UniformOutput',0)];
% Means = arrayfun(@(x) fillmissing(Means{1,x},'constant',0),1:6,'uni',0);
% Stds = arrayfun(@(x) fillmissing(Stds{1,x},'constant',0),1:6,'uni',0);
Stes = arrayfun(@(x) Stds{1,x}./sqrt(cnt_unique'), 1:6,'uni',0);

numlabels = arrayfun(@(s) sprintf('%1.0f',s),cnt_unique,'UniformOutput',false);
colors = lines(length(unique_a));
% colors = linspace(0,1,)

figure('Units','normalized','OuterPosition',[0 0 1 1])
tiledlayout(2,3,'TileSpacing','compact')
for i = 1:length(Means)
    nexttile
    yline(mean(Means{1,i}),':','LineWidth',2,'Alpha',.3); hold on;
    for j = 1:length(Means{1,i})
        if cnt_unique(j) == 3
            errorbar(unique_a(j), Means{1,i}(j), Stes{1,i}(j), ...
                'o','MarkerSize',8,'MarkerFaceColor','white', ...
                'LineStyle','none','Color',colors(1,:),'LineWidth',1); hold on;
        else
            errorbar(unique_a(j), Means{1,i}(j), Stes{1,i}(j),...
                'o','MarkerSize',8,'MarkerFaceColor','white',...
                'LineStyle','none','Color',colors(2,:),'LineWidth',1);
        end
%         text(unique_a(j),Means{1,i}(j),numlabels{j},'HorizontalAlignment','center', ...
%             'Color',colors(j,:),'FontSize',12,'FontWeight','bold')
    end
    if i == 1; ylabel('Specificity');
    elseif i == 4; ylabel('NPV');
    elseif i == 5; xlabel('Subjects');
    end
    if i < 4
        title(sprintf(Sensors2{i}));
    end
%     t = text(16,1,sprintf('SD = %.3f',std(Stes{1,i})),'FontName','Calibri light')
%     t = text(20,1.1,sprintf('%.2f (%.3f)',mean(Stes{1,i}),std(Stes{1,i})),'FontName','Calibri light',...
%         'FontSize',12,'HorizontalAlignment','right')
    t = text(20,1.1,sprintf('%.2f',std(Means{1,i})),'FontName','Calibri light',...
        'FontSize',16,'HorizontalAlignment','right')
    
end
set(findobj(gcf,'type','axes'),'YLim',[-.3 1.3], 'XLim',[0 21],'FontName','Calibri light', ...
    'FontSize',18)
% vartestn([Means{1,1},Means{1,2}],'TestType','LeveneAbsolute') % for
% absolute values
% vartestn([Means{1,1},Means{1,3}],'TestType','LeveneAbsolute') %for within
% subjects
end
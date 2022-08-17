function [actiIndDates] = MatchActiFileDate(actiFiles)
%creats a cell array- each row contains unique dates for matching actifile
%(according to actFiles structures order)

actiIndDates = cell((size(actiFiles,1)/2),1);

ii = 1;
for i = 1:2:size(actiFiles,1)
    opts = detectImportOptions(actiFiles(i).name);
    opts = setvaropts(opts,'Date','InputFormat','MM/dd/yy');
    acti = readtable(actiFiles(i).name,opts);
    dates = unique(acti.Date);

    actiIndDates{ii,1} = unique(dates);
    ii= ii+1;
% good time to pause and check the dates.
%     if contains(actiFiles(i).name,'CK.csv')
%         actiIndDates{ii,1} = unique(dates);
%     elseif contains(actiFiles(i).name,'S.csv')
%         actiIndDates{ii,2} = unique(dates);
%         ii = ii+1;
%     end
    
end
    
end


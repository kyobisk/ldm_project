%% Kyobi Skutt-Kakaria
% 01.22.2018 - Created
% 02.14.2018 - updated


%% Select files to analyze

% opens a ui to select mat files to analyze
fullPath = pwd;
files = uigetfile('*.mat','MultiSelect','on');
if iscell(files) ~= 1
    files = {files};
end

% loads an experimental design file, script expects a n x 3 array where n is the number of bins in
% the stimulus sequence. col 1 is the bin length in seconds, col 2 is a logical vector indicating
% whether the `lights were on or off in that bin. col 3 is a vector of pwm values that reflect the
% pwm setting of the arduino controlling the led light board.
lightDat = dlmread('lightSequence_5Mins.txt');
lightDat = [lightDat;lightDat(end,:)];
lightDat(end,1) = lightDat(end,1)*10;
tic
%turnDirs = batch(clust,@extractTurns,1,{files,lightDat});
toc

%turnDirs = cell(0);
tic
for ii = 1:length(files)
    load(files{ii}) 
    turnDirs = extractTurns(flyTracks,files{ii},lightDat);
    toc
    save(strcat(files{ii}(1:(end-4)),'_processed.mat'),'turnDirs')
end
toc

%% Make large cell array to handle all data that I can query for groups

files = uigetfile('*.mat','MultiSelect','on');
[allDataCell, cellColNames] = parseProcessedFiles(files);

%%
    
array = allDataCell;

array(:,3) = upper(array(:,3));


%% Generate ldm bar plot

[a,b,c] = unique(array(:,3));

ldmNull = nan(1,2);
numRe = 10000;
ldm = nan(length(a),numRe);
f = @(x) (x - nanmean(x))./nanstd(x);
for ii = 1:length(a)
    turns = array(c==ii,1);
    light = array(c==ii,11);
   
    dat = nan(sum(c==ii),1);
    err = dat;
    for jj = 1:length(turns);
        tb_light = turnbias(turns{jj}(light{jj}));
        tb_dark = turnbias(turns{jj}(~light{jj}));
        dat(jj) = tb_light(:,1) - tb_dark(:,1);
        err(jj) = sqrt(tb_light(:,2).^2 + tb_dark(:,2).^2);
    end
    index = ~isnan(dat);
    dat = dat(index);
    err = err(index);

    ldm(ii,:) = abs(bootstrp(numRe,@(dat,err) sqrt(var(dat) - mean(err.^2)),dat,err)');
    n(ii) = min(sum(~isnan(dat)));
end

id = strcmp(a(e),'ISO31');
[d,e] = sort(nanmean(ldm,2));
ldm = ldm(e,:);
n = n(e);

names = {'CS','cry[1]','cry[2]','Rh4','eya',...
    'gmr-hid','iso31','Rh1[7]','Rh1[8]','NorpA-'};

errorbar(nanmean(ldm,2),nanstd(ldm,[],2),'LineStyle','none','CapSize',0,'MarkerSize',10,'Marker','o',...
    'MarkerFaceColor','auto','LineWidth',2)
set(gca,'XLim',[0 11],'YLim',[0 0.15],'XTickLabel',names(e),'XTickLabelRotation',45,...
    'XTick',1:10)
ylabel('LDM')
pbaspect([1.5 1 1])
eles = {'ldm_resamples','names','n','eles'};
LDM_Figure_2a = {ldm,names(e),n(e),eles};
save('LDM_Figure_2a.mat','LDM_Figure_2a');


shg
%%
notNans = all(all(squeeze(~isnan(data(:,2,:,:))),3),2);
idx = (idx1 | idx2) & notNans;

subArray = array(idx,:);



%% Generate scatter plots and corr bar graph


% set index of behavior you're interested in
behave = 2;

% extract behavior biases for each light bin and time bin
dat1 = data(idx,behave,1,1);
err1 = error(idx,behave,1,1);

dat2 = data(idx,behave,1,2);
err2 = error(idx,behave,1,2);

dat3 = data(idx,behave,2,1);
err3 = error(idx,behave,2,1);

dat4 = data(idx,behave,2,2);
err4 = error(idx,behave,2,2);


% make scatter plots
figure
hScat1 = scatter(dat2,dat1);
hRef1 = line([0.05,0.95],[0.05 0.95]);

figure
hScat2 = scatter(dat4,dat3);
hRef2 = line([0.05,0.95],[0.05 0.95]);

figure
hScat3 = scatter(dat4,dat1);
hRef3 = line([0.05,0.95],[0.05 0.95]);

set([hScat1,hScat2,hScat3],'Marker','o','MarkerFaceColor','flat','MarkerEdgeColor','black',...
    'SizeData',repmat(100,size(dat1,1),1))

set([hScat1.Parent, hScat2.Parent, hScat3.Parent],'XLim',[0 1],'YLim',[0 1],'FontSize',...
    24,'XTick', 0:0.5:1, 'YTick',...
    0:0.5:1, 'FontWeight', 'bold', 'PlotBoxAspectRatio', [1 1 1])

set([hRef1, hRef2, hRef3],'Color','black','LineWidth',2)

ylab1 = 'Light Bias (0-120 mins)';
ylab2 = 'Dark Bias (0-120 mins)';
ylabel(hScat1.Parent, ylab1); ylabel(hScat2.Parent, ylab2); ylabel(hScat3.Parent, ylab1);

xlab1 = 'Light Bias (120-240 mins)';
xlab2 = 'Dark Bias (120-240 mins)';
xlabel(hScat1.Parent, xlab1); xlabel(hScat2.Parent, xlab2); xlabel(hScat3.Parent, xlab2);

title(hScat1.Parent, 'Light versus Light');
title(hScat2.Parent, 'Dark versus Dark');
title(hScat3.Parent, 'Light versus Dark');

f = @(x,y) corr(x,y,'rows','pairwise','type','Pearson');
corrs1 = bootstrp(10000, f, dat1, dat2);
corrs2 = bootstrp(10000, f, dat3, dat4);
corrs3 = bootstrp(10000, f, dat1, dat4);

y = [nanmean(corrs1), nanmean(corrs2), nanmean(corrs3)];
e = [nanstd(corrs1), nanstd(corrs2), nanstd(corrs3)];

figure
hold on
bar(1:3,y,'FaceColor',[0.5 0.5 0.5])
errorbar(1:3,y,e,'LineStyle','none','LineWidth',5,'Color',[0 0 0],'CapSize',10)
set(gca,'XLim',[0.5 3.5],'YLim',[0 1],'FontWeight','bold','XTick',1:3,'XTickLabel',...
    {'\rho_{Light,Light}','\rho_{Dark,Dark}','\rho_{Light,Dark}'},'XTickLabelRotation',45,...
    'YTick',0:0.5:1,'FontSize',32,'PlotBoxAspectRatio',[0.75 1 1])
ylabel('Spearman Correlation Coefficient','FontSize',24)



%% Make individual plot


nyidalur=interp1([1 128 129 256],[1 0 1; .2559 .248 .2559; .248 .2559 .248; 0 1 0],1:256);

[a,b] = sort(dat1 - dat3);

%[a,b] = sort(dat2 - dat4);

idx = b(end-2);

timeRange = [120 360]*60;
timeBins = [timeRange(1):900:timeRange(2)];
xVals = 7.5:15:240;

bias = nan(length(timeBins)-1,2);

tStamps = subArray{idx,2};
turns = subArray{idx,1};

turns = turns(tStamps>=timeRange(1) & tStamps<timeRange(2));
tStamps = tStamps(tStamps>=timeRange(1) & tStamps<timeRange(2));

turnFilter = 10;
for ii = 1:length(timeBins)-1
    tI = tStamps >= timeBins(ii) & tStamps < timeBins(ii+1);
    turn = turns(tI); 
    if length(turn) > turnFilter
    bias(ii,:) = turnbias(turn);
    end
end

figure
hPlot = plot(xVals,bias(:,1));
set(hPlot,'LineWidth',2,'LineStyle','--','Marker','s','MarkerSize',12,'Color','black',...
    'MarkerFaceColor','black')
set(hPlot.Parent,'YLim',[0 1])

hold on
xS = 10;
offset = 1.23;
for jj = 1:length(turns)
        x = [tStamps(jj)-xS,tStamps(jj)+xS,tStamps(jj)+xS,tStamps(jj)-xS]/60 - timeRange(1)/60;
    if turns(jj)
        y = [0 0 0.1 0.1] + offset;
        col = nyidalur(50,:);
    else
        y = [0 0 -0.1 -0.1] + offset;
        col = nyidalur(end-50,:);
    end
    hPatch = patch(x,y,col,'EdgeAlpha',0,'FaceAlpha',0.4);
end


lightV = [repmat([0.2 0.2 0 0],1,length(xVals)/2)];
y = interleave2(timeBins,timeBins)/60 - timeRange(1)/60;
offset3 = 1.5;
hPlot2 = plot(y(2:end-1),lightV+offset3,'Color','black','LineWidth',2);

yMax = 1.75;
x = interleave2(15:15:240,15:15:240)';
y = repmat([0 yMax yMax 0],1,floor(length(x)/4));
patch(x,y,[0 0 0],'FaceAlpha',0.1,'EdgeAlpha',0)

patch([0 250 250 0],[1 1 1.05 1.05],[1 1 1],'EdgeAlpha',0)
offset2 = 0.4;
patch([0 250 250 0],[1 1 1.05 1.05]+offset2,[1 1 1],'EdgeAlpha',0)



set(gca,'YLim',[0 yMax],'YTick',[0:0.5:1],'Box','off','FontSize',28,'FontWeight','bold',...
    'XLim',[0 250],'XTick',0:60:240,'TickDir','out')
ylabel('Turn Bias','FontSize',22)
xlabel('Time (mins)','FontSize',22)

set(gcf,'Renderer','painters')

%% Histogram plot


%% Supplemental figures

% activity versus TB
figure
% extract behavior biases for each light bin and time bin
dat1 = data(idx,1,1,1);
err1 = error(idx,1,1,1);

dat2 = data(idx,2,1,1);
err2 = error(idx,2,1,1);

dat3 = data(idx,2,2,1);
err3 = error(idx,2,2,1);

dat4 = dat2 - dat3;

figure
hScat1 = scatter(dat1,dat2);
figure
hScat2 = scatter(dat1,dat3);
figure
hScat3 = scatter(dat1,dat4);

set([hScat1,hScat2,hScat3],'Marker','o','MarkerFaceColor','flat','MarkerEdgeColor','black',...
    'SizeData',repmat(100,size(dat1,1),1))

set([hScat1.Parent,hScat2.Parent,hScat3.Parent],'YLim',[0 1],'FontSize',...
    24, 'YTick',...
    0:0.5:1, 'FontWeight', 'bold', 'PlotBoxAspectRatio', [1 1 1])

set(hScat3.Parent,'YLim',[-0.5 0.5],'YTick',-0.5:0.5:0.5)

xlabel(hScat1.Parent,'Activity');xlabel(hScat2.Parent,'Activity');xlabel(hScat3.Parent,'Activity');
ylabel(hScat1.Parent,'Light Turn Bias'); ylabel(hScat2.Parent,'Dark Turn Bias');...
    ylabel(hScat3.Parent,'\Delta Turn Bias');

%% to make:

% histograms of light and dark
% Wall following transition over longer time periods to see if early wall following becomes less
% over time
% Supplemental figures showing how the individual stats change over the 8 hour experiment time
% SF for sex effects

%%
clf
%generateDistPlots([data(idx1,:,1,:,bin),data(idx1,:,2,:,bin)],[error(idx1,:,1,:,bin) error(idx1,:,2,:,bin)]);
out = generateDistPlots([data(idx,:,1,:,bin),data(idx,:,2,:,bin)],...
    [error(idx,:,1,:,bin) error(idx,:,2,:,bin)]);
set(gca,'PlotBoxAspectRatio',[1.5 1 1])
print('distributionPlot','-dpdf','-fillpage')


%%
clf
generateDiffPlot4([data(idx,:,1,:,bin),data(idx,:,2,:,bin)],...
    [error(idx,:,1,:,bin) error(idx,:,2,:,bin)])
set(gca,'FontSize',24,'FontWeight','bold','FontName','times','XLim',[-0.5 0.5],'PlotBoxAspectRatio',...
    [1.5 1 1],'XTick',-1:0.25:1,'PlotBoxAspectRatio',[1.5 1 1])
print('ldm_plot','-dpdf','-fillpage')


%% Make correlation heatmaps between all 5 metrics

blanding=interp1([1 128 129 256],[0 1 1; .248 .2559 .2559; .2559 .248 .248; 1 0 0],1:256);
mokidugway=interp1([1 128 129 256],[0 0.3 1; .9921 1 1; 1 .9921 .9921; 1 0 0],1:256);

YNames = {'Activity','Turn Bias', 'Turn Direction Streakiness','Wall Proximity',...
    'Turn Timing Clumpiness'};

data1 = data(idx,:);
error1 = error(idx,:);


%data1(:,[2 7]) = abs(data1(:,[2 7])-0.5);


figure
corrs1 = corr(data1(:,6:10),'type','Spearman','rows','pairwise');
imagesc(corrs1)
colormap(mokidugway)
hCb = colorbar;
caxis([-1 1])
set(gca,'YTickLabel',YNames,'XTickLabel',YNames,'YTick',1:5,'XTickLabelRotation',25,'XTick',1:5,...
    'FontWeight','bold','FontSize',20)
title('Dark')
pbaspect([1 1 1])
ylabel(hCb,'\rho_{dark}','Rotation',270,'VerticalAlignment','cap')

figure
corrs2 = corr(data1(:,1:5),'rows','pairwise','type','Spearman');
imagesc(corrs2)
colormap(mokidugway)
hCb = colorbar;
caxis([-1 1])
set(gca,'YTickLabel',YNames,'XTickLabel',YNames,'YTick',1:5,'XTickLabelRotation',25,'XTick',1:5,...
    'FontWeight','bold','FontSize',20)
title('Light')
pbaspect([1 1 1])
ylabel(hCb,'\rho_{light}','Rotation',270,'VerticalAlignment','cap')

figure
imagesc(corrs2-corrs1)
colormap(mokidugway)
hCb = colorbar;
caxis([-0.5 0.5])
set(gca,'YTickLabel',YNames,'XTickLabel',YNames,'YTick',1:5,'XTickLabelRotation',25,'XTick',1:5,...
    'FontWeight','bold','FontSize',20)
title('Light - Dark')
pbaspect([1 1 1])
ylabel(hCb,'\rho_{light} - \rho_{dark}','Rotation',270,'VerticalAlignment','cap')

figure
corrs4 = corr(data1(:,1:5)-data1(:,6:10),'rows','pairwise','type','Spearman');
imagesc(corrs4)
colormap(mokidugway)
hCb = colorbar;
caxis([-1 1])
set(gca,'YTickLabel',YNames,'XTickLabel',YNames,'YTick',1:5,'XTickLabelRotation',25,'XTick',1:5,...
    'FontWeight','bold','FontSize',20)
title('LDM')
pbaspect([1 1 1])
ylabel(hCb,'\rho_{light}','Rotation',270,'VerticalAlignment','cap')


figure
corrs4 = corr([data1,data1(:,1:5)-data1(:,6:10)],'rows','pairwise','type','Spearman');
imagesc(corrs4)
colormap(mokidugway)
hCb = colorbar;
caxis([-1 1])
% set(gca,'YTickLabel',YNames,'XTickLabel',YNames,'YTick',1:5,'XTickLabelRotation',25,'XTick',1:5,...
%     'FontWeight','bold','FontSize',20)
title('LDM')
pbaspect([1 1 1])
ylabel(hCb,'\rho_{light}','Rotation',270,'VerticalAlignment','cap')

%% Generate a transition triggered average

figure
colors = {[0 0 0],[0.8 0.2 0],[0 0.6 0.2]}; 
alpha = 0.5;

behave = 2;
light = 1;

c1 = [0.3 0.18 0.7];
c2 = [0.4 0.45 0.5];

subArray    = array(idx,:);

hold on
%yyaxis left
hPlot = generateTTAIBEPlot3(subArray,lightDat,behave,[0 0 0],light);
% figure
% hold on
cruzbay=interp1([1 51 102 153 204 256],[0 0 0; 0 0 .75; 0 .6 .8; 0 .95 0; .85 1 0; 1 1 1],1:256);


set(gca,'Color','none','FontSize',24,'FontWeight','bold','FontName','times','YLim',[0 0.6],...
    'XLim',[-3 6])


ylabel('| Light Bias - Dark Bias |')
xlabel('Time (min)')

pbaspect([1.5 1 1])
set(gcf,'Renderer','painters')
%ylabel('Activity Corrected LDM')
%line([0 0],[0 0.125],'Color','black','LineStyle','--','LineWidth',3)
if light
    hPatch = patch([-3 -3 0 0],[0 1 1 0],[0 0 0]);

else
    hPatch = patch([0 0 6 6],[0 1 1 0],[0 0 0]) ;
end
set(hPatch,'FaceAlpha',0.1,'EdgeAlpha',0)
colorbar

print('TTA_AllInds','-dpdf','-fillpage')


shg
%%
yyaxis right
%hError2 = generateTTAMedianPlot(subArray,lightDat,4,c1,0);
hError3 = generateTTAMedianPlot(subArray,lightDat,4,c2,1);

set(gca,'FontSize',28,'YColor',c2,'YLim',[0.53 0.6])
ylabel('Median Wall Proximity')
xlabel('Time (secs)')


%%
timeBin = 15;
tMax = 500;
timeBins = ((timeBin/2):timeBin:(tMax-timeBin/2))*60;

fly = 10
tStamps = subArray{fly,2};

for ii = 1:(length(timeBins)-1)
    ind = tStamps >= timeBins(ii) & tStamps < timeBins(ii+1);
    tStamps(ind) = tStamps(ind) - ii*timeBin*60;
end



%% Make wall following figure
%load(files(4).name)

clf
clear tData lIdx rIdx wData lData rData centData centApp
for kk = 1:2
    for jj = 1:120
        
        fly = jj;
        
        timepoints = turnDirs.allTStamps{fly} < 240*60;
        
        if kk == 1
            lightstatus = logical(turnDirs.allLight{fly});
        else
            lightstatus = ~logical(turnDirs.allLight{fly});
        end
        
        idx = timepoints & lightstatus;
        
        tData{jj,kk} = turnDirs.allTurnDir{fly}(lightstatus);
        lIdx = ~tData{jj,kk};
        rIdx = tData{jj,kk};
        wData{jj,kk} = turnDirs.allWallDist{fly}(lightstatus);
        lData{jj,kk} = wData{jj,kk}(lIdx);
        rData{jj,kk} = wData{jj,kk}(rIdx);
        nanmean(rData{jj,kk}) - nanmean(lData{jj,kk});
        centData{jj,kk} = turnDirs.allCentDist{fly}(lightstatus);
        centApp{jj,kk} = turnDirs.allCentApp{fly}(lightstatus,:);
    end
    ldmWallVect(:,kk) = cellfun(@nanmean,rData(:,kk)) - cellfun(@nanmean,lData(:,kk));
end
[a,b] = sort(ldmWallVect(:,2) - ldmWallVect(:,1),'descend');
b = b(~isnan(a));
a = a(~isnan(a));




%% Make wall following figure
figure
fly = 89; % 14
lightStatus = 2;
tData1 = logical(cat(1,tData{fly,lightStatus}));
lIdx = ~tData1;
rIdx = tData1;
wData1 = cat(1,wData{fly,lightStatus});
lData1 = cat(1,lData{fly,lightStatus});
rData1 = cat(1,rData{fly,lightStatus});
centData1 = cat(1,centData{fly,lightStatus});
centApp1 = cat(1,centApp{fly,lightStatus});
nyidalur=interp1([1 128 129 256],[1 0 1; .2559 .248 .2559; .248 .2559 .248; 0 1 0],1:256);

subplot(3,4,[1,2,5,6,9,10])

% scatter(centApp1(:,1),centApp1(:,2),...
%     [],double(tData1),'MarkerEdgeAlpha',0.8,'Marker','.')
colormap(nyidalur)
% pbaspect([1 1 1])
%
[bc,i] = histc(centApp1,[0:0.5:30]);

hValue = nan(max(i(:,2)),max(i(:,1)));
for ii = 1:max(i(:,1))
    for jj = 1:max(i(:,2))
        pts = i(:,1) == ii & i(:,2) == jj;
        if nansum(pts) > 5
            sum(pts);
            hValue(jj,ii) = nansum(pts & tData1)/nansum(pts);
        end
    end
end

% hValue = hValue(~all(isnan(hValue),2),~all(isnan(hValue),1));

alphaIm =  zeros(size(hValue));
alphaIm(~isnan(hValue)) = 1;
hImage = imagesc(hValue,'AlphaData',alphaIm);


binEdges = 4:2:14;

b1 = discretize(centData1(lIdx),binEdges);
b2 = discretize(centData1(rIdx),binEdges);

binVect = nan(length(binEdges),2);
binCV = binVect;
binCell = cell(0);
for ii = 1:max(b1)
    binVect(ii,1) = nanmean(lData1(b1==ii));
    binVect(ii,2) = nanmean(rData1(b2==ii));
    binCV(ii,1) = nanstd(lData1(b1==ii));
    binCV(ii,2) = nanstd(rData1(b2==ii));
    binCell{ii}{1} = lData1(b1==ii);
    binCell{ii}{2} = rData1(b2==ii);
end

binVect = [smooth(binVect(:,1),10), smooth(binVect(:,2),10)];

subplot(3,4,[3 7 11])
hScatter = scatter(wData1,centData1,...
    'CData',double(tData1),'MarkerEdgeAlpha',0.8,'Marker','.');
hold on
pbaspect([1,3,1])

% 
% plot(-binEdges',binVect(:,1),'-o','LineWidth',3,'Color',[0.3 0 0.3],'Marker','none')
% plot(-binEdges',binVect(:,2),'-o','LineWidth',3,'Color',[0 0.3 0],'Marker','none')
% colormap(gca,colors)
% line(-[3 20],[nanmean(binVect(:)) nanmean(binVect(:))],'color','black')


histBinEdges = 0:0.05:1;

subplot(3,4,4)

cellNum = max(b1);
h = histogram(binCell{cellNum}{1},histBinEdges,'Normalization',...
    'probability','FaceColor',nyidalur(1,:));
hold on
line([nanmedian(binCell{cellNum}{1}) nanmedian(binCell{cellNum}{1})], [0 0.25],...
    'color','black','LineWidth',2)
histogram(binCell{cellNum}{2},histBinEdges,'Normalization','probability','FaceColor',nyidalur(end,:))
ylim([0 0.3])
line([nanmedian(binCell{cellNum}{2}) nanmedian(binCell{cellNum}{2})], [0 0.25],...
    'color','black','LineWidth',2)

subplot(3,4,8)

cellNum = floor(max(b1)/2);
histogram(binCell{cellNum}{1},histBinEdges,...
    'Normalization','probability','FaceColor',nyidalur(1,:))
hold on
line([nanmedian(binCell{cellNum}{1}) nanmedian(binCell{cellNum}{1})], [0 0.25],...
    'color','black','LineWidth',2)
histogram(binCell{cellNum}{2},histBinEdges,'Normalization','probability','FaceColor',nyidalur(end,:))
ylim([0 0.3])
line([nanmedian(binCell{cellNum}{2}) nanmedian(binCell{cellNum}{2})], [0 0.25],...
    'color','black','LineWidth',2)

subplot(3,4,12)


cellNum = 1;
histogram(binCell{cellNum}{1},histBinEdges,'Normalization','probability','FaceColor',nyidalur(1,:))
hold on
line([nanmedian(binCell{cellNum}{1}) nanmedian(binCell{cellNum}{1})], [0 0.25],...
    'color','black','LineWidth',2)
histogram(binCell{cellNum}{2},histBinEdges,'Normalization','probability','FaceColor',nyidalur(end,:))
ylim([0 0.3])
line([nanmedian(binCell{cellNum}{2}) nanmedian(binCell{cellNum}{2})], [0 0.25],...
    'color','black','LineWidth',2)
shg
%% Wall dist assym versus ldm
subArray = array(1:100,:);
wallDistM = nan(size(subArray,1),2);
timeBin = 30;
dEnd = [-120:30:360];
for ii = 1:size(subArray,1)
    for kk = 1:length(dEnd)
    walls = subArray{ii,10};
    turns = subArray{ii,1};
    light = subArray{ii,11};
    tStamps = subArray{ii,2};
    [x1,x2,tt] = calculateRelativeTime(tStamps,lightDat);
    idx = ~light & (x1 >= dEnd(kk)) & (x1 < dEnd(kk)+timeBin);
    temp = wallAssym(walls(idx),turns(idx));
    wallDistM(ii,kk) = temp(1);
    end
end
%%
scatter(wallDistM(:,1),data(1:100,7))
shg


%% 
generateTTALdmVersusMedWall(subArray,lightDat,0)

%%
data2 = data1( ~any(isnan(data1),2) , : );
clf
figure; hold on
idx = randi(size(data2,1),50,1);
tempData = data2(idx,:);
scatter(tempData(:,2),tempData(:,4))
scatter(tempData(:,7),tempData(:,9))
for ii = 1:size(tempData,1)
    line(tempData(ii,[2 7]),tempData(ii,[4 9]))
end


[zs1,mu,we] = zscore(data2(:,1:5));
[a,b,c,d,e,f] = pca(zs1);
d1 = b;

[zs2,mu,we] = zscore(data2(:,6:10));
d2 = zs2*a;

figure; hold on
pcN = [2 3]
d1 = d1(idx,:);
d2 = d2(idx,:);
scatter(d1(:,pcN(1)),d1(:,pcN(2)))
scatter(d2(:,pcN(1)),d2(:,pcN(2)))
for ii = 1:size(tempData,1)
    line([d1(ii,pcN(1)) d2(ii,pcN(1))],[d1(ii,pcN(2)) d2(ii,pcN(2))])
end

%% Make a figure that shows expected variation in turn bias as a function of time
% I am trying to figure out how to account for drift of turn bias and correct for it in my corrected
% LDM statistic

for jj = 1:25%size(subArray,1)
dTs = subArray{jj,2}-subArray{jj,2}';
interval = 10;
dEnd = [-120:interval:300]*60;
interval = interval*60;
tb = nan(length(dEnd),2);

for ii = 1:length(dEnd)-1
    tIdx = any(dTs > dEnd(ii) & dTs < dEnd(ii) + interval,2);
    tb(ii,:) = turnbias(subArray{jj,1}(tIdx));
    
end

allTbs(:,jj) = abs(tb(2:end,1) - tb(1,1));
nullTbs(:,jj) = nanmean(bootstrp(1000,@(x)...
    abs(x(1,1) - normrnd(x(2:end,1),x(2:end,2))),tb),1);

end

plot(allTbs - nullTbs)


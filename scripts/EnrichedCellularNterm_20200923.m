%% Figure 3 and STables - Cellular factors modulated by infection


clear
clc

path = '/Users/ed/Documents/GitHub/sars2nterm/data/';

% Load data
dat = struct();


% Load the Quant search evidence and peptide files
dat.evi.A549 = readtable([path , 'tA549_Enrich/evidence.txt']);1
dat.evi.Vero = readtable([path , 'tVero_Enrich/evidence.txt']);2

dat.pep.A549 = readtable([path , 'tA549_Enrich/peptides.txt']);3
dat.pep.Vero = readtable([path , 'tVero_Enrich/peptides.txt']);4

% Load the Var search evidence files
dat.var.A549 = readtable([path , 'tA549_EnrichVar/evidence.txt']);5
dat.var.Vero = readtable([path , 'tVero_EnrichVar/evidence.txt']);6

samples = {'A549','Vero'};

%% Import gene name/signal peptide data from uniprot
gn = struct();

gn.human = readtable([path , 'human_acc_to_gn_signaltransit.csv']);
gn.vero  = readtable([path , 'vero_acc_to_gn_signaltransit.csv']);

% Load in the TMTpro design matrices containing the randomised layouts
% A549-ACE2
dat.tmt.A549 = readmatrix([path , 'SARS2a549tmtlabelling_20200507.csv']);
% VeroE6
dat.tmt.Vero = readmatrix([path , 'Verotmtlabelling_20200511.csv']);

% Rearrange the Reporter channels in dat.evi to obtain the correct order of
% Channels:
% Channel layout from 1-16 after reordering is:
% 0h  Mock
% 0h  A
% 0h  B
% 0h  C
% 6h  A
% 6h  B
% 6h  C
% 12h A
% 12h B
% 12h C
% 24h A
% 24h B
% 24h C
% 24h Mock A
% 24h Mock B
% 24h Mock C

% Reorder the corrected RI intensity channels

dat.pep.A549(:,44:59) = dat.pep.A549(: , dat.tmt.A549(2,:) + 43);
dat.pep.Vero(:,44:59) = dat.pep.Vero(: , dat.tmt.Vero(2,:) + 43);


% Backup temp
backup = dat;
%% Data cleanup
dat = backup;

% Remove Reverse hits, Contaminants and low PEP identifications
for ii = 1:numel(samples)
    % Remove PEP <= 0.02
    dat.pep.(samples{ii}) = dat.pep.(samples{ii})(dat.pep.(samples{ii}).PEP <= 0.02 , :);
    % Remove Reverse hits
    dat.pep.(samples{ii}) = dat.pep.(samples{ii})(categorical(dat.pep.(samples{ii}).Reverse) ~= '+' , :);
    % Remove potential contaminants
    dat.pep.(samples{ii}) = dat.pep.(samples{ii})(categorical(dat.pep.(samples{ii}).PotentialContaminant) ~= '+' , :);
end
%
% Now Convert the TMT RI data to matrix form

for ii = 1:numel(samples)
   % Convert table columns to a matrix
    dat.mat.(samples{ii}) = table2array(dat.pep.(samples{ii})(: , [44:59]));
   
   % Convert 0 to NaN;
   dat.mat.(samples{ii})(dat.mat.(samples{ii}) == 0) = NaN; 
end

% Remove unquantified hits, column normalise, impute and row normalise.
for ii = 1:numel(samples)
   % identify rows with >75% NaN
   allNaN = sum(isnan(dat.mat.(samples{ii})) , 2) >13;
   dat.mat.(samples{ii}) = dat.mat.(samples{ii})(~allNaN , :);
   dat.pep.(samples{ii}) = dat.pep.(samples{ii})(~allNaN , :);
   
   clear allNaN
   
   % Median normalise
    dat.mat.(samples{ii}) = dat.mat.(samples{ii}) ./ nanmedian(dat.mat.(samples{ii}));

    % Knn impute missing data
    dat.mat.(samples{ii}) = knnimpute(dat.mat.(samples{ii}));

    % Row normalise by mean (whole dataset) 
    dat.mat.(samples{ii}) = dat.mat.(samples{ii}) ./ mean(dat.mat.(samples{ii}) , 2);
 
    % Generate matrix with 24h data only
    dat.h24.(samples{ii}) = dat.mat.(samples{ii})(:,[end-5: end]);
   
end

backup2 = dat;

%%
dat = backup2;

 for ii = 1:numel(samples)
    dat.h24.(samples{ii}) = dat.h24.(samples{ii})(dat.pep.(samples{ii}).StartPosition > 2 , :);
    dat.mat.(samples{ii}) = dat.mat.(samples{ii})(dat.pep.(samples{ii}).StartPosition > 2 , :);
    dat.pep.(samples{ii}) = dat.pep.(samples{ii})(dat.pep.(samples{ii}).StartPosition > 2 , :);
 end
 
 
%% KS testing of proteins matching LxGG or (STVP)xLQ, DEVD?
 
 % Extract the P4 to P1 sequence from the Nterm cleavage window
 for ii = 1:numel(samples) 
     
     for jj = 1:numel(dat.pep.(samples{ii}).N_termCleavageWindow)
     
         dat.pep.(samples{ii}).p4p1{jj} = dat.pep.(samples{ii}).N_termCleavageWindow{jj}(12:15);
     
     end
     
 end
 
 % Regexp
 dat.reg.Nsp5 = '[A|S|T|V|P].LQ'; % Note added 'A'
 dat.reg.Nsp3 = 'L.GG';
 
for ii = 1:numel(samples)
    regNsp3  = regexp(dat.pep.(samples{ii}).p4p1 , dat.reg.Nsp3);
    regNsp5  = regexp(dat.pep.(samples{ii}).p4p1 , dat.reg.Nsp5);
    
    dat.viralProMatch.nsp3.(samples{ii}) = ~cellfun(@isempty , regNsp3);
    dat.viralProMatch.nsp5.(samples{ii}) = ~cellfun(@isempty , regNsp5);
    
    clear regNsp3 regNsp5
end
 
 %% Plot distribution of results

yl = 3.5; % set y axis limit

figure
t = tiledlayout(2,2,'TileSpacing','compact');

% A549 nsp5
 dat.vmat.A549 = [dat.h24.A549(:,1);dat.h24.A549(:,2);dat.h24.A549(:,3)];
[B, I] = sort(dat.vmat.A549, 'descend');
 
nexttile
 b = bar(log2(B),'FaceColor','k');
 b.FaceColor = 'flat';
 b.FaceAlpha = 0.3;

 dat.vpv.nsp5.A549 = [dat.viralProMatch.nsp5.A549;dat.viralProMatch.nsp5.A549;dat.viralProMatch.nsp5.A549];
 
  test = 1:numel(dat.vmat.A549);

  test = test(dat.vpv.nsp5.A549(I));
hold on
 
  scatter(test,log2(B(dat.vpv.nsp5.A549(I))),'filled','MarkerFaceAlpha',0.5); % Add scatter plot indicating peptides matching protease consensus
  

 [h,p,k] =  kstest2(test, 1:numel(dat.vmat.A549)) % KS test (two-tailed)
 hold on
 text(numel(dat.vpv.nsp5.A549)/3 , 1.5,['p = ',num2str(p)],'FontSize',14) % Add KS p-value to plot
 title('A549-Ace2: (A|P|S|T|V)xLQ enrichment')
 ylim([-yl yl])
 hold off
 
 % A549 nsp3
 dat.vmat.A549 = [dat.h24.A549(:,1);dat.h24.A549(:,2);dat.h24.A549(:,3)];
[B, I] = sort(dat.vmat.A549, 'descend');
 
nexttile
 b = bar(log2(B),'FaceColor','k');
 b.FaceColor = 'flat';
 b.FaceAlpha = 0.3;

 dat.vpv.nsp3.A549 = [dat.viralProMatch.nsp3.A549;dat.viralProMatch.nsp3.A549;dat.viralProMatch.nsp3.A549];
 
  test = 1:numel(dat.vmat.A549);
  test = test(dat.vpv.nsp3.A549(I));
hold on
 
scatter(test,log2(B(dat.vpv.nsp3.A549(I))),'filled','MarkerFaceAlpha',0.5); % Add scatter plot indicating peptides matching protease consensus
  
 [h,p,k] =  kstest2(test, 1:numel(dat.vmat.A549)) % KS test (two-tailed)
 hold on
 text(numel(dat.vpv.nsp3.A549)/3 , 1.5,['p = ',num2str(p)],'FontSize',14) % Add KS p-value to plot
 title('A549-Ace2: LxGG enrichment')
 ylim([-yl yl])
 hold off
 
 dat.vmat.Vero = [dat.h24.Vero(:,1);dat.h24.Vero(:,2);dat.h24.Vero(:,3)];
[B, I] = sort(dat.vmat.Vero, 'descend');
 
nexttile
 b = bar(log2(B),'FaceColor','k');
 b.FaceColor = 'flat';
 b.FaceAlpha = 0.3;

 dat.vpv.nsp5.Vero = [dat.viralProMatch.nsp5.Vero;dat.viralProMatch.nsp5.Vero;dat.viralProMatch.nsp5.Vero];
 
  test = 1:numel(dat.vmat.Vero);
  test = test(dat.vpv.nsp5.Vero(I));
  
hold on
   scatter(test,log2(B(dat.vpv.nsp5.Vero(I))),'filled','MarkerFaceAlpha',0.5); % Add scatter plot indicating peptides matching protease consensus
  
 [h,p,k] =  kstest2(test, 1:numel(dat.vmat.Vero)) % KS test (two-tailed)
 hold on
 text(numel(dat.vpv.nsp5.Vero)/3 , 1.5,['p = ',num2str(p)],'FontSize',14) % Add KS p-value to plot
 title('Vero E6: (A|P|S|T|V)xLQ enrichment')
 ylim([-yl yl])
 hold off
  
 % Vero nsp3
 dat.vmat.Vero = [dat.h24.Vero(:,1);dat.h24.Vero(:,2);dat.h24.Vero(:,3)];
[B, I] = sort(dat.vmat.Vero, 'descend');
 
nexttile
 b = bar(log2(B),'FaceColor','k');
 b.FaceColor = 'flat';
 b.FaceAlpha = 0.3;

 dat.vpv.nsp3.Vero = [dat.viralProMatch.nsp3.Vero;dat.viralProMatch.nsp3.Vero;dat.viralProMatch.nsp3.Vero];
 
  test = 1:numel(dat.vmat.Vero);
  test = test(dat.vpv.nsp3.Vero(I));
hold on
  scatter(test,log2(B(dat.vpv.nsp3.Vero(I))),'filled','MarkerFaceAlpha',0.5); % Add scatter plot indicating peptides matching protease consensus
 
 [h,p,k] =  kstest2(test, 1:numel(dat.vmat.Vero)); % KS test (two-tailed)
 hold on
 text(numel(dat.vpv.nsp3.Vero)/3 , 1.5,['p = ',num2str(p)],'FontSize',14) % Add KS p-value to plot

 title('Vero E6: LxGG enrichment')
 ylim([-yl yl])
 hold off

 xlabel(t,'Neo-N-terminal peptides');
 ylabel(t,'Log_2 24h Infected / Mock')
 
 print([path , '/Figures/KStest_ConsensusNterm.pdf'],'-dpdf');
 
%% Heat maps - Vero and A549

% Note peptide hits manually curated from those showing t-test significance
% at 24h and matching or close to matching nsp3/5 protease consensus
% sequences and the subset showing significant fold-change)


a549seqs = {'ASQDENFGNTTPR',... % NUP107
    'ASSAASSASPVSR',... % XRCC1
    'FNSSDTVTSPQR',... % SRC - LxGG
    'SKDQITAGNAAR',... % PAICS
    'SSVVATSKER',... % PNN
    'VTTTANKVGR'}; % WNK1
    %'TQGPPDYPR',... % MRPL49  - removed as matches degrabase


veroseqs = {'ALEVLPVAPPPEPR',... % ATAD2
    'APAPWHGEGTSPQLR',... % BST1 - AEGG
    'AQVECSHSSQQR',... % GOLGA3
    'ASSAASSASPVSR',... % XRCC1
    'FQESDDADEDYGR',... % NUCKS1
    'GAAGAGGGGSGAGGGSGGSGGR',... % KLHDC10 - RRGG
    'SFGTEEPAYSTR',... KAT7
    'TSPSPKAGAATGR',... % ATP51B
    'TTSSSITLR'}; % MYLK
    
% T test and multiple hypothesis correction
% Perform t-test for significance
[~ , dat.p.A549 , ~ , ~] = ttest2(log2(dat.h24.A549(:,[1:3])) , log2(dat.h24.A549(:,[4:6])),'Dim',2);
[~ , dat.p.Vero , ~ , ~] = ttest2(log2(dat.h24.Vero(:,[1:3])) , log2(dat.h24.Vero(:,[4:6])),'Dim',2);

%Correct for multiple hypothesis testing
[dat.fdr.A549 , dat.q.A549] = mafdr(dat.p.A549);
[dat.fdr.Vero , dat.q.Vero] = mafdr(dat.p.Vero);

%% Select those samples which made the q-value cutoff
qcut = 0.05; % Q value cutoff

% Select based on qvalue cutoff
dat.matq.A549 = dat.mat.A549(dat.q.A549 <= qcut , :);
dat.matq.Vero = dat.mat.Vero(dat.q.Vero <= qcut , :);

dat.pepq.A549 = dat.pep.A549(dat.q.A549 <= qcut , :);
dat.pepq.Vero = dat.pep.Vero(dat.q.Vero <= qcut , :);

%% Now need to select based on sequences of interest

% Ismember gives only exact, not partial matches
 dat.heatmap.A549 = dat.matq.A549(ismember(dat.pepq.A549.Sequence,a549seqs),:);
 dat.heatmap.Vero = dat.matq.Vero(ismember(dat.pepq.Vero.Sequence,veroseqs),:);

 dat.pepH.A549 = dat.pepq.A549(ismember(dat.pepq.A549.Sequence,a549seqs),:);
 dat.pepH.Vero = dat.pepq.Vero(ismember(dat.pepq.Vero.Sequence,veroseqs),:);



%% Annotate pepH with Gene Names
dat.pepH.A549.Acc = extractBetween(dat.pepH.A549.LeadingRazorProtein,4,9);
dat.pepH.Vero.Acc = extractBetween(dat.pepH.Vero.LeadingRazorProtein,4,13);

[lia, locb] = ismember(dat.pepH.A549.Acc , gn.human.Entry);
dat.pepH.A549.GN = gn.human.GeneNames(locb);
clear lia locb

[lia, locb] = ismember(dat.pepH.Vero.Acc , gn.vero.Entry);
dat.pepH.Vero.GN = gn.vero.GeneNames(locb);
clear lia locb

% Note: GN contains multiple gene names. Keep only the first
% Need to do in a loop so that it only does for those which contain ' '
lia = contains(dat.pepH.A549.GN , ' ');
dat.pepH.A549.GN(lia) = extractBefore(dat.pepH.A549.GN(lia) , ' ');
clear lia
lia = contains(dat.pepH.Vero.GN , ' ');
dat.pepH.Vero.GN(lia) = extractBefore(dat.pepH.Vero.GN(lia) , ' ');
clear lia

% Also want to sort on variance.
dat.hmV.A549 = mean(dat.heatmap.A549(:,11:13),2);
dat.hmV.Vero = mean(dat.heatmap.Vero(:,11:13),2);

[~ , dat.vI.A549] = sort(dat.hmV.A549,'descend');
[~ , dat.vI.Vero] = sort(dat.hmV.Vero,'descend');

%% Want to Add indication of consensus sequence and match to it.
a549yticks = dat.pepH.A549.GN;
veroyticks = dat.pepH.Vero.GN;

% Note: these will be incorrect if the identify/number of selected hits
% changes (shouldn't happen due to manual selection)

% Blue = nsp5 consensus match, red = nsp3 consensus match
a549consensus = {': \color{magenta}V\color{black}l\color{magenta}LQ';...
                 ': \color{magenta}A\color{black}t\color{magenta}LQ';...
                 ': \color{darkGreen}L\color{black}f\color{darkGreen}GG';...
                 ': \color{magenta}V\color{black}l\color{magenta}LQ';...
                 ': \color{magenta}P\color{black}a\color{magenta}LQ';...
                 ': \color{black}QrF\color{magenta}Q'};

veroconsensus = {': \color{black}Ev\color{magenta}LQ';...
                 ': \color{black}Ae\color{darkGreen}GG';...
                 ': \color{magenta}T\color{black}k\color{magenta}LQ';...
                 ': \color{magenta}A\color{black}t\color{magenta}LQ';...
                 ': \color{black}DyS\color{magenta}Q';...
                 ': \color{black}Rr\color{darkGreen}GG';...
                 ': \color{black}Rn\color{magenta}LQ';...
                 ': \color{black}YaA\color{magenta}Q';...
                 ': \color{magenta}P\color{black}v\color{magenta}LQ'};
             
% Now concatenate the Ytick labels so contain gene name, position, and P4 to P1 colored by match to consensus             
for ii = 1:numel(a549yticks)
   a549yticks{ii} = [a549yticks{ii} ,' (',dat.pepH.A549.FirstAminoAcid{ii},num2str(dat.pepH.A549.StartPosition(ii)),')', a549consensus{ii}]; 
end

for ii = 1:numel(veroyticks)
   veroyticks{ii} = [veroyticks{ii} ,' (',dat.pepH.Vero.FirstAminoAcid{ii},num2str(dat.pepH.Vero.StartPosition(ii)),')', veroconsensus{ii}]; 
end
           

figure
t = tiledlayout(2,1)
nexttile
imagesc(log2(dat.heatmap.A549(dat.vI.A549,:))); colormap( redblue( 64 ) ); %rb;
c = colorbar('Ticks',[-2 , -1 , 0 , 1 , 2],'TickLabels',{'\leq-2','-1','0','1','\geq2'})
c.Label.String = 'Log_2 fold-change';
caxis([-2 2])
yticks([1:1:numel(veroyticks)])
yticklabels(a549yticks(dat.vI.A549));
xticks([])
title('A549-Ace2 cellular neo-N-termini')

nexttile
imagesc(log2(dat.heatmap.Vero(dat.vI.Vero,:))); colormap( redblue( 64 ) );%rb;
c = colorbar('Ticks',[-2 , -1 , 0 , 1 , 2],'TickLabels',{'\leq-2','-1','0','1','\geq2'})
c.Label.String = 'Log_2 fold-change';
caxis([-2 2])
yticks([1:1:numel(veroyticks)])
yticklabels(veroyticks(dat.vI.Vero));
xticks([1,3,6,9,12,15])
xticklabels({'0M','0h','6h','12h','24h','24M'})
ylabel(t,'Gene name of cleaved protein')
xlabel(t,'Hours post-infection')
title('Vero E6 cellular neo-N-termini')

% Save figure
print([path , '/Figures/Fig_heatmaps.pdf'],'-dpdf');

%% Export full tables of N-termimi Quantification

% Get the accession number
dat.pep.A549.Acc = extractBetween(dat.pep.A549.LeadingRazorProtein,4,9);
dat.pep.Vero.Acc = extractBetween(dat.pep.Vero.LeadingRazorProtein,4,13);

% Match accession to gene name
[lia, locb] = ismember(dat.pep.A549.Acc , gn.human.Entry);
for ii = 1:numel(dat.pep.A549(:,1))
    dat.pep.A549.GN(ii) = {''};
end
dat.pep.A549.GN(lia) = gn.human.GeneNames(locb(lia));
clear lia locb

[lia, locb] = ismember(dat.pep.Vero.Acc , gn.vero.Entry);
for ii = 1:numel(dat.pep.Vero(:,1))
    dat.pep.Vero.GN(ii) = {''};
end
dat.pep.Vero.GN(lia) = gn.vero.GeneNames(locb(lia));
clear lia locb

% Note: GN contains multiple gene names. Keep only the first
% Need to do in a loop so that it only does for those which contain ' '
lia = contains(dat.pep.A549.GN , ' ');
dat.pep.A549.GN(lia) = extractBefore(dat.pep.A549.GN(lia) , ' ');
clear lia
lia = contains(dat.pep.Vero.GN , ' ');
dat.pep.Vero.GN(lia) = extractBefore(dat.pep.Vero.GN(lia) , ' ');
clear lia

% Generate new tables to hold the output.
TabA = table();
TabV = table();

% Export only the indicated columns
TabA = dat.pep.A549(:,[1,2,103,35,36,105,37,38,42,43,99,100]);

TabV = dat.pep.Vero(:,[1,2,103,35,36,105,37,38,42,43,99,100]);

TabA = [TabA , array2table(log2(dat.mat.A549))];
TabV = [TabV , array2table(log2(dat.mat.Vero))];

% Rename the TMT columns
timepoints = {'TMT_0M','TMT_0hA','TMT_0hB','TMT_0hC','TMT_6hA','TMT_6hB','TMT_6hC','TMT_12hA','TMT_12hB','TMT_12hC','TMT_24hA','TMT_24hB','TMT_24hC','TMT_24MA','TMT_24MB','TMT_24MC'};
TabA.Properties.VariableNames(13:28) = timepoints;
TabV.Properties.VariableNames(13:28) = timepoints;

% Write the output tables
writetable(TabA,[path , 'Tables/A549_Nterm_Quant.csv']);
writetable(TabV,[path , 'Tables/Vero_Nterm_Quant.csv']);
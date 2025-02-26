function [irf_] = plot_irfs_(irfs,options)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Filippo Ferroni, 6/1/2015
% Revised, 2/15/2017
% Revised, 3/21/2018
% Revised, 8/08/2019

% input : irfs
% 1st dimension: variable
% 2nd dimension: horizon
% 3rd dimension: shock
% 4th dimension: draws
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nvar    = size(irfs,1);
hor     = size(irfs,2);
nshocks = size(irfs,3);
ndraws  = size(irfs,4);
%nplots  = [ceil(sqrt(nvar)) ceil(sqrt(nvar))];
nplots = [2, 3]; % 3 rows, 2 columns

savefig_yes = 0;
conf_sig    = 0.68;
normz       = ones(nshocks,1);
add_irfs_yes = 0;
normz_yes   = 0;
add_multiple_bands_yes = 0;
fnam_dir    = '.';
fnam_suffix = 'irfs_';
fontsize    = 12;
ylimits     = 0;

if nargin <2
    disp('You did not provided names for shocks nor variables.')
    disp('I call them Var 1, Var 2, ... and Shck 1, ...')
    for v = 1 : nvar
        eval(['varnames{'   num2str(v) '} =  ''Var  ' num2str(v) ''';'])
    end
    for v = 1 : nshocks
        eval(['shocksnames{' num2str(v) '} =  ''Shck ' num2str(v) ''';'])
    end
else
    if isfield(options,'varnames') ==1
        varnames = options.varnames;
        if length(varnames) ~= nvar
            error('There is a mismatch between the number of var and the names')
        end
    else
        disp('You did not provided names for the endogenous variables.')
        disp('I call them Var 1, Var 2, ...')
        for v = 1 : nvar
            eval(['varnames{'   num2str(v) '} =  ''Var  ' num2str(v) ''';'])
        end
    end
    if isfield(options,'shocksnames') == 1 
        shocksnames = options.shocksnames;
        if length(shocksnames) ~= nshocks
            error('There is a mismatch between the number of shocks and the names')
        end
    elseif isfield(options,'shocknames') == 1 
        shocksnames = options.shocknames;
        if length(shocksnames) ~= nshocks
            error('There is a mismatch between the number of shocks and the names')
        end
    else
        disp('You did not provided names for the shocks.')
        disp('I call them Shck 1,  2, ...')
        for v = 1 : nshocks
            eval(['shocksnames{' num2str(v) '} =  ''Shck ' num2str(v) ''';'])
        end
    end
    if isfield(options,'normz') ==1 && options.normz==1,
        normz_yes = 1;
    end
    if isfield(options,'conf_sig') ==1;
        conf_sig = options.conf_sig;
    end
    if isfield(options,'nplots') ==1;
        nplots = options.nplots;
    end
    if isfield(options,'saveas_strng') ==1;
        savefig_yes = 1;
        % setting the names of the figure to save
        fnam_suffix = [ fnam_suffix options.saveas_strng ];
    end
    if isfield(options,'saveas_dir') ==1;
        savefig_yes = 1;
        % setting the folder where to save the figure
        fnam_dir = options.saveas_dir;
        if exist(fnam_dir,'dir') == 0
            mkdir(fnam_dir)
        end
    end
    if isfield(options,'add_irfs') ==1
        % setting the folder where to save the figure
        add_irfs = options.add_irfs;
        add_irfs_yes = 1;
    end
    if isfield(options,'conf_sig_2') ==1
        add_multiple_bands_yes = 1;
        sort_idx_2   = round((0.5 + [-options.conf_sig_2, options.conf_sig_2, 0]/2) * ndraws);
    end
    if isfield(options,'fontsize') ==1
        % title font size
        fontsize = options.fontsize;
    end
    if isfield(options,'ylimits') ==1
        % adds limits
        ylimits = 1;
        if size(options.ylimits,1) ~= nvar ||  size(options.ylimits,2) ~= 2
            error('you have to specify a nx2 vector with lower and upper bounds')
        end
%         if options.ylimits(1) > options.ylimits(2)
%             b = options.ylimits(:,1);
%             a = options.ylimits(:,2);
%         else
            b = options.ylimits(:,2);
            a = options.ylimits(:,1);
%         end
            
    end

end



nfigs  = ceil(length(varnames)/( nplots(1)*nplots(2)) );
nplots = repmat(nplots,nfigs,1);
for j=1:size(nplots,1),
    nbofplots(j)=nplots(j,1)*nplots(j,2);
end

ntotplots = sum(nbofplots);
if ntotplots<length(varnames),
    nfigplus = ceil((length(pplotvar)-ntotplots)/nbofplots(end));
    lastrow=nplots(end,:);
    lastrow=repmat(lastrow,nfigplus,1);
    nplots = [nplots;lastrow];
    nbofplots = [nbofplots repmat(nbofplots(end),1,nfigplus)];
end

% conf_sig = 0.68;
% sort_idx = round((0.5 + [-conf_sig, conf_sig, 0]/2) * options.K);
%
% sims_shock_down_conf = normz * sims_shock_sort(:, :, :,  sort_idx(1));
% sims_shock_up_conf   = normz * sims_shock_sort(:, :, :,  sort_idx(2));
% sims_shock_median    = normz * sims_shock_sort(:, :, :,  sort_idx(3));

irf_Median  = nan(nvar,hor,nshocks);
irf_low     = nan(nvar,hor,nshocks);
irf_up      = nan(nvar,hor,nshocks);
irf_low_low = nan(nvar,hor,nshocks);
irf_up_up   = nan(nvar,hor,nshocks);

if ndraws > 1
    sort_idx   = round((0.5 + [-conf_sig, conf_sig, 0]/2) * ndraws);
    irf_sort   = sort(irfs,4);
    if normz_yes == 1
        % normalize the IRF relative to a 100 bpt increase in the first
        % variable, first horizon, first shock
        for ns = 1 : nshocks
            normz(ns) = 1 ./ irf_sort(ns, 1, ns,  sort_idx(3) );
        end
        
    end
    if sort_idx(1) == 0 
        sort_idx(1) = 1;
    end    
    for ns = 1 : nshocks
        irf_Median(:,:,ns) = normz(ns) * squeeze(irf_sort(:, :, ns,  sort_idx(3) ));
        irf_low(:,:,ns)    = normz(ns) * squeeze(irf_sort(:, :, ns,  sort_idx(1) ));
        irf_up(:,:,ns)     = normz(ns) * squeeze(irf_sort(:, :, ns,  sort_idx(2) ));
        if  add_multiple_bands_yes == 1
            if sort_idx_2(1) == 0, sort_idx_2(1) = 1; end
            irf_low_low(:,:,ns)  = normz(ns) .* squeeze(irf_sort(:, :, ns,  sort_idx_2(1) ));
            irf_up_up(:,:,ns)    = normz(ns) .* squeeze(irf_sort(:, :, ns,  sort_idx_2(2) ));
        end
    end
else
    for ns = 1 : nshocks
        irf_Median(:,:,ns) = normz(ns) .* irfs(:,:,ns,:);
        irf_low(:,:,ns)    = normz(ns) .* irfs(:,:,ns,:);
        irf_up(:,:,ns)     = normz(ns) .* irfs(:,:,ns,:);
    end
end

jplot = 0;
jfig  = 0;
for sho = 1 : nshocks
    %     figm = figure('Name',['IRFs of ' deblank(varnames{sho})] );
    for var= 1: nvar %size(varnames,2)
        
        if jplot==0,
            figure('name',['IRFs of ' shocksnames{sho}] );
            jfig=jfig+1;
        end
        
        jplot=jplot+1;
        subplot(nplots(jfig,1),nplots(jfig,2),jplot)
        
        if add_multiple_bands_yes == 1
            
            h = area([irf_low_low(var,:,sho)',...
                irf_low(var,:,sho)' - irf_low_low(var,:,sho)',...
                irf_up(var,:,sho)' - irf_low(var,:,sho)',...
                irf_up_up(var,:,sho)' - irf_up(var,:,sho)']);%,'FaceColor',[.85 .85 .85]);
            % set(h(4),'FaceColor',[.95 .95 .95])
            % set(h(3),'FaceColor',[.85 .85 .85])
            % set(h(2),'FaceColor',[.95 .95 .95])
             set(h(1),'FaceColor',[1 1 1])
            set(h(4), 'FaceColor', [1.0 0.6 0.6]); % Lightest red (soft pink)
            set(h(3), 'FaceColor', [1.0 0.4 0.4]); % Light red
            set(h(2), 'FaceColor', [1.0 0.6 0.6]); % Medium red
            %set(h(1), 'FaceColor', [1.0 0.2 0.2]); % Darker red
            set(h,'linestyle','none')
            hold on
            
        else
            h = area([irf_low(var,:,sho)',...
                irf_up(var,:,sho)' - irf_low(var,:,sho)'],'Visible','on');%,'FaceColor',[.85 .85 .85]);
            set(h(2),'FaceColor',[.85 .85 .85])
            set(h(1),'FaceColor',[1 1 1])
            set(h,'linestyle','none')
        end
        %         hold on
        %         plot(irf.cholesky.up(var,:,sho),'b:');
        %         hold on;
        %         plot(irf.cholesky.low(var,:,sho),'b:');
        hold on;
        %plot(irf_Median(var,:,sho),'k');
                plot(irf_Median(var,:,sho),'r');
        hold on;
        if add_irfs_yes == 1
            for hh = 1: size(add_irfs,4)
                plot(add_irfs(var,:,sho,hh),'b','LineWidth',2);
            end
        end
        hold on;
        plot(zeros(1,hor),'k')
        hold on;
        hold on
        axis tight
        if ylimits == 1 && ~isnan(a(var)+b(var))
            ylim([a(var) b(var)]);
        end
        title(varnames{var},'FontSize',fontsize)
        set(gcf,'position' ,[50 50 800 650])
        if jplot==nbofplots(jfig) || var==length(varnames)
            %legend(legenda);
            if savefig_yes == 1
                STR_RECAP = [ fnam_dir '/' fnam_suffix '_' shocksnames{sho} '_' int2str(jfig)];
                saveas(gcf,STR_RECAP,'fig');
                if strcmp(version('-release'),'2022b') == 0
                    saveas(gcf,STR_RECAP,'eps');
                    %savefigure_pdf(STR_RECAP);
                    savefigure_pdf([STR_RECAP '.pdf']);
                end
            end
            jplot=0;
        end
    end
    jfig = 0;
end


if nargout > 0
    irf_.Median  = irf_Median  ;
    irf_.low     = irf_low     ;
    irf_.up      = irf_up      ;
    irf_.low_low = irf_low_low ;
    irf_.up_up   = irf_up_up   ;
end
   
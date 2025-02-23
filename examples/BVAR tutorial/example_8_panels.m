%% BVAR tutorial: Panels of  VARs
% Author:   Filippo Ferroni and  Fabio Canova
% Date:     01/05/2020, revision 20/02/2025

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1) calculation of  average  response averaging  individual  responses
% 2) calculation of  average response  using  pooled  estimator
% 3) calculation  of  average  response  using shrinkage approach (Partial
%    Pooling and  Exchangeable  Prior)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

warning off;  close all; clc; clear;

addpath ../../cmintools/
addpath ../../bvartools/

%% 1) Computing  responses unit  by  unit and  average
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Estimating the transmission of a lending  shock  to  lending rates and
% deposit rates  in a VAR assuming bank by bank, then take average. This
% is  a consistent estimator when T -> oo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% the data  is a  monthly panel of  100  data  points  for  50  banks.
% load data 
load DataBanks
[T,NBanks]   = size(LendingRate);


irfs_to_plot=zeros(2,24,2,NBanks);
lags              =  4;
opt.K             =  1;    % Draws from the posterior not needed
for i  = 1 : NBanks
    % construct the banks i database 
    yi   = [LendingRate(:,i) DepositRate(:,i)];    
    % estimate VAR
    bvar0 = bvar_(yi,lags,opt);
    % store IRFs
    irfs_to_plot(:,:,:,i)  = bvar0.ir_ols;
end

% Customize the IRF plot
% variables names for the plots
options.varnames      = {'Lending Rate','Deposit Rate'};  
% name of the directory where the figure is saved
 options.saveas_dir    = './panels_plt';
% name of the figure to save
 options.saveas_strng  = 'TSAverage';
% name of the shock
options.shocksnames   = options.varnames;
% additional 95% HPD set
options.conf_sig_2    = 0.95;   
% plot appeareance
options.nplots = [2 2];
% add mean response (graphs reports  the  median)
options.add_irfs = mean(irfs_to_plot,4);
% the plotting command
plot_all_irfs_(irfs_to_plot,options);
pause;


%% 2) Pooling 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Estimating the transmission of a lending  shock  to  lending rates and
% deposit rates  in a VAR assuming  homogenous dynamics and  fixed  effects
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOTE: IF THE DATA  HAS DYNAMIC HETEROGENEITY THE  ESTIMATOR COMPUTED HERE
% IS INCONSISTENT

ypooled = zeros(T,2,NBanks);
for i  =  1 : NBanks
    ypooled(:,:,i)  = [demean(LendingRate(:,i)) , demean(DepositRate(:,i))];
end

lags        = 2;
bvar1       = bvar_(ypooled,lags);

% IRF to be plotted
irfs_to_plot           = bvar1.ir_draws;
% name of the figure to save
options.saveas_strng  = 'Pooling';
% the plotting command
plot_all_irfs_(irfs_to_plot,options);
pause;
clear options;

%% 3) Partial pooling
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Estimating the transmission of a lending  shock  to  lending and deposits
% rates assuming  heterogenous dynamics and  fixed  effects
% using  Bayesian partial pooling estimator:
% Bpost=(X'*X + (1./gam)*eye(k,k))\(X'*X*Bet+ (1./gam)*barBet);
% barBet =  prior  mean, SigmaV=gam=*Sigma prior dispersion.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

LendingRateDM = demean(LendingRate);
DepositRateDM = demean(DepositRate);

Nv = 2; % number of variables

% prior  cross  sectional  mean
k       = lags*Nv + 1;
barBet  = zeros(k,Nv);  % pooling  toward  a  prior  mean  of  zero
barBet(1,1)        = 1.0; % pooling  toward  a random  walk
barBet(lags+1,2)   = 1.0;  
gam                = 0.1; % pooling  parameter :  if  large  just  OLS

options.priors.name     = 'Conjugate';
options.priors.Phi.mean = barBet;
options.priors.Phi.cov  = gam * eye(size(barBet,1));
options.conf_sig_2      = 0.9;   
options.K = 1000;
% variables names for the plots
options.varnames      = {'Lending Rate','Deposit Rate'};  
% names of the directory where the figure is saved
 options.saveas_dir    = './panels_plt';
% names of the figure to save
 options.saveas_strng  = 'PartialPooling';
 
 % compute  responses  for  all  banks; plot the  responses of bank=NBanks
for i  = 1: NBanks    
    %i
    yi  = [LendingRateDM(:,i) DepositRateDM(:,i)];    
    bvar2 = bvar_(yi,lags,options);    
    % names of the figure to save
    if  i==NBanks
        options.saveas_strng  = ['PartialPoolingBank#' num2str(i)];  
        plot_all_irfs_(bvar2.ir_draws,options)
    end
end
pause;


%% 4) Exchangable prior
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Use a subset of units to form the prior for the remaining units
% Estimating the transmission of a lending  shock  to  lending and deposits
% rates assuming  heterogenous dynamics and  fixed  effects
% using  Bayesian partial pooling estimator  for  coefficients
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% use the first 20 units to get a prior  for  the  remaining  50
N1           = 20; 
LendingRate_ = reshape(demean(LendingRate(:,1:N1)),T*N1,1);
DepositRate_ = reshape(demean(DepositRate(:,1:N1)),T*N1,1);
yp           = [LendingRate_ , DepositRate_];
bvar3        = bvar_(yp,lags);

options.priors.name     = 'Conjugate';
options.priors.Phi.mean = mean(bvar3.Phi_draws,3);
% Exchangable prior Shrinkage
% if  very  large  just  OLS, if  very  small perfect  pooling.
gam = 0.1;          
options.priors.Phi.cov  = gam * eye(size(options.priors.Phi.mean,1));
options.K = 1000;
i1        = 0;
irfs_to_plot2=zeros(2,24,2,NBanks-N1);

 % compute  responses  for  all  banks; plot the  responses of bank=NBanks
 % WARNING: IT  IS  DOING  50  MCMC HERE
 for i  = N1 + 1:  NBanks    
    i1 = i1 + 1;
   % i
    % construct the banks i database 
    yi  = [LendingRate(:,i) DepositRate(:,i)];
    % estimate bivarite VAR
    bvare = bvar_(yi,lags,options);
    % store IRFs
    irfs_to_plot2(:,:,:,i1)  = bvare.ir_ols;
    if i == NBanks
        options.saveas_strng  = ['exchPartialPoolingBank#' num2str(i)];
        plot_all_irfs_(bvare.ir_draws,options)
    end
end

% plot the cross  sectional  distribution of  responses
% name of the figure to save
options.saveas_strng  = 'exchPartialPooling';
% the plotting command
plot_all_irfs_(irfs_to_plot2,options);


return

%%=========================================================================
%% Extra\ Countries
clear options
% load the data
load DataPooling
% Time:         1978m1 to 2012m8
cnames = {'uk','us','jp','de'};
Nc = length(cnames);
% Varibles:     IPI, CPI, 1Y GOVT YIELD (LTR), Policy Rate (STR)
vnames = {'ipi','cpi','ltr','str'};
Nv = length(vnames);

% Transform the data: take log-differences and demean.
% reshape the data so that 
% [ ipi_uk, cpi_uk, ltr_uk, str_uk;
%   ipi_us, cpi_us, ltr_us, str_us;
%   ipi_jp, cpi_jp, ltr_jp, str_jp;
%   ipi_de, cpi_de, ltr_de, str_de]
T       = size(time,1)-1;
ypooled = nan(T*Nc,Nv);

for v = 1 : Nv % iterate over var
    dta = [];
    for c = 1 : Nc % iterate over countries
        eval(['tmp = ' vnames{v} '_' cnames{v} ';']);
        dta =  [dta ; demean(100*diff(log(tmp)))];
    end
    ypooled(:,v) = dta;
end

lags        = 4 ;
options.hor = 36;
bvar1       = bvar_(ypooled,lags,options);

% Define the IRF of Interest
% index of the shocks of interest (shock to str)
indx_sho              = 4;   
% IRF to PLOT
irfs_to_plot           = bvar1.ir_draws(:,:,indx_sho,:);

% Customize the IRF plot
% variables names for the plots
options.varnames      = vnames;  
% names of the directory where the figure is saved
options.saveas_dir    = './panels_plt';
% names of the figure to save
options.saveas_strng  = 'pooling';
% name of the shock
options.shocksnames   = {'MP'};  
% additional 90% HPD set
options.conf_sig_2    = 0.9;   
% finally, the plotting command
plot_irfs_(irfs_to_plot,options)


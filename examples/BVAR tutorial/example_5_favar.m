%% BVAR tutorial: Classical FAVAR
% Author:   Filippo Ferroni and Fabio Canova
% Date:     27/02/2020, revised  20/02/2025

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1) Estimation of  a  FAVAR
% 2) Impulse  responses calculated for  variables  in the  PC
% 3) Impulse responses calculated with  restrictions  on  the  variables
%    in  the  PC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
close all; clc; clear;

addpath ../../cmintools/
addpath ../../bvartools/

% load favar data (Quarterly)
load DataFAVAR
% y2 are slow moving variables (YoY growth rates)
transf = 2;         % standardize y2
% extract the first 3 Principal Components (PC)
nfac   = 3;         % number of PC
[~,fhat,Lambda,~,STD] = pc_T(y2,nfac,transf);

% y1 interest rate (TBILL3M)
% use compressed slow moving variables first (PC) and TBILL3M,
y = [fhat y1];

% 1. restrictions on the compressed variables, recursive identification 
lags   = 2; 
fabvar = bvar_(y,lags);

% Rescale the IRF from (PC,y1) back to (y2,y1)
% PC are ordered first
order_pc = 1;
C_       = rescaleFAVAR(STD,Lambda,size(y1,2),order_pc);

% construct an IRF for each draw and shock of interest.
% shocks of interest: MP (3 factor + interest rate)
indx_sho     = nfac + 1;       
for k = 1: fabvar.ndraws % iterate on draws
    fabvar.irX_draws(:,:,1,k) =  C_ * fabvar.ir_draws(:,:,indx_sho,k);
end

% Identify the variables of interest for plots (real GDP and CORE PCE)
[~,indx_var] = ismember ({'GDPC96','JCXFE'},varnames_y2);
% Real GDP and CORE PCE and TBILL3M
irfs_to_plot = fabvar.irX_draws( indx_var, :, 1, :);

%  variables names for the plots
options.saveas_dir    = './FAVAR_plt';
options.saveas_strng  = 'FAVAR';
options.shocksnames   = {'MP'};  
options.varnames      = {'GDP','CORE PCE'};  
options.nplots        = [1 2];          % plot appeareance
plot_irfs_(irfs_to_plot,options)
pause;

% sign restrictions on the uncompressed variables. 
% agregate supply: GDP (+) GDP deflator (-). 
% Assume that AD is the first shock
[~,indx_var] = ismember ({'GDPC96','GDPCTPI'},varnames_y2);

signrestriction{1} = ['y(' num2str(indx_var(1)) ',1:3,1)>0;'];
signrestriction{2} = ['y(' num2str(indx_var(2)) ',1:3,1)<0;'];

for k = 1 : fabvar.ndraws % iterate on draws
      Phi       = fabvar.Phi_draws(:,:,k);
      Sigma     = fabvar.Sigma_draws(:,:,k);
      [ir,Omeg] = iresponse_sign(Phi,Sigma,fabvar.hor,signrestriction,C_);
      fabvar.irXsign_draws(:,:,:,k) = ir;
end

[~,indx_var] = ismember ({'GDPC96','GDPCTPI','JCXFE'},varnames_y2);
indx_sho     = 1;       % shocks of interest
irfs_to_plot = fabvar.irXsign_draws(indx_var ,:,indx_sho,:);

options.saveas_dir    = './FAVAR_plt';   % folder
options.saveas_strng  = 'FAVAR_unc';        % names of the figure to save
options.shocksnames   = {'AS'};         % name of the shock
options.varnames      = {'GDP','GDP Defl','CORE PCE'};  
 options.nplots        = [2 2];
plot_irfs_(irfs_to_plot,options)



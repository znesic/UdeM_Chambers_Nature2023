function configIn = UdeM_init_all(dateIn)  
% Parameters, paths and files needed to do UdeM chamber flux calculations
%
% File created:              20200122 (Zoran)
% Last modification:         20200301 (Zoran)
% Very last modification:    20220125 (Carolina): updated slope selection
% (points to skip) for 2021 data, and update chamber volumes for 2021
%

    % Site ID
    configIn.SiteId = 'UdeM';

    Dates    = zeros(1,100); %#ok<*NASGU>

    %-------------------------------
    % Common
    %-------------------------------
    configIn.PC_name       = fr_get_pc_name;
    [configIn.path,configIn.hhour_path,configIn.database_path,configIn.csi_path] = fr_get_local_path;
    configIn.ext           = '.dUdeM';
    configIn.hhour_ext     = '.hUdeM.mat';
    configIn.site          = 'NWT';
    configIn.ch_ctrl       = 'CH_CTRL';                         % name of the chamber control logger
    configIn.localPCname   = fr_get_pc_name;							% check for this name later on to select
    configIn.gmt_to_local  = -5/24;

    %------------------------------------------------
    % All instruments
    %------------------------------------------------
    nLGR = 1;
    nCH_CTRL = 2;
    nCH_AUX_Fast = 3;
    nCH_AUX_Slow = 4;

    %-----------------------
    % Closed path LGR CH4/N2O definitions:
    %-----------------------
    configIn.Instrument(nLGR).varName       = 'LGR';
    configIn.Instrument(nLGR).Type       = 'analyzer';      % case sensitive!
    configIn.Instrument(nLGR).SerNum     = 000;
    configIn.Instrument(nLGR).FileType   = 'LGR2';          %
    configIn.Instrument(nLGR).FileID     = '101';           % String!
    configIn.Instrument(nLGR).assign_in  = 'caller';        % Create variable LGR in hhour structure
    configIn.Instrument(nLGR).flagUBCGII_ASCII = 1;         % load UBC_GII version of LGR files
    configIn.Instrument(nLGR).forceReadASCII = 0;           % this is usually 0 but sometimes we want to
    % re-create MAT version of raw data. Then we use 1.
    %-----------------------
    % CH_CTRL logger definitions:
    %-----------------------
    configIn.Instrument(nCH_CTRL).varName    = 'CH_CTRL';
    configIn.Instrument(nCH_CTRL).fileName   = 'CH_CTRL_CR1000X_UdeM_Main_Raw';
    configIn.Instrument(nCH_CTRL).Type       = 'logger';        % case sensitive!
    configIn.Instrument(nCH_CTRL).SerNum     = 5980;
    configIn.Instrument(nCH_CTRL).FileType   = 'TOA5';          %
    configIn.Instrument(nCH_CTRL).FileID     = '101';           % String!
    configIn.Instrument(nCH_CTRL).assign_in  =  'base';         %
    configIn.Instrument(nCH_CTRL).time_str_flag = 1;            % first column is time vector
    configIn.Instrument(nCH_CTRL).headerlines = 4;              % header is 4 lines
    configIn.Instrument(nCH_CTRL).defaultNaN = 'NaN';           % default NaN

    %-----------------------
    % CTRL_AUX - fast logger definitions:
    %-----------------------
    configIn.Instrument(nCH_AUX_Fast).varName    = 'CH_AUX_10s';
    configIn.Instrument(nCH_AUX_Fast).fileName   = 'AUX_CR1000XSeries_TVC_ACAux_fast';
    configIn.Instrument(nCH_AUX_Fast).Type       = 'logger';        % case sensitive!
    configIn.Instrument(nCH_AUX_Fast).SerNum     = 8323;
    configIn.Instrument(nCH_AUX_Fast).FileType   = 'TOA5';          %
    configIn.Instrument(nCH_AUX_Fast).FileID     = '101';           % String!
    configIn.Instrument(nCH_AUX_Fast).assign_in  =  'base';         %
    configIn.Instrument(nCH_AUX_Fast).time_str_flag = 1;            % first column is time vector
    configIn.Instrument(nCH_AUX_Fast).headerlines = 4;              % header is 4 lines
    configIn.Instrument(nCH_AUX_Fast).defaultNaN = 'NaN';           % default NaN

    %-----------------------
    % CTRL_AUX - slow logger definitions:
    %-----------------------
    configIn.Instrument(nCH_AUX_Slow).varName    = 'CH_AUX_30min';
    configIn.Instrument(nCH_AUX_Slow).fileName   = 'AUX_CR1000XSeries_TVC_ACAux_slow';
    configIn.Instrument(nCH_AUX_Slow).Type       = 'logger';        % case sensitive!
    configIn.Instrument(nCH_AUX_Slow).SerNum     = 8323;
    configIn.Instrument(nCH_AUX_Slow).FileType   = 'TOA5';          %
    configIn.Instrument(nCH_AUX_Slow).FileID     = '101';           % String!
    configIn.Instrument(nCH_AUX_Slow).assign_in  =  'base';         %
    configIn.Instrument(nCH_AUX_Slow).time_str_flag = 1;            % first column is time vector
    configIn.Instrument(nCH_AUX_Slow).headerlines = 4;              % header is 4 lines
    configIn.Instrument(nCH_AUX_Slow).defaultNaN = 'NaN';           % default NaN

    % The number of chambers in the experiment
    configIn.chNbr = 18; %
    
    % Chamber run time
    configIn.sampleTime = 3600 / configIn.chNbr;                    % seconds per chamber

    %-------------------------------------------------------------
    % Define chamber area and volume
    %-------------------------------------------------------------
    configIn = get_chamber_size(configIn,dateIn);
    
    %-------------------------------------------------------------
    % Define flux processing parameters:
    % - Chamber volume
    % - skipPoints     (points to
    % - deadBand
    % - pointsToTest   (... for t0 search)
    % - timePeriodToFit
    %-------------------------------------------------------------
    configIn = get_fit_parameters(configIn,dateIn);


    %---------------------------------------------------------------
    % Define which climate data traces are related to which chamber
    %---------------------------------------------------------------
    configIn = get_traces(configIn,dateIn);

end

%===============================================================
% get_fit_parameters  - setup exponential fit parameters
%                       Note: these settings are date dependant
%===============================================================

function configIn = set_exp_fit_parameters(configIn,chNum,gasType,skipPoints,deadBand,pointsToTest,pointsToFit)
    arg_default('pointsToFit',9999)
    configIn.chamber(chNum).(gasType).fit_exp.skipPoints = skipPoints;
    configIn.chamber(chNum).(gasType).fit_exp.deadBand = deadBand;
    configIn.chamber(chNum).(gasType).fit_exp.pointsToTest = pointsToTest;
    maxPointsAvailableToFit = configIn.sampleTime ...
                    - configIn.chamber(chNum).(gasType).fit_exp.skipPoints ...
                    - configIn.chamber(chNum).(gasType).fit_exp.deadBand ...
                    - configIn.chamber(chNum).(gasType).fit_exp.pointsToTest;
    if pointsToFit == 9999
        % by default use all the points available for the fits
        configIn.chamber(chNum).(gasType).fit_exp.timePeriodToFit =  maxPointsAvailableToFit;
    else
        % otherwise use the minimum between the requested pointsToFit and maxPointsAvailableToFit
        configIn.chamber(chNum).(gasType).fit_exp.timePeriodToFit =  min(maxPointsAvailableToFit,pointsToFit);
    end
                    
end

%===============================================================
% get_fit_parameters  - setup exponential fit parameters
%                       Note: these settings are date dependant
%===============================================================

function configIn = set_lin_fit_parameters(configIn,chNum,gasType,skipPoints,deadBand,pointsToTest,pointsToFit)
    arg_default('pointsToFit',9999)
    configIn.chamber(chNum).(gasType).fit_lin.skipPoints = skipPoints;
    configIn.chamber(chNum).(gasType).fit_lin.deadBand = deadBand;
    configIn.chamber(chNum).(gasType).fit_lin.pointsToTest = pointsToTest;
    maxPointsAvailableToFit = configIn.sampleTime ...
                    - configIn.chamber(chNum).(gasType).fit_lin.skipPoints ...
                    - configIn.chamber(chNum).(gasType).fit_lin.deadBand ...
                    - configIn.chamber(chNum).(gasType).fit_lin.pointsToTest;
    if pointsToFit == 9999
        % by default use all the points available for the fits
        configIn.chamber(chNum).(gasType).fit_lin.timePeriodToFit =  maxPointsAvailableToFit;
    else
        % otherwise use the minimum between the requested pointsToFit and maxPointsAvailableToFit
        configIn.chamber(chNum).(gasType).fit_lin.timePeriodToFit =  min(maxPointsAvailableToFit,pointsToFit);
    end
                    
end

%===============================================================
% get_fit_parameters  - setup quadratic fit parameters
%                       Note: these settings are date dependant
%===============================================================

function configIn = set_quad_fit_parameters(configIn,chNum,gasType,skipPoints,deadBand,pointsToTest,pointsToFit)
    arg_default('pointsToFit',9999)
    configIn.chamber(chNum).(gasType).fit_quad.skipPoints = skipPoints;
    configIn.chamber(chNum).(gasType).fit_quad.deadBand = deadBand;
    configIn.chamber(chNum).(gasType).fit_quad.pointsToTest = pointsToTest;
    maxPointsAvailableToFit = configIn.sampleTime ...
                    - configIn.chamber(chNum).(gasType).fit_quad.skipPoints ...
                    - configIn.chamber(chNum).(gasType).fit_quad.deadBand ...
                    - configIn.chamber(chNum).(gasType).fit_quad.pointsToTest;
    if pointsToFit == 9999
        % by default use all the points available for the fits
        configIn.chamber(chNum).(gasType).fit_quad.timePeriodToFit =  maxPointsAvailableToFit;
    else
        % otherwise use the minimum between the requested pointsToFit and maxPointsAvailableToFit
        configIn.chamber(chNum).(gasType).fit_quad.timePeriodToFit =  min(maxPointsAvailableToFit,pointsToFit);
    end
                    
end

function configIn = get_fit_parameters(configIn,dateIn) %#ok<*INUSD>
    defaultPointsToExpFitCO2  = [];
    defaultPointsToLinFitCO2  = 60;
    defaultPointsToQuadFitCO2 = 60;
    defaultPointsToExpFitCH4  = [];
    defaultPointsToLinFitCH4  = [];
    defaultPointsToQuadFitCH4 = [];
    chNum = 1;
        a = 35; b = 40; c = 20;
        % input parameters               (configIn,chNum,gasType,skipPoints,deadBand,pointsToTest,pointsToFit)
        configIn = set_exp_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToExpFitCO2);
        configIn = set_exp_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToExpFitCH4);
        configIn = set_lin_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToLinFitCO2);    
        configIn = set_lin_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToLinFitCH4);
        configIn = set_quad_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,4*c           ,defaultPointsToQuadFitCO2);    
        configIn = set_quad_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,4*c           ,defaultPointsToQuadFitCH4);
    chNum = 2;
        a = 35; b = 40; c = 20;
        % input parameters               (configIn,chNum,gasType,skipPoints,deadBand,pointsToTest,pointsToFit)
        configIn = set_exp_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToExpFitCO2);
        configIn = set_lin_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToLinFitCO2);
        configIn = set_exp_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToExpFitCH4);
        configIn = set_lin_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToLinFitCH4);
        configIn = set_quad_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToQuadFitCO2);    
        configIn = set_quad_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToQuadFitCH4);        
    chNum = 3;
        a = 40; b = 40; c = 20;
        % input parameters               (configIn,chNum,gasType,skipPoints,deadBand,pointsToTest,pointsToFit)
        configIn = set_exp_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToExpFitCO2);
        configIn = set_lin_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToLinFitCO2);
        configIn = set_exp_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToExpFitCH4);
        configIn = set_lin_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToLinFitCH4);
        configIn = set_quad_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToQuadFitCO2);    
        configIn = set_quad_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToQuadFitCH4);
     chNum = 4;
        a = 40; b = 40; c = 20;
        % input parameters               (configIn,chNum,gasType,skipPoints,deadBand,pointsToTest,pointsToFit)
        configIn = set_exp_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToExpFitCO2);
        configIn = set_lin_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToLinFitCO2);
        configIn = set_exp_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToExpFitCH4);
        configIn = set_lin_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToLinFitCH4);
        configIn = set_quad_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToQuadFitCO2);    
        configIn = set_quad_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToQuadFitCH4);
    chNum = 5;
        a = 40; b = 40; c = 20;
        % input parameters               (configIn,chNum,gasType,skipPoints,deadBand,pointsToTest,pointsToFit)
        configIn = set_exp_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToExpFitCO2);
        configIn = set_lin_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToLinFitCO2);
        configIn = set_exp_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToExpFitCH4);
        configIn = set_lin_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToLinFitCH4);
        configIn = set_quad_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToQuadFitCO2);    
        configIn = set_quad_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToQuadFitCH4);
    chNum = 6;
        a = 40; b = 40; c = 20;
        % input parameters               (configIn,chNum,gasType,skipPoints,deadBand,pointsToTest,pointsToFit)
        configIn = set_exp_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToExpFitCO2);
        configIn = set_lin_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToLinFitCO2);
        configIn = set_exp_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToExpFitCH4);
        configIn = set_lin_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToLinFitCH4);
        configIn = set_quad_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToQuadFitCO2);    
        configIn = set_quad_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToQuadFitCH4);
    chNum = 7;
		if dateIn < datenum(2021,1,1)
			a = 35; b = 40; c = 20;   % settings for 2019
		else
			a = 40; b = 40; c = 20;   % settings for 2021
		end
		
        % input parameters               (configIn,chNum,gasType,skipPoints,deadBand,pointsToTest,pointsToFit)
        configIn = set_exp_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToExpFitCO2);
        configIn = set_lin_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToLinFitCO2);
        configIn = set_exp_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToExpFitCH4);
        configIn = set_lin_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToLinFitCH4);
        configIn = set_quad_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToQuadFitCO2);    
        configIn = set_quad_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToQuadFitCH4);
    chNum = 8;
        a = 40; b = 40; c = 20;
        % input parameters               (configIn,chNum,gasType,skipPoints,deadBand,pointsToTest,pointsToFit)
        configIn = set_exp_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToExpFitCO2);
        configIn = set_lin_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToLinFitCO2);
        configIn = set_exp_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToExpFitCH4);
        configIn = set_lin_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToLinFitCH4);
        configIn = set_quad_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToQuadFitCO2);    
        configIn = set_quad_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToQuadFitCH4);
    chNum = 9;
        a = 40; b = 40; c = 20;
        % input parameters               (configIn,chNum,gasType,skipPoints,deadBand,pointsToTest,pointsToFit)
        configIn = set_exp_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToExpFitCO2);
        configIn = set_lin_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToLinFitCO2);
        configIn = set_exp_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToExpFitCH4);
        configIn = set_lin_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToLinFitCH4);
        configIn = set_quad_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToQuadFitCO2);    
        configIn = set_quad_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToQuadFitCH4);
    chNum = 10;
		if dateIn < datenum(2021,1,1)
			a = 45; b = 40; c = 20;   % settings for 2019
		else
			a = 55; b = 40; c = 20;   % settings for 2021
		end 
        % input parameters               (configIn,chNum,gasType,skipPoints,deadBand,pointsToTest,pointsToFit)
        configIn = set_exp_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToExpFitCO2);
        configIn = set_lin_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToLinFitCO2);
        configIn = set_exp_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToExpFitCH4);
        configIn = set_lin_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToLinFitCH4);
        configIn = set_quad_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,4*c           ,defaultPointsToQuadFitCO2);    
        configIn = set_quad_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,4*c           ,defaultPointsToQuadFitCH4);
    chNum = 11;
        a = 35; b = 40; c = 20;
        % input parameters               (configIn,chNum,gasType,skipPoints,deadBand,pointsToTest,pointsToFit)
        configIn = set_exp_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToExpFitCO2);
        configIn = set_lin_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToLinFitCO2);
        configIn = set_exp_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToExpFitCH4);
        configIn = set_lin_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToLinFitCH4);
        configIn = set_quad_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToQuadFitCO2);    
        configIn = set_quad_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToQuadFitCH4);
    chNum = 12;
        a = 35; b = 40; c = 20;
        % input parameters               (configIn,chNum,gasType,skipPoints,deadBand,pointsToTest,pointsToFit)
        configIn = set_exp_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToExpFitCO2);
        configIn = set_lin_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToLinFitCO2);
        configIn = set_exp_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToExpFitCH4);
        configIn = set_lin_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToLinFitCH4);
        configIn = set_quad_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToQuadFitCO2);    
        configIn = set_quad_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToQuadFitCH4);
    chNum = 13;
        a = 35; b = 40; c = 20;
        % input parameters               (configIn,chNum,gasType,skipPoints,deadBand,pointsToTest,pointsToFit)
        configIn = set_exp_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToExpFitCO2);
        configIn = set_lin_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToLinFitCO2);
        configIn = set_exp_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToExpFitCH4);
        configIn = set_lin_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToLinFitCH4);
        configIn = set_quad_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToQuadFitCO2);    
        configIn = set_quad_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToQuadFitCH4);
    chNum = 14;
        a = 35; b = 40; c = 20;
        % input parameters               (configIn,chNum,gasType,skipPoints,deadBand,pointsToTest,pointsToFit)
        configIn = set_exp_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToExpFitCO2);
        configIn = set_lin_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToLinFitCO2);
        configIn = set_exp_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToExpFitCH4);
        configIn = set_lin_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToLinFitCH4);
        configIn = set_quad_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToQuadFitCO2);    
        configIn = set_quad_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToQuadFitCH4);
    chNum = 15;
		if dateIn < datenum(2021,1,1)
			a = 45; b = 40; c = 20;   % settings for 2019
		else
			a = 55; b = 40; c = 20;   % settings for 2021
		end
        % input parameters               (configIn,chNum,gasType,skipPoints,deadBand,pointsToTest,pointsToFit)
        configIn = set_exp_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToExpFitCO2);
        configIn = set_lin_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToLinFitCO2);
        configIn = set_exp_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToExpFitCH4);
        configIn = set_lin_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToLinFitCH4);
        configIn = set_quad_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToQuadFitCO2);    
        configIn = set_quad_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToQuadFitCH4);
    chNum = 16;
		if dateIn < datenum(2021,1,1)
			a = 40; b = 40; c = 20;   % settings for 2019
		else
			a = 35; b = 40; c = 20;   % settings for 2021
		end	
        
        % input parameters               (configIn,chNum,gasType,skipPoints,deadBand,pointsToTest,pointsToFit)
        configIn = set_exp_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToExpFitCO2);
        configIn = set_lin_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToLinFitCO2);
        configIn = set_exp_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToExpFitCH4);
        configIn = set_lin_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToLinFitCH4);
        configIn = set_quad_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToQuadFitCO2);    
        configIn = set_quad_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToQuadFitCH4);
    chNum = 17;
        a = 40; b = 40; c = 20;
        % input parameters               (configIn,chNum,gasType,skipPoints,deadBand,pointsToTest,pointsToFit)
        configIn = set_exp_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToExpFitCO2);
        configIn = set_lin_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToLinFitCO2);
        configIn = set_exp_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToExpFitCH4);
        configIn = set_lin_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToLinFitCH4);
        configIn = set_quad_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToQuadFitCO2);    
        configIn = set_quad_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToQuadFitCH4);
    chNum = 18;
        a = 35; b = 40; c = 20;
        % input parameters               (configIn,chNum,gasType,skipPoints,deadBand,pointsToTest,pointsToFit)
        configIn = set_exp_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToExpFitCO2);
        configIn = set_lin_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToLinFitCO2);
        configIn = set_exp_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToExpFitCH4);
        configIn = set_lin_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToLinFitCH4);                                               
        configIn = set_quad_fit_parameters(configIn,chNum,'co2'  ,a         ,b       ,c           ,defaultPointsToQuadFitCO2);    
        configIn = set_quad_fit_parameters(configIn,chNum,'ch4'  ,a         ,b       ,c           ,defaultPointsToQuadFitCH4);
end


%=======================================================
% get_traces
%=======================================================
function configIn = get_traces(configIn,dateIn)
    %**********************************************************
    % There is no Pbar recorded here.  Use a constant.
    % (in the future - consider how to automatically get it
    % from the EC system)
    % 
    %**********************************************************
    configIn.Pbar_default = 101300;          % Pa
    
    % If Tair is missing for a chamber, a default of 20 deg C will be used instead
    configIn.Tair_default = 20 + 273.15;     % Tair default

    % first define the common traces for all chambers:
    % {'matlab trace name',  'analyzer/logger', 'inst. name', 'original trace name'}
    for i=1:configIn.chNbr
        configIn.chamber(i).traces = { ...
            'h2o_ppm',          'analyzer', 'LGR' ,    'H2O_ppm';...
            'co2_dry',          'analyzer', 'LGR' ,    'CO2d_ppm';...
            'ch4_dry',          'analyzer', 'LGR' ,    'CH4d_ppm';...
            'h2o_ppm',          'analyzer', 'LGR' ,    'H2O_ppm';...
            'pressureInlet',    'logger'    'CH_CTRL',   'P_inlet_Avg';...
            'pressureOutlet',   'logger',   'CH_CTRL',   'P_return_Avg';...
            'airTemperature',   'logger',   'CH_AUX_10s', sprintf('CHMBR_AirTemp_Avg%d',i);...
            };
    end

    % then define each chamber's individual traces
    configIn.chamber(1).traces = [configIn.chamber(1).traces;
        {
        'PAR_in',                [],         [],              [];...
        'soilTemperature_in',   'logger',   'CH_AUX_30min',  'CHMBR1_SoilTemp_Avg';...
        'soilVWC_in',           'logger',   'CH_AUX_30min',  'CHMBR1_VWC_Avg';...
        'EC_in',                   'logger',   'CH_AUX_30min',  'CHMBR1_EC_Avg';...
        'permittivity_in',      'logger'    'CH_AUX_30min',  'CHMBR1_Permittivity_Avg';...
        }
        ];

    configIn.chamber(2).traces = [configIn.chamber(2).traces;
        {
        'PAR_in',                'logger',   'CH_AUX_10s',   'CHMBR2_PAR_Avg';...
        'soilTemperature_in',   [],          [],            [];...
        'soilVWC_in',           [],          [],            [];...
        'EC_in',                   [],          [],            [];...
        'permittivity_in',      [],          [],            [];...
        }
        ];

    configIn.chamber(3).traces = [configIn.chamber(3).traces;
        {
        'PAR_in',                [],         [],              [];...
        'soilTemperature_in',   'logger',   'CH_AUX_30min',  'CHMBR3_SoilTemp_Avg';...
        'soilVWC_in',           'logger',   'CH_AUX_30min',  'CHMBR3_VWC_Avg';...
        'EC_in',                   'logger',   'CH_AUX_30min',  'CHMBR3_EC_Avg';...
        'permittivity_in',      'logger'    'CH_AUX_30min',  'CHMBR3_Permittivity_Avg';...
        }
        ];
    configIn.chamber(4).traces = [configIn.chamber(4).traces;
        {
        'PAR_in',                [],         [],              [];...
        'soilTemperature_in',   'logger',   'CH_AUX_30min',  'CHMBR4_SoilTemp_Avg';...
        'soilVWC_in',           'logger',   'CH_AUX_30min',  'CHMBR4_VWC_Avg';...
        'EC_in',                   'logger',   'CH_AUX_30min',  'CHMBR4_EC_Avg';...
        'permittivity_in',      'logger'    'CH_AUX_30min',  'CHMBR4_Permittivity_Avg';...
        }
        ];

    configIn.chamber(5).traces = [configIn.chamber(5).traces;
        {
        'PAR_in',                'logger',   'CH_AUX_10s',   'CHMBR7_PAR_Avg';...
        'soilTemperature_in',   [],          [],            [];...
        'soilVWC_in',           [],          [],            [];...
        'EC_in',                   [],          [],            [];...
        'permittivity_in',      [],          [],            [];...
        }
        ];
    configIn.chamber(6).traces = [configIn.chamber(6).traces;
        {
        'PAR_in',                [],         [],              [];...
        'soilTemperature_in',   'logger',   'CH_AUX_30min',  'CHMBR6_SoilTemp_Avg';...
        'soilVWC_in',           'logger',   'CH_AUX_30min',  'CHMBR6_VWC_Avg';...
        'EC_in',                   'logger',   'CH_AUX_30min',  'CHMBR6_EC_Avg';...
        'permittivity_in',      'logger'    'CH_AUX_30min',  'CHMBR6_Permittivity_Avg';...
        }
        ];
    configIn.chamber(7).traces = [configIn.chamber(7).traces;
        {
        'PAR_in',                'logger',   'CH_AUX_10s',   'CHMBR7_PAR_Avg';...
        'soilTemperature_in',   [],          [],            [];...
        'soilVWC_in',           [],          [],            [];...
        'EC_in',                   [],          [],            [];...
        'permittivity_in',      [],          [],            [];...
        }
        ];
    configIn.chamber(8).traces = [configIn.chamber(8).traces;
        {
        'PAR_in',                [],         [],              [];...
        'soilTemperature_in',   'logger',   'CH_AUX_30min',  'CHMBR8_SoilTemp_Avg';...
        'soilVWC_in',           'logger',   'CH_AUX_30min',  'CHMBR8_VWC_Avg';...
        'EC_in',                   'logger',   'CH_AUX_30min',  'CHMBR8_EC_Avg';...
        'permittivity_in',      'logger'    'CH_AUX_30min',  'CHMBR8_Permittivity_Avg';...
        }
        ];
    configIn.chamber(9).traces = [configIn.chamber(9).traces;
        {
        'PAR_in',                'logger',   'CH_AUX_10s',   'CHMBR9_PAR_Avg';...
        'soilTemperature_in',   [],          [],            [];...
        'soilVWC_in',           [],          [],            [];...
        'EC_in',                   [],          [],            [];...
        'permittivity_in',      [],          [],            [];...
        }
        ];
    configIn.chamber(10).traces = [configIn.chamber(10).traces;
        {
        'PAR_in',                [],         [],              [];...
        'soilTemperature_in',   'logger',   'CH_AUX_30min',  'CHMBR10_SoilTemp_Avg';...
        'soilVWC_in',           'logger',   'CH_AUX_30min',  'CHMBR10_VWC_Avg';...
        'EC_in',                   'logger',   'CH_AUX_30min',  'CHMBR10_EC_Avg';...
        'permittivity_in',      'logger'    'CH_AUX_30min',  'CHMBR10_Permittivity_Avg';...
        }
        ];
    configIn.chamber(11).traces = [configIn.chamber(11).traces;
        {
        'PAR_in',                'logger',   'CH_AUX_10s',   'CHMBR11_PAR_Avg';...
        'soilTemperature_in',   [],          [],            [];...
        'soilVWC_in',           [],          [],            [];...
        'EC_in',                   [],          [],            [];...
        'permittivity_in',      [],          [],            [];...
        }
        ];
    configIn.chamber(12).traces = [configIn.chamber(12).traces;
        {
        'PAR_in',                [],         [],              [];...
        'soilTemperature_in',   'logger',   'CH_AUX_30min',  'CHMBR12_SoilTemp_Avg';...
        'soilVWC_in',           'logger',   'CH_AUX_30min',  'CHMBR12_VWC_Avg';...
        'EC_in',                   'logger',   'CH_AUX_30min',  'CHMBR12_EC_Avg';...
        'permittivity_in',      'logger'    'CH_AUX_30min',  'CHMBR12_Permittivity_Avg';...
        }
        ];
    configIn.chamber(13).traces = [configIn.chamber(13).traces;
        {
        'PAR_in',                'logger',   'CH_AUX_10s',   'CHMBR13_PAR_Avg';...
        'soilTemperature_in',   [],          [],            [];...
        'soilVWC_in',           [],          [],            [];...
        'EC_in',                   [],          [],            [];...
        'permittivity_in',      [],          [],            [];...
        }
        ];
    configIn.chamber(14).traces = [configIn.chamber(14).traces;
        {
        'PAR_in',                'logger',   'CH_AUX_10s',   'CHMBR14_PAR_Avg';...
        'soilTemperature_in',   [],          [],            [];...
        'soilVWC_in',           [],          [],            [];...
        'EC_in',                   [],          [],            [];...
        'permittivity_in',      [],          [],            [];...
        }
        ];
    configIn.chamber(15).traces = [configIn.chamber(15).traces;
        {
        'PAR_in',                [],         [],              [];...
        'soilTemperature_in',   'logger',   'CH_AUX_30min',  'CHMBR15_SoilTemp_Avg';...
        'soilVWC_in',           'logger',   'CH_AUX_30min',  'CHMBR15_VWC_Avg';...
        'EC_in',                'logger',   'CH_AUX_30min',  'CHMBR15_EC_Avg';...
        'permittivity_in',      'logger'    'CH_AUX_30min',  'CHMBR15_Permittivity_Avg';...
        }
        ];
    configIn.chamber(16).traces = [configIn.chamber(16).traces;
        {
        'PAR_in',                'logger',   'CH_AUX_10s',   'CHMBR16_PAR_Avg';...
        'soilTemperature_in',   [],          [],            [];...
        'soilVWC_in',           [],          [],            [];...
        'EC_in',                [],          [],            [];...
        'permittivity_in',      [],          [],            [];...
        }
        ];
    configIn.chamber(17).traces = [configIn.chamber(17).traces;
        {
        'PAR_in',                [],         [],              [];...
        'soilTemperature_in',   'logger',   'CH_AUX_30min',  'CHMBR17_SoilTemp_Avg';...
        'soilVWC_in',           'logger',   'CH_AUX_30min',  'CHMBR17_VWC_Avg';...
        'EC_in',                'logger',   'CH_AUX_30min',  'CHMBR17_EC_Avg';...
        'permittivity_in',      'logger'    'CH_AUX_30min',  'CHMBR17_Permittivity_Avg';...
        }
        ];
    configIn.chamber(18).traces = [configIn.chamber(18).traces;
        {
        'PAR_in',                'logger',   'CH_AUX_10s',   'CHMBR18_PAR_Avg';...
        'soilTemperature_in',   [],          [],            [];...
        'soilVWC_in',           [],          [],            [];...
        'EC_in',                [],          [],            [];...
        'permittivity_in',      [],          [],            [];...
        }
    ];
end

%====================================================================
% get_chamber_size  - set and/or calculate chamber area and volume
%                       Note: these settings are date dependant
%====================================================================
function configIn = calc_chamber_volume(configIn,chNum,chamberRadius,ChamberHeight,domeVolume,chamberSlope)
    arg_default('chamberSlope',0);                                  % chamber slope in degrees (default)
    chArea   = chamberRadius^2 * pi * cos(chamberSlope/180*pi);     % m^2 (corrected for slope)
    
    configIn.chamber(chNum).chArea = chArea;            % (m^2) chamber area
    CylinderVolume     =ChamberHeight * chArea;         % (m^3) for cylinder part of the chamber
    configIn.chamber(chNum).chVolume = ...
                        CylinderVolume + domeVolume;    % (m^3) Total volume for the chamber

end

function configIn = get_chamber_size(configIn,dateIn)
    % Default chamber diameter
    chamberRadius = (22.05-2*0.632)*0.0254/2;   % m (calculated based on the specified pipe dimensions)
    chamberSlope    = 0;                        % degrees of chamber tilt (default 0 deg)
    domeVolume = 0.030;                         %(m3) chamber dome average of two measurements (29.4 and 30.6L). Last done Mar 2, 2020 (by Zoran)
    
    if dateIn < datenum(2021,1,1)	
		chNum = 1;
			chamberHeight = 0.0595;                 % updated by Carolina for 2021 measurements
			configIn = calc_chamber_volume(configIn,chNum,chamberRadius,chamberHeight,domeVolume,chamberSlope);
		chNum = 2;
			chamberHeight = 0.0650;                 % updated by Carolina for 2021 measurements
			configIn = calc_chamber_volume(configIn,chNum,chamberRadius,chamberHeight,domeVolume,chamberSlope);
		chNum = 3;
			chamberHeight = 0.0270;                 % updated by Carolina for 2021 measurements
			configIn = calc_chamber_volume(configIn,chNum,chamberRadius,chamberHeight,domeVolume,chamberSlope);
		chNum = 4;
			chamberHeight = 0.0630;                 % updated by Carolina for 2021 measurements
			configIn = calc_chamber_volume(configIn,chNum,chamberRadius,chamberHeight,domeVolume,chamberSlope);
		chNum = 5;
			chamberHeight = 0.0320;                 % updated by Carolina for 2021 measurements
			configIn = calc_chamber_volume(configIn,chNum,chamberRadius,chamberHeight,domeVolume,chamberSlope);
		chNum = 6;
			chamberHeight = 0.0290;                 % updated by Carolina for 2021 measurements
			configIn = calc_chamber_volume(configIn,chNum,chamberRadius,chamberHeight,domeVolume,chamberSlope);
		chNum = 7;
			chamberHeight = 0.0505;                 % updated by Carolina for 2021 measurements
			configIn = calc_chamber_volume(configIn,chNum,chamberRadius,chamberHeight,domeVolume,chamberSlope);
		chNum = 8;
			chamberHeight = 0.0460;                 % updated by Carolina for 2021 measurements
			configIn = calc_chamber_volume(configIn,chNum,chamberRadius,chamberHeight,domeVolume,chamberSlope);
		chNum = 9;
			chamberHeight = 0.0275;                 % updated by Carolina for 2021 measurements
			configIn = calc_chamber_volume(configIn,chNum,chamberRadius,chamberHeight,domeVolume,chamberSlope);
		chNum = 10;
			chamberHeight = 0.0065;                 % updated by Carolina for 2021 measurements
			configIn = calc_chamber_volume(configIn,chNum,chamberRadius,chamberHeight,domeVolume,chamberSlope);
		chNum = 11;
			chamberHeight = 0.0265;                 % updated by Carolina for 2021 measurements
			configIn = calc_chamber_volume(configIn,chNum,chamberRadius,chamberHeight,domeVolume,chamberSlope);
		chNum = 12;
			chamberHeight = 0.0460;                 % updated by Carolina for 2021 measurements
			configIn = calc_chamber_volume(configIn,chNum,chamberRadius,chamberHeight,domeVolume,chamberSlope);
		chNum = 13;
			chamberHeight = 0.0160;                 % updated by Carolina for 2021 measurements
			configIn = calc_chamber_volume(configIn,chNum,chamberRadius,chamberHeight,domeVolume,chamberSlope);
		chNum = 14;
			chamberHeight = 0.0635;                 % updated by Carolina for 2021 measurements
			configIn = calc_chamber_volume(configIn,chNum,chamberRadius,chamberHeight,domeVolume,chamberSlope);
		chNum = 15;
			chamberHeight = 0.0200;                 % updated by Carolina for 2021 measurements
			configIn = calc_chamber_volume(configIn,chNum,chamberRadius,chamberHeight,domeVolume,chamberSlope);
		chNum = 16;
			chamberHeight = 0.0260;                 % updated by Carolina for 2021 measurements
			configIn = calc_chamber_volume(configIn,chNum,chamberRadius,chamberHeight,domeVolume,chamberSlope);
		chNum = 17;
			chamberHeight = 0.0340;                 % updated by Carolina for 2021 measurements
			configIn = calc_chamber_volume(configIn,chNum,chamberRadius,chamberHeight,domeVolume,chamberSlope);
		chNum = 18;
			chamberHeight = 0.0055;                 % updated by Carolina for 2021 measurements
			configIn = calc_chamber_volume(configIn,chNum,chamberRadius,chamberHeight,domeVolume,chamberSlope);
	else
	        
		chNum = 1;
			chamberHeight = 0.0615;                 % from Carolina's email 20200220 for year 2019
			configIn = calc_chamber_volume(configIn,chNum,chamberRadius,chamberHeight,domeVolume,chamberSlope);
		chNum = 2;
			chamberHeight = 0.0670;                 % from Carolina's email 20200220 for year 2019
			configIn = calc_chamber_volume(configIn,chNum,chamberRadius,chamberHeight,domeVolume,chamberSlope);
		chNum = 3;
			chamberHeight = 0.0355;                 % from Carolina's email 20200220 for year 2019
			configIn = calc_chamber_volume(configIn,chNum,chamberRadius,chamberHeight,domeVolume,chamberSlope);
		chNum = 4;
			chamberHeight = 0.0450;                 % from Carolina's email 20200220 for year 2019
			configIn = calc_chamber_volume(configIn,chNum,chamberRadius,chamberHeight,domeVolume,chamberSlope);
		chNum = 5;
			chamberHeight = 0.0435;                 % from Carolina's email 20200220 for year 2019
			configIn = calc_chamber_volume(configIn,chNum,chamberRadius,chamberHeight,domeVolume,chamberSlope);
		chNum = 6;
			chamberHeight = 0.0320;                 % from Carolina's email 20200220 for year 2019
			configIn = calc_chamber_volume(configIn,chNum,chamberRadius,chamberHeight,domeVolume,chamberSlope);
		chNum = 7;
			chamberHeight = 0.0455;                 % from Carolina's email 20200220 for year 2019
			configIn = calc_chamber_volume(configIn,chNum,chamberRadius,chamberHeight,domeVolume,chamberSlope);
		chNum = 8;
			chamberHeight = 0.0515;                 % from Carolina's email 20200220 for year 2019
			configIn = calc_chamber_volume(configIn,chNum,chamberRadius,chamberHeight,domeVolume,chamberSlope);
		chNum = 9;
			chamberHeight = 0.0460;                 % from Carolina's email 20200220 for year 2019
			configIn = calc_chamber_volume(configIn,chNum,chamberRadius,chamberHeight,domeVolume,chamberSlope);
		chNum = 10;
			chamberHeight = 0.0195;                 % from Carolina's email 20200220 for year 2019
			configIn = calc_chamber_volume(configIn,chNum,chamberRadius,chamberHeight,domeVolume,chamberSlope);
		chNum = 11;
			chamberHeight = 0.0285;                 % from Carolina's email 20200220 for year 2019
			configIn = calc_chamber_volume(configIn,chNum,chamberRadius,chamberHeight,domeVolume,chamberSlope);
		chNum = 12;
			chamberHeight = 0.0505;                 % from Carolina's email 20200220 for year 2019
			configIn = calc_chamber_volume(configIn,chNum,chamberRadius,chamberHeight,domeVolume,chamberSlope);
		chNum = 13;
			chamberHeight = 0.0230;                 % from Carolina's email 20200220 for year 2019
			configIn = calc_chamber_volume(configIn,chNum,chamberRadius,chamberHeight,domeVolume,chamberSlope);
		chNum = 14;
			chamberHeight = 0.0480;                 % from Carolina's email 20200220 for year 2019
			configIn = calc_chamber_volume(configIn,chNum,chamberRadius,chamberHeight,domeVolume,chamberSlope);
		chNum = 15;
			chamberHeight = 0.0200;                 % from Carolina's email 20200220 for year 2019
			configIn = calc_chamber_volume(configIn,chNum,chamberRadius,chamberHeight,domeVolume,chamberSlope);
		chNum = 16;
			chamberHeight = 0.0380;                 % from Carolina's email 20200220 for year 2019
			configIn = calc_chamber_volume(configIn,chNum,chamberRadius,chamberHeight,domeVolume,chamberSlope);
		chNum = 17;
			chamberHeight = 0.0415;                 % from Carolina's email 20200220 for year 2019
			configIn = calc_chamber_volume(configIn,chNum,chamberRadius,chamberHeight,domeVolume,chamberSlope);
		chNum = 18;
			chamberHeight = -0.001;                 % from Carolina's email 20200220 for year 2019
			configIn = calc_chamber_volume(configIn,chNum,chamberRadius,chamberHeight,domeVolume,chamberSlope);
	 end  
end



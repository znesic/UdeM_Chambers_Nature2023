function dataStruct = UdeM_ACS_calc_slopes_and_fluxes(dataStruct,plotFlag,fullCalcFlag,chambersToCalc,slopesToCalc)
%
%
%
%
%
%
%
%
%

% Revisions:
%
% Apr 1, 2021 (Zoran)
%   - fixed a bug. The sampleList by default went 1:chamberNum instead
%     1:24.
%     Changed:
%        slopesList = 1:dataStruct.configIn.chNbr; 
%     to
%        slopesList = 1:round(24*3600/(dataStruct.configIn.sampleTime*dataStruct.configIn.chNbr)); 
% Mar 29, 2021 (Zoran)
%   - modified this function to calculate also just selected chambers and/or slopes
% Mar 25, 2020 (Zoran)
%   - modified code for UdeM_ACS_calc_fluxes function. Removed "gasType"
%     input parameter. The function now works for all gasTypes and all fits.
%
    arg_default('chambersToCalc',Inf);
    arg_default('slopesToCalc',Inf);
    arg_default('plotFlag',false);
    arg_default('fullCalcFlag',false);
    
    currentDate = dataStruct.tv;
    indOut = dataStruct.indexes;
    cFigNumMain = 2;
    cFigNum2 = 10;
    cFigNum3 = 11;
    %  select output type for plotting. If fullCalcFlag true then
    %  plot the full results of Biomet fits (exp_B). 
    %  Otherwise plot Licor (exp_L) estimates
    if fullCalcFlag
        outputType = 'exp_B';
    else
        outputType = 'exp_L';
    end
    
    % See if all or only selected chambers need to be recaluclated
    if isinf(chambersToCalc)
        chamberList = 1:dataStruct.configIn.chNbr;
    else
        chamberList = chambersToCalc;
    end
    % See if all or only selected chambers need to be recaluclated
    if isinf(slopesToCalc)
        slopesList = 1:round(24*3600/...
            (dataStruct.configIn.sampleTime*dataStruct.configIn.chNbr));     
    else
        slopesList = slopesToCalc;
    end    
%     tv = dataStruct.rawData.logger.CH_CTRL.tv; %#ok<*UNRCH>
%     ch_time_sec_CH_CTRL = (tv-tv(1))*24; %#ok<*NASGU>
%     tv = dataStruct.rawData.logger.CH_AUX_10s.tv;
%     ch_time_sec_AUX_10s = (tv-tv(1))*24;
    tv = dataStruct.rawData.analyzer.LGR.tv;
    ch_time_hours_LGR = (tv-tv(1))*24;
   
    % initialize figures
    if plotFlag
        UdeM_visualize_one_day(dataStruct,[], cFigNumMain,true)
        UdeM_visualize_one_day_fluxes(dataStruct,[],'co2',outputType,cFigNum2,true)
        UdeM_visualize_one_day_fluxes(dataStruct,[],'ch4',outputType,cFigNum3,true)
        userData = get(cFigNumMain,'userdata');
        if isempty(userData) | ~isfield(userData,'figNum') %#ok<*OR2>
            userData.figNum = uifigure;
            userData.flagPause = false;
            set(cFigNumMain,'userdata',userData);
            btn = uibutton(userData.figNum,'push','Position',[420, 218, 100, 22],'ButtonPushedFcn', 'userData = get(2,''userdata'');userData.flagPause = true;set(2,''userdata'',userData)');
        end
    end
    
    tx = now;
    for chNum=chamberList
        
        % Plotting
        if plotFlag
            UdeM_visualize_one_day(dataStruct,chNum, cFigNumMain,false)
        end
        
        %
        ty = now;
        indX = indOut.analyzer.LGR(chNum).start';
        indY = indOut.analyzer.LGR(chNum).end';
        traceY = medfilt1(dataStruct.rawData.analyzer.LGR.('CO2d_ppm'),3);   % filter out the spikes
        %
        % Calculate only selected slopes (user can decide to calculate only a particular 
        % slopes - this is useful when rapidly testing the ini parameters).
        % * the part below was supposed to somehow guard from calculating missing chambers
        %   (if the indX is not 24 elements long). It needs to be changed to achive that.
        %   Not urgent! **
        %slopesList = intersect(slopesList,1:length(indX));
        
        % Loop through each chamber cycle. Usually, for UdeM, all chambers
        % are measured inside 1 hour period so there will be 24 cycles (samples)
        % per chamber.
        for sampleNum=slopesList
            try

                % ================================================================
                % The idea is to always do Licor version of exponential fit 
                % plus iterative linear and quadratic fits.
                % When doing final reprocessing (on a faster PC than the site PC) 
                % then also do the full Biomet exponential iterative method.
                % ================================================================


                %--------------------------
                % Run iterative quadratic fit
                %--------------------------            
                oneIteration = false;
                flagVerbose = true;
                dataStruct = UdeM_data_fit(dataStruct,chNum,sampleNum,'co2','fit_quad',oneIteration,flagVerbose);
                dataStruct = UdeM_data_fit(dataStruct,chNum,sampleNum,'ch4','fit_quad',oneIteration,flagVerbose);            

                %--------------------------
                % Run iterative linear fit
                %--------------------------
                oneIteration = false;
                flagVerbose = true;
                dataStruct = UdeM_data_fit(dataStruct,chNum,sampleNum,'co2','fit_lin',oneIteration,flagVerbose);
                dataStruct = UdeM_data_fit(dataStruct,chNum,sampleNum,'ch4','fit_lin',oneIteration,flagVerbose);            



                %----------------------------------------------------------------------------------
                % If requested, run full calculations
                % Note:
                %   If plotFlag is true, doing full calculations will overwrite the "best estimates"
                %   (dcdt, rmse,c0,t0) from above so the plots will show the exp_B calculations
                %-----------------------------------------------------------------------------------
                if fullCalcFlag

                    %--------------------------
                    % Run Licor fit (exp_L)
                    %--------------------------
                    useLicorMethod = true;
                    flagVerbose = true;
                    dataStruct = UdeM_data_fit(dataStruct,chNum,sampleNum,'co2','fit_exp',useLicorMethod,flagVerbose);
                    dataStruct = UdeM_data_fit(dataStruct,chNum,sampleNum,'ch4','fit_exp',useLicorMethod,flagVerbose);

                    %--------------------------
                    % Run exp_B fit
                    %--------------------------
                    useLicorMethod = false;
                    flagVerbose = true;
                    dataStruct = UdeM_data_fit(dataStruct,chNum,sampleNum,'co2','fit_exp',useLicorMethod,flagVerbose);
                    dataStruct = UdeM_data_fit(dataStruct,chNum,sampleNum,'ch4','fit_exp',useLicorMethod,flagVerbose);
                end

                % ====================================
                % Calculate fluxes 
                % ====================================

                % Use the dcdt-s calculated above to calculate fluxes for 
                % all gases and all types or fits:
                dataStruct = UdeM_ACS_calc_fluxes(dataStruct,chNum,sampleNum);



                % Plotting
                if plotFlag
                    % check if the Pause button has been clicked
                    userData = get(cFigNumMain,'userdata');
                    if ~isempty(userData) 
                        figure(userData.figNum);
                        if userData.flagPause
                            fprintf('Paused.  Press any key to continue.\n');
                            userData.flagPause = false;
                            set(cFigNumMain,'userdata',userData);
                            pause
                            figure(userData.figNum);
                        end
                    end

                    % Update main data plot (full day of data, cFigNumMain)
                    t_fit = ch_time_hours_LGR(indX(sampleNum):indY(sampleNum));
                    c_fit = traceY(indX(sampleNum):indY(sampleNum));
                    figure(cFigNumMain)
                    subplot(2,2,3);
                    hold on
                    plot(t_fit,c_fit,'ro')
                    hold off          

                    plotDataType = 'exp_B';
                    UdeM_visualize_one_day_fluxes(dataStruct,chNum,'co2',outputType,cFigNum2,false) 
                    UdeM_visualize_one_day_fluxes(dataStruct,chNum,'ch4',outputType,cFigNum3,false)
                    UdeM_visualize_one_fit(dataStruct,chNum,sampleNum,plotDataType,'co2',98)
                    UdeM_visualize_one_fit(dataStruct,chNum,sampleNum,plotDataType,'ch4',99)
                end
            catch
                fprintf('Error calculating slopes for ch: %d  h:%d   (%s)\n',chNum,sampleNum,getErrorFunStack);
            end            
        end
        
        fprintf('Time to process chamber #%d fluxes for %s was %4.1f seconds\n',chNum,datestr(currentDate,'yyyymmdd'),(now-ty)*24*3600);
    end
    fprintf('Time to process all fluxes for %s was %4.1f seconds\n',datestr(currentDate,'yyyymmdd'),(now-tx)*24*3600);

end 







%================================================================================================
%     Local functions
%================================================================================================



function dataStruct = UdeM_data_fit(dataStruct,chNum,sampleNum,gasType,fitType,useLicorMethod,flagVerbose)
            arg_default('flagVerbose',false)
            tz = now;
                   
            indOut = dataStruct.indexes;
            indX = indOut.analyzer.LGR(chNum).start';
            indY = indOut.analyzer.LGR(chNum).end';
            switch lower(gasType)
                case 'co2'
                    traceY = medfilt1(dataStruct.rawData.analyzer.LGR.('CO2d_ppm'),3);   % filter out the spikes
                case 'ch4'
                    traceY = medfilt1(dataStruct.rawData.analyzer.LGR.('CH4d_ppm'),3);   % filter out the spikes
            end
            tv = dataStruct.rawData.analyzer.LGR.tv;
            ch_time_hours_LGR = (tv-tv(1))*24;
            
            t_fit = ch_time_hours_LGR(indX(sampleNum):indY(sampleNum));
            c_fit = traceY(indX(sampleNum):indY(sampleNum));
            
            % Fit parameters
            optionsIn.skipPoints        = dataStruct.configIn.chamber(chNum).(gasType).(fitType).skipPoints;            
            optionsIn.deadBand          = dataStruct.configIn.chamber(chNum).(gasType).(fitType).deadBand;                      
            optionsIn.pointsToTest      = dataStruct.configIn.chamber(chNum).(gasType).(fitType).pointsToTest;         
            optionsIn.timePeriodToFit   = dataStruct.configIn.chamber(chNum).(gasType).(fitType).timePeriodToFit;            
            
            switch lower(fitType)
                case 'fit_exp'        
                    [fitOut,fCO2,gof] = ...
                                     UdeM_exponential_fit(t_fit/24,c_fit,optionsIn,useLicorMethod,gasType);
                    if useLicorMethod
                        outputType = 'exp_L';
                    else
                        outputType = 'exp_B';
                    end
                case 'fit_lin'
                    oneIteration = useLicorMethod;
                    polyType = 'poly1';
                    [fitOut,fCO2,gof] = ...
                                     UdeM_polynomial_fit(t_fit/24,c_fit,optionsIn,oneIteration,polyType);
                    if useLicorMethod
                        outputType = 'lin_L';
                    else
                        outputType = 'lin_B';
                    end
                case 'fit_quad'
                    outputType = 'quad_B';
                    polyType = 2;                   % second order poly
                    [fitOut,fCO2,gof] = ...
                                     UdeM_polynomial_fit_fast(t_fit/24,c_fit,optionsIn,polyType);
            end
   
            dataStruct.chamber(chNum).sample(sampleNum).flux.(gasType).(outputType).dcdt = fitOut.dcdt;
            dataStruct.chamber(chNum).sample(sampleNum).flux.(gasType).(outputType).rmse = fitOut.rmse;
            dataStruct.chamber(chNum).sample(sampleNum).flux.(gasType).(outputType).t0 = fitOut.t0;
            dataStruct.chamber(chNum).sample(sampleNum).flux.(gasType).(outputType).c0 = fitOut.c0;
            dataStruct.chamber(chNum).sample(sampleNum).flux.(gasType).(outputType).fCO2 = fCO2;
            dataStruct.chamber(chNum).sample(sampleNum).flux.(gasType).(outputType).gof = gof;
            dataStruct.chamber(chNum).sample(sampleNum).flux.(gasType).(outputType).fitOut = fitOut;
            if flagVerbose
                    fprintf('%s(%s, %s):   ch: %d  h: %d  dcdt: %12.4e rmse: %12.4e c0: %6.2f  t0: %6.2f\n',gasType,fitType,outputType,chNum,sampleNum,fitOut.dcdt,fitOut.rmse,fitOut.c0,fitOut.t0)                         
            end

            dataStruct.chamber(chNum).sample(sampleNum).flux.(gasType).(outputType).t_elapsed = (now-tz)*24*3600;
end

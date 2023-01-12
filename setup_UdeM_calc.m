%% Setup UdeM calculations
%cd D:\NZ\MATLAB\CurrentProjects\UdeM
addpath('.\local_BIOMET.NET','-begin');
addpath('.\UBC_PC_Setup\Site_specific','-begin');
addpath('.\UBC_PC_Setup\PC_specific','-begin');
%[dataPth,hhourPth,databasePth,csi_netPth] = fr_get_local_path;


return


%% Main structure
%
% Data structure contains one day of data!!
%
%
%      dataOut
%               .configuration: [1x1 struct]
%
%               .rawData  - high frequency data (Instrument and Loggers)
%                   .analyzer
%                       .CH4_ppm       - data for one day
%                       .CO2_ppm
%                       ... (all variables)
%                       .tv             - time vector for hhour
%                   .logger
%                       .CH_CTRL
%                           ... (all variables)
%                       .CH_AUX_30min
%                           ... (all variables)
%               .data30min - hhour averages (same structure as rawData)
%                   .analyzer
%                       .co2.data
%                       .ch4.data
%                   .logger
%                       .CH_CTRL
%                           ... (all variables)
%                       .CH_AUX_30min
%                           ... (all variables)
%               .chamber()     - all chamber related data
%                   .sample()  - sample (avg/min/max/std)
%                       .tv
%                       .soilTemperature_in [avg/min/max/std]
%                       .soilTemperature_out [avg/min/max/std]
%                       .soilVWC_in [avg/min/max/std]
%                       .soilVWC_out [avg/min/max/std]
%                       .par_in [avg/min/max/std]
%                       .par_out [avg/min/max/std]
%                       .airTemperature [avg/min/max/std]
%                       .airPressure [avg/min/max/std]
%                       .co2_dry [avg/min/max/std]
%                       .ch4_dry [avg/min/max/std]
%                       .nwo_dry [avg/min/max/std]
%                       .h2o_dry [avg/min/max/std]
%                       .indSlope
%                           .n2o [start end]
%                           .co2 [start end]
%                           .ch4 [start end]
%                       .diag   (detailed diagnostics for this slope -all
%                               HF data [avg/min/max/std] for this slope)
%                           .pressureIn [avg/min/max/std]
%                           .pressureOut [avg/min/max/std]
%                           ...

%%
% Steps
%   - Load gas analyzer and climate data into the data structure
dateIn = datenum(2019,7,15:-1:15);
% use the loop below only if you want to refresh all the HF LGR mat files.
% Only the last day will be used below (dataOut is not cumulative).

for currentDate = dateIn
    tx = now;
    configIn = UdeM_init_all(currentDate);
    dataOut = UdeM_read_one_day(currentDate,configIn);
    
    fprintf('Time to load data for: %s was %4.1f seconds\n',datestr(currentDate,'yyyymmdd'),(now-tx)*24*3600);

    indOut = UdeM_find_chamber_indexes(dataOut,configIn);
    tv = dataOut.rawData.logger.CH_CTRL.tv;
    ch_time_sec_CH_CTRL = (tv-tv(1))*24;
    tv = dataOut.rawData.logger.CH_AUX_10s.tv;
    ch_time_sec_AUX_10s = (tv-tv(1))*24;
    tv = dataOut.rawData.analyzer.LGR.tv;
    ch_time_hours_LGR = (tv-tv(1))*24;
    
    %figure(1);clf
    figure(2);clf;ax(1)=subplot(2,2,1);ax(2)=subplot(2,2,2);ax(3)=subplot(2,2,3);ax(4)=subplot(2,2,4);linkaxes(ax,'x');zoom on;
    set(2,'Name',sprintf('Data for: %s',datestr(currentDate)),'numbertitle','off','menubar','none','WindowState','maximized');
    %figure(3);clf
    
    % Parameters for exponential fit
    optionsIn.skipPoints = 35;                  %
    optionsIn.deadBand = 40;                      %
    optionsIn.pointsToTest      = 20;         % (samples) number of samples over which to test t0
    optionsIn.timePeriodToFit = 200 ...
        - optionsIn.deadBand...
        - optionsIn.skipPoints...
        - optionsIn.pointsToTest;        % (s) length of exp fit starting from t0
    
    % reserve space for one day worth of output data
    dcdt=NaN*ones(24,18);
    rmse_exp = NaN*ones(24,18);
    c0 = NaN*ones(24,18);
    t0=NaN*ones(24,18);
    fitOut = struct([]);
    fCO2 = struct([]);
    gof = struct([]);
    tx = now;
    for i=1:18
        figure(2);
        
        subplot(2,2,1);
        indX = indOut.logger.CH_AUX_10s(i).start';
        indY = indOut.logger.CH_AUX_10s(i).end';
        %     ch_time_sec(indX),dataOut.rawData.logger.CH_AUX_10s.(sprintf('CHMBR_AirTemp_Avg%d',i))(indX),'ro',...
        plot(ch_time_sec_AUX_10s,dataOut.rawData.logger.CH_AUX_10s.(sprintf('CHMBR_AirTemp_Avg%d',i)),'-')
        title(sprintf('Chamber: %d',i))
        ylabel('T_{air}')
        xlabel('Hours')
        hold on
        for j=1:length(indX)
            plot(ch_time_sec_AUX_10s(indX(j):indY(j)),dataOut.rawData.logger.CH_AUX_10s.(sprintf('CHMBR_AirTemp_Avg%d',i))(indX(j):indY(j)),'ro')
        end
        hold off
        
        subplot(2,2,2);
        indX = indOut.logger.CH_AUX_10s(i).start';
        indY = indOut.logger.CH_AUX_10s(i).end';
        %     ch_time_sec(indX),dataOut.rawData.logger.CH_AUX_10s.(sprintf('CHMBR_AirTemp_Avg%d',i))(indX),'ro',...
        fieldNamePAR = sprintf('CHMBR%d_PAR_Avg',i);
        if isfield(dataOut.rawData.logger.CH_AUX_10s,fieldNamePAR)
            plot(ch_time_sec_AUX_10s,dataOut.rawData.logger.CH_AUX_10s.(fieldNamePAR),'-')
            title(sprintf('Chamber: %d',i))
            hold on
            for j=1:length(indX)
                plot(ch_time_sec_AUX_10s(indX(j):indY(j)),dataOut.rawData.logger.CH_AUX_10s.(fieldNamePAR)(indX(j):indY(j)),'ro')
            end
            hold off
            xlabel('Hours')
            ylabel('PAR sensor')
        else
            plot(ch_time_sec_AUX_10s,zeros(length(ch_time_sec_AUX_10s),1))
            title('no PAR data')
            xlabel('Hours')
            ylabel('PAR sensor')
        end
        
        subplot(2,2,3);
        indX = indOut.analyzer.LGR(i).start';
        indY = indOut.analyzer.LGR(i).end';
        %     ch_time_sec(indX),dataOut.rawData.logger.CH_AUX_10s.(sprintf('CHMBR_AirTemp_Avg%d',i))(indX),'ro',...
        plot(ch_time_hours_LGR,dataOut.rawData.analyzer.LGR.('CO2d_ppm'),'-')
        title(sprintf('Chamber: %d',i))
        ylabel('CO_2')
        xlabel('Hours')
        hold on
        ty = now;
        for j=1:length(indX)
            t_fit = ch_time_hours_LGR(indX(j):indY(j));
            c_fit = dataOut.rawData.analyzer.LGR.('CO2d_ppm')(indX(j):indY(j));
            plot(t_fit,c_fit,'ro')
            tic;
            [fitOut{j,i},fCO2{j,i},gof{j,i}] = co2_exponential_fit_licor(t_fit/24,c_fit,optionsIn);
            dcdt(j,i) = fitOut{j,i}.dcdt; %#ok<*SAGROW>
            rmse_exp(j,i) = fitOut{j,i}.rmse;
            c0(j,i) = fitOut{j,i}.c0;
            t0(j,i) = fitOut{j,i}.t0;
            fprintf('ch: %d  h: %d  dcdt: %6.4f c0: %6.2f  t0: %6.2f\n\n',i,j,fitOut{j,i}.dcdt,fitOut{j,i}.c0,fitOut{j,i}.t0)
            t_elapsed(j,i) = toc;
            
            figure(1);
            clf
            x=t_fit/24;%t_fit(optionsIn.skipPoints:end,1);
            x=(x-x(optionsIn.skipPoints))*24*60*60;
            plot(fCO2{j,i}{fitOut{j,i}.N_optimum},x,c_fit) %(optionsIn.skipPoints:end,1))
            
            ax=axis;
            v = [0 ax(3);
                0 ax(4);
                optionsIn.deadBand ax(4);
                optionsIn.deadBand ax(3)];
            f=[1 2 3 4];
            h=patch('Vertices',v,'faces',f,'facecolor','g','edgecolor','none','facealpha',0.2);
            
            v2 = [ax(1) ax(3);ax(1) ax(4);0 ax(4);0 ax(3)];
            f2=[1 2 3 4];
            h2=patch('Vertices',v2,'faces',f2,'facecolor','y','edgecolor','none','facealpha',0.3);
            
            v3 = [0                         max(ax(3),fitOut{j,i}.c0-10);
                0                         min(ax(4),fitOut{j,i}.c0+10);
                optionsIn.pointsToTest    min(ax(4),fitOut{j,i}.c0+10);
                optionsIn.pointsToTest    max(ax(3),fitOut{j,i}.c0-10)];
            f3=[1 2 3 4];
            h3=patch('Vertices',v3,'faces',f3,'facecolor','none','edgecolor','#0072BD','facealpha',0.7);
            
            
            %legend('Data','fit','deadband','skipped','t0 search','location','southeast')
            
            %hh=line(x(fitOut.N_optimum+optionsIn.skipPoints),c_fit(fitOut.N_optimum),'marker','o','markersize',10,'color','#D95319','markerfacecolor','#D95319')
            hh=line(fitOut{j,i}.t0,fitOut{j,i}.c0,'marker','+','markersize',10,'color','#D95319','markerfacecolor','#D95319','linewidth',2);
            legend('Data','fit','deadband','skipped','t0 search','t0','location','southeast')
            %pause
            figure(10);
            axx(1)=subplot(4,1,1);
            plot(dcdt);ylabel('dcdt');
            axx(2)=subplot(4,1,2);
            plot(rmse_exp);ylabel('rmse');
            axx(3)=subplot(4,1,3);
            plot(c0);ylabel('C_0');
            axx(4)=subplot(4,1,4);
            plot(t0);ylabel('T_0');
            linkaxes(axx,'x');
            
            figure(2);
        end
        hold off
        
        subplot(2,2,4);
        plot(ch_time_hours_LGR,dataOut.rawData.analyzer.LGR.('CH4d_ppm'),'-')
        title(sprintf('Chamber: %d',i))
        ylabel('CH_4')
        xlabel('Hours')
        hold on
        for j=1:length(indX)
            plot(ch_time_hours_LGR(indX(j):indY(j)),dataOut.rawData.analyzer.LGR.('CH4d_ppm')(indX(j):indY(j)),'ro')
        end
        hold off
        fprintf('Time to process chamber #%d fluxes for %s was %4.1f seconds\n',i,datestr(currentDate,'yyyymmdd'),(now-ty)*24*3600);
    end
    fprintf('Time to process all fluxes for %s was %4.1f seconds\n',datestr(currentDate,'yyyymmdd'),(now-tx)*24*3600);
    %pause
    fileNameOut = sprintf('%s_recalcs_UdeM',datestr(currentDate,'yyyymmdd'));
    fprintf('Saving all data for %s in file: %s \n',datestr(currentDate,'yyyymmdd'),fileNameOut)
        % Plot dcdt-s, errors...
    save(fileNameOut)
end

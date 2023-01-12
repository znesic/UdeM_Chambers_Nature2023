function view_LGR_Chamber_data(dateIn)
% view_EC_data(dateIn) - loads and plots system HF data for a UBC EC system
%
% Note:  Current data (dateIn = now) is not available with 
%        UBC_GII software.  Only the historical data can be plotted
%        using this program (any 30-minute period before the current one)
%
% (c) Zoran Nesic               File created:       Jan 31, 2019
%                               Last modification:  Feb 17, 2019
% View_EC_data(now-1/48) % Previous h-hour data 
% View_EC_data(now-5/48) % Previous 5th h-hour

% Revisions (newest first)
%
% Feb 17, 2019 (Zoran)
%   - Fixed the warnings regarding the file name string in the title.
%     Replaced '\' with '/'


% Get current site ID
SiteID = fr_current_siteID; %#ok<NASGU>

pth = 'd:\met-data\data';
fileName = [FR_DateToFileName(dateIn) '.dUdeM101'];
fName = fullfile(pth,fileName);
s = dir(fName);
if isempty(s)
    fName = fullfile(pth,fileName(1:6),fileName);
    s = dir(fName);
    if isempty(s)
        error('File: %s not found.',fName);
    end
end

[EngUnits,Header,tv] = fr_read_LGR2_file(fName,[],1); %#ok<ASGLU>
tv_sec = (tv-tv(1))*24*60*60;
fig = 0;

fNameTitle = fName;
fNameTitle(strfind(fName,'\')) = '/';

fig=fig+1;
figure(fig)
plot(tv_sec,EngUnits(:,1)/1000)
title({datestr(tv(end)),sprintf('File: %s',fNameTitle)})
xlabel('Time [s]')
ylabel('H_2O [mmol/mol]')
zoom on
grid on

fig=fig+1;
figure(fig)
plot(tv_sec,EngUnits(:,7))
title({datestr(tv(end)),sprintf('File: %s',fNameTitle)})
xlabel('Time [s]')
ylabel('CH_4d [\mumol/mol]')
zoom on
grid on

fig=fig+1;
figure(fig)
plot(tv_sec,EngUnits(:,9))
title({datestr(tv(end)),sprintf('File: %s',fNameTitle)})
xlabel('Time (s)')
ylabel('CO_2d [\mumol/mol]')
zoom on
grid on

fig=fig+1;
figure(fig)
plot(tv_sec,EngUnits(:,11))
title({datestr(tv(end)),sprintf('File: %s',fNameTitle)})
xlabel('Time (s)')
ylabel('Pressure [Torr]')
zoom on
grid on

fig=fig+1;
figure(fig)
plot(tv_sec,EngUnits(:,13))
title({datestr(tv(end)),sprintf('File: %s',fNameTitle)})
xlabel('Time (s)')
ylabel('T_{cell} [\circC]')
zoom on
grid on


fig=fig+1;
figure(fig)
plot(tv_sec,EngUnits(:,15))
title({datestr(tv(end)),sprintf('File: %s',fNameTitle)})
xlabel('Time (s)')
ylabel('T_{ambient} [\circC]')
zoom on
grid on

fig=fig+1;
figure(fig)
plot(tv_sec,EngUnits(:,17))
title({datestr(tv(end)),sprintf('File: %s',fNameTitle)})
xlabel('Time (s)')
ylabel('RD0_us []')
zoom on
grid on

fig=fig+1;
figure(fig)
plot(tv_sec,EngUnits(:,19))
title({datestr(tv(end)),sprintf('File: %s',fNameTitle)})
xlabel('Time (s)')
ylabel('RD1_us []')
zoom on
grid on



fig=fig+1;
figure(fig)
plot(tv_sec,EngUnits(:,21))
title({datestr(tv(end)),sprintf('File: %s',fNameTitle)})
xlabel('Time (s)')
ylabel('Temp_Status [mA]')
zoom on
grid on


fig=fig+1;
figure(fig)
plot(tv_sec,EngUnits(:,23))
title({datestr(tv(end)),sprintf('File: %s',fNameTitle)})
xlabel('Time (s)')
ylabel('Analyzer_Status [mA]')
zoom on
grid on




% disp('==========================')
% disp('Data points collected')
% fprintf('System: %d\n',nSystem)
% fprintf('Sonic:  %d\n',nSonic)
% fprintf('IRGA:   %d\n',nIRGA)
% disp('Fluxes:')
% fprintf('Fc     = %8.2f\n',Stats_New.MainEddy.Three_Rotations.LinDtr.Fluxes.Fc)
% fprintf('Hs     = %8.2f\n',Stats_New.MainEddy.Three_Rotations.LinDtr.Fluxes.Hs)
% fprintf('LE     = %8.2f\n',Stats_New.MainEddy.Three_Rotations.LinDtr.Fluxes.LE_L)
% if ~isempty(LGRNum)
%     fprintf('LE_LGR = %8.2f\n',Stats_New.MainEddy.Three_Rotations.LinDtr.Fluxes.LE_LGR)
%     fprintf('F_n2o  = %8.2f\n',Stats_New.MainEddy.Three_Rotations.LinDtr.Fluxes.F_n2o)
%     fprintf('F_ch4  = %8.2f\n',Stats_New.MainEddy.Three_Rotations.LinDtr.Fluxes.F_ch4)
% end
% fprintf('u*     = %8.2f\n',Stats_New.MainEddy.Three_Rotations.LinDtr.Fluxes.Ustar)
% disp('Delay times:');
% disp(Stats_New.MainEddy.Delays);
% disp('==========================')
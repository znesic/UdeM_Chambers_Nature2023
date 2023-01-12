function dataOut = UdeM_read_one_day(dateIn,configIn)
%  dataOut = UdeM_read_one_day(dateIn,configIn) - loads one day of UdeM chamber
%                                         data (loggers and LGR)
%
% example:
%   dateIn = datenum(2019,8,22)
%   configIn = UdeM_init_all(dateIn);
%   dataOut = UdeM_read_one_day(dateIn,configIn); % load Aug 22, 2019 data
%
% Zoran Nesic                   File created:       Jan 26, 2020
%                               Last modification:  Jan 31, 2020
%

% Revisions (newest first):
%
% Jan 31, 2020 (Zoran)
%   - Made sure that the dateIn is a single element and not a vector.  The
%     function is called "read_ONE_day" after all.  In case I forget and
%     pass an array.

dataOut(1).configIn = configIn;
dateIn = dateIn(1);

%dataOut.tv = fr_round_time(dateIn);

% The data logger files are stored in daily files and labeled with the end
% time (tomorow's date!). 
% The following creates the correct base file name: 'yymmdd'
dateInLogger = floor(dateIn)+1;
dayStr = datestr(round(dateInLogger),'yyyymmdd');

% First load daily files (data logger data)
instrumentNum = 2;
fileName = fullfile(configIn.csi_path,[configIn.Instrument(instrumentNum).fileName '.' dayStr]);
time_str_flag = configIn.Instrument(instrumentNum).time_str_flag;
headerlines = configIn.Instrument(instrumentNum).headerlines;
defaultNaN = configIn.Instrument(instrumentNum).defaultNaN;
assign_in = configIn.Instrument(instrumentNum).assign_in;
%[~,~,~,CH_CTRL] = fr_read_TOA5_file(fileName,time_str_flag,headerlines,defaultNaN,assign_in,[],[],'CH_CTRL');
cmdStr = sprintf('[~,~,~,rawData.logger.%s] = fr_read_TOA5_file(fileName,time_str_flag,headerlines,defaultNaN);',configIn.Instrument(instrumentNum).varName);
eval(cmdStr)

instrumentNum = 3;
fileName = fullfile(configIn.csi_path,[configIn.Instrument(instrumentNum).fileName '.' dayStr]); %#ok<*NASGU>
time_str_flag = configIn.Instrument(instrumentNum).time_str_flag;
headerlines = configIn.Instrument(instrumentNum).headerlines;
defaultNaN = configIn.Instrument(instrumentNum).defaultNaN;
assign_in = configIn.Instrument(instrumentNum).assign_in;
cmdStr = sprintf('[~,~,~,rawData.logger.%s] = fr_read_TOA5_file(fileName,time_str_flag,headerlines,defaultNaN);',configIn.Instrument(instrumentNum).varName);
eval(cmdStr)

instrumentNum = 4;
fileName = fullfile(configIn.csi_path,[configIn.Instrument(instrumentNum).fileName '.' dayStr]); %#ok<*NASGU>
time_str_flag = configIn.Instrument(instrumentNum).time_str_flag;
headerlines = configIn.Instrument(instrumentNum).headerlines;
defaultNaN = configIn.Instrument(instrumentNum).defaultNaN;
assign_in = configIn.Instrument(instrumentNum).assign_in;
cmdStr = sprintf('[~,~,~,rawData.logger.%s] = fr_read_TOA5_file(fileName,time_str_flag,headerlines,defaultNaN);',configIn.Instrument(instrumentNum).varName);
eval(cmdStr)


% Create daily raw data files (each trace is one day long as
% oposed to 30 minutes). It could make more sense with 1-hour cycle (or
% longer) of chamber measurements.

% First store the logger data
%
dataOut.rawData.logger = rawData.logger;

% Then join the analyzer data
instrumentNum = 1;
instrumentVarName = configIn.Instrument(instrumentNum).varName;
dataOut.rawData.analyzer.(instrumentVarName)= struct('tv',[]);
for i = 1:48
    currentDate = floor(dateIn)+i/48;
    try
        [~,~,rawData.analyzer.(instrumentVarName)] = fr_read_LGR2(currentDate,configIn,instrumentNum);
        for fieldName = fieldnames(rawData.analyzer.(instrumentVarName))'   
            fName = char(fieldName);
            if isfield(dataOut.rawData.analyzer.(instrumentVarName),fName)
                dataOut.rawData.analyzer.(instrumentVarName).(fName) = [dataOut.rawData.analyzer.(instrumentVarName).(fName); ...
                                                                                rawData.analyzer.(instrumentVarName).(fName)];
            else
                dataOut.rawData.analyzer.(instrumentVarName).(fName) = rawData.analyzer.(instrumentVarName).(fName);
            end
        end
    catch
        fprintf('Missing or bad file for: %s\n',datestr(currentDate));
    end
end


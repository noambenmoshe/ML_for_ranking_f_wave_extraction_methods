%% This function runs the main functions for f-wave extraction
 
close all
clear
clc
 
 
 
%% define function paths
 
slash = '\';
main_path =pwd; 
 
%% define global variables
maxNumCompThreads(20)
db = {'JPAFDB'}; %{'UVAFDB', 'RBAFDB', 'JPAFDB'}; % the name of the db directories
db_name = {'SHDB'}; %{'UVAF', 'RBDB', 'SHDB'}; % the name of the db for ploting
NUM_OF_PCA_COMP=3;
CORRECT_QRS = 1;
sevireties = ["preprocessed_af", "preprocessed_non_af"]; %["mild","mod","sev", "preprocessed_af", "preprocessed_non_af"]
plot_= 0; 
debug_= 0;
lead_num=2;%{1, 2} 
 
ms = 1000; % 1sec=1000ms (milliseconds)
N_S_IN_HOUR=3600; % 1hour=3600sec
N_S_IN_MIN=60; % 1min=60sec
N_MINUTES_EPISODE=1; % minimum event length
 
methods = ["TS", "TS_cerutti", "TS_suzzane", "TS_PCA"] ;% "TS_KF"
methods_names = ["$\mathrm{ABS}$", "$\mathrm{ABS_{sc1}}$", "$\mathrm{ABS_{sc2}}$", "$\mathrm{TS_{PCA}}$"];
N_methods=length(methods); % (KF, TS, TS cerutti, TS PCA, TS suzzane)
% Frequency range for AA
upper_fibFreqz = 12.05;
lower_fibFreqz = 3.95;
 
 
% TS parameters
LOW_CUT_FREQ = 4;% 0.5;
HIGH_CUT_FREQ = 45;
 
 
%Plot parameters
set(groot,'defaultAxesTickLabelInterpreter','latex'); 
line_styles = ["-" "--" ":" "-."];
TEXT_SIZE = 35;
LINE_WIDTH = 2;
 
 
%% Load data
for i=1:length(db)
    main_path_db = [main_path slash 'databases' slash db{i} slash];
    savefolder_figs = [main_path_db 'figs_preprocessed_all_60'];
    savefolder_mats = [main_path_db 'mats_preprocessed_all_60']; 
   
    for s=1:length(sevireties)
        if sevireties(s) == 'preprocessed_af'
            myfolder = [main_path_db 'AF_preprocessed_all_60'];
            file_prefix = "";
            sqi_file = [db{i} '_AF_preprocessed_all_60_' int2str(lead_num) '.csv'];
        elseif sevireties(s) == 'preprocessed_non_af'
            myfolder = [main_path_db 'nonAF_preprocessed_all_60'];
            file_prefix = "_nonAF";
            sqi_file = [db{i} '_nonAF_preprocessed_all_60_' int2str(lead_num) '.csv'];
        else
           print('s is not good')
        end
 
        filePattern = fullfile(myfolder, '*.mat');
        matFiles = dir(filePattern);
        N = length(matFiles(not([matFiles.isdir])));
        
 
        % set local variables
        % F_AA - frequency of the AA mat, shape: (rows: events, columns:
        % extraction methods)
        % df_meta - meta information matching the rows in F_AA
        F_AA = zeros(N , N_methods);
        df_mag =  zeros(N , N_methods);
        df_integral_in_bound  = zeros(N , N_methods);
        df_meta =  cell(3, N ); % id, age, sex
        df_start_time = zeros(N , 1);
        df_end_time = zeros(N , 1);
        df_a_pp_median =  zeros(N , 1);
        df_a_pp_mean =  zeros(N , 1);
 
        count = 0;
        start_index = 1;
        ts_residuals_mat = zeros(N, N_MINUTES_EPISODE*N_S_IN_MIN*200);
        ce_residuals_mat = zeros(N, N_MINUTES_EPISODE*N_S_IN_MIN*200);
        su_residuals_mat = zeros(N, N_MINUTES_EPISODE*N_S_IN_MIN*200);
        pca_residuals_mat = zeros(N, N_MINUTES_EPISODE*N_S_IN_MIN*200);
        qrs_values = {};
        
      
        for k = start_index:length(matFiles)
            k
 
            matFilename = fullfile(myfolder, matFiles(k).name);
            data = load(matFilename);
            
             %retrieve meta information
            [filepath,name,ext] = fileparts(matFilename);
            split_name = split(name,'_');
            id = split_name{1};
            start_time = split_name{5};
            start_time = str2double(start_time);
            end_time = split_name{7};
            end_time = str2double(end_time);
 
            id = str2double(id);
           
            if  size(data.data, 1)< lead_num
                continue
            elseif isempty(data.rqrs)
                continue
            else
                count = count +1;
                end_ecg=data.fs*N_MINUTES_EPISODE*N_S_IN_MIN;
                ecg_temp(1, :)=data.data(lead_num, 1:end_ecg);
                if iscell(data.rqrs) % check the strcuture of data.rqrs
                    qrs_temp{1}=data.rqrs{1}(find(data.rqrs{1}<end_ecg));
                    qrs_temp{2}=data.rqrs{2}(find(data.rqrs{2}<end_ecg));
                else
                    qrs_temp{1}=data.rqrs(1, find(data.rqrs(1,:)<end_ecg));
                    qrs_temp{2}=data.rqrs(2, find(data.rqrs(2,:)<end_ecg));
                end
                if size(data.data, 1)==3
                    ecg_temp(3,:)=data.data(3, 1:end_ecg);
                    if iscell(data.rqrs)
                        qrs_temp{3}=data.rqrs{3}(find(data.rqrs{3}<end_ecg));
                    else
                        qrs_temp{3}=data.rqrs(3, find(data.rqrs(3,:)<end_ecg));
                    end
                end
                data.data=ecg_temp;
                data.rqrs=qrs_temp;
 
                if iscell(data.rqrs)
                    qrs = data.rqrs{lead_num}+1;
                else
                    qrs = data.rqrs(lead_num,:)+1;
                end
                if length(qrs) < 10
                    fprintf('Skiped because of qrs is of length less than 10')
                    continue
                end
                if length(qrs) > 22 % define parameter for TS methods
                    NbCycles=20;
                else
                    NbCycles = round(length(qrs)/2);
                end
 
                ecg = data.data(1,:);
                fs = double(data.fs); % initial sampling freq.
 
%                 methods: --'TS','TS-CERUTTI','TS-SUZANNA','TS-PCA'--
%                 ECG preprocessing
                [b_lp,a_lp] = butter(5,HIGH_CUT_FREQ/(fs/2),'high');
                [b_bas,a_bas] = butter(2,LOW_CUT_FREQ/(fs/2),'high');
                ecg = ecg-mean(ecg); % (1) centre
                bpfecg = ecg'-filtfilt(b_lp,a_lp,ecg'); % (2) remove higher freq (zero phase)
                bpfecg = filtfilt(b_bas,a_bas,bpfecg); % (3) remove baseline (zero phase)      
                
                if CORRECT_QRS ==1
                    qrs = qrs_adjust(bpfecg,qrs,fs,abs(max(bpfecg))> abs(min(bpfecg)),0.05,0);
                    qrs = qrs_adjust(bpfecg,qrs,fs,abs(max(bpfecg))> abs(min(bpfecg)),0.02,0);
 
                end
                
                %extract the fwaves using different methods
                residual_TS = FECGSYN_ts_extraction(qrs,bpfecg','TS',debug_, NbCycles,'',fs);
                residual_CE = FECGSYN_ts_extraction(qrs,bpfecg','TS-CERUTTI',debug_, NbCycles,'',fs);
                residual_SU = FECGSYN_ts_extraction(qrs,bpfecg','TS-SUZANNA',debug_, NbCycles,'',fs);
                residual_PCA = FECGSYN_ts_extraction(qrs,bpfecg','TS-PCA',debug_, NbCycles,NUM_OF_PCA_COMP,fs);
  
 
                ts_residuals_mat(k,:)= residual_TS;
                ce_residuals_mat(k,:)= residual_CE;
                su_residuals_mat(k,:)= residual_SU;
                pca_residuals_mat(k,:)= residual_PCA;
                qrs_values(k) = {qrs};
 
                AA.residual_TS = residual_TS;
                AA.residual_CE = residual_CE;
                AA.residual_SU = residual_SU;
                AA.residual_PCA = residual_PCA;
%                 extract freq domain
                fns = fieldnames(AA);
               if plot_    
                    nb_of_points = length(residual_PCA);
                    tm = 1/fs:1/fs:nb_of_points/fs;
                    [P,Q] = rat(200/250);
                    figure('Renderer', 'painters', 'Position', [10 10 1400 700])
                    hold on;
                    plot(tm,bpfecg, 'k','LineWidth',LINE_WIDTH); hold on;
                    plot(tm(qrs),bpfecg(qrs),'+r','LineWidth',LINE_WIDTH);
                    plot(tm, residual_TS+mean(bpfecg)-0.2, 'k','LineWidth',LINE_WIDTH); hold on;
                    plot(tm, residual_CE+mean(bpfecg)-0.4, 'k','LineWidth',LINE_WIDTH);  hold on;
                    plot(tm, residual_SU+mean(bpfecg)-0.6, 'k','LineWidth',LINE_WIDTH);  hold on;
                    plot(tm, residual_PCA+mean(bpfecg)-0.8, 'k','LineWidth',LINE_WIDTH); hold on;
                    xlim([0, 5])
                    ylim([-0.9 0.4])
                    xlabel('Time[sec]','interpreter','latex', 'FontSize', TEXT_SIZE);
                    set(gca, 'YTick', [mean(bpfecg)-0.8 mean(bpfecg)-0.6 mean(bpfecg)-0.4 mean(bpfecg)-0.2 mean(bpfecg)], 'YTickLabel', {"$\mathrm{TS_{PCA}}$", "$\mathrm{ABS_{sc2}}$","$\mathrm{ABS_{sc1}}$","$\mathrm{ABS}$",  'ECG'}, 'FontSize', TEXT_SIZE)
 
               end
                if plot_
                    figure('Renderer', 'painters', 'Position', [10 10 1400 700])
 
                end
                
                %calculate features for each fwave extraction method
                before_R_length = ceil(0.09*fs)-1;
                after_R_length = floor(0.09*fs);
                for j=1:N_methods
                    [F_AA(k,j),df_mag(k,j), df_integral_in_bound(k,j), Pxx, F,df_a_pp_mean(k,j),  df_a_pp_median(k,j)]= calc_features(AA.(fns{j}), qrs,fs,  before_R_length, after_R_length, lower_fibFreqz, upper_fibFreqz,0 );%plot_
                    if plot_
                        plot(F,Pxx, 'LineStyle', line_styles(j), 'LineWidth', LINE_WIDTH); hold on;
                    end
                end
 
                if plot_
                    box off
                    legend(methods_names,'interpreter','latex', 'FontSize', TEXT_SIZE)
                    legend('boxoff')
                    xlim([0 25]);
                    ax = gca;
                    ax.FontSize = TEXT_SIZE;
 
 
                    xlabel('Frequency [Hz]','interpreter','latex', 'FontSize', TEXT_SIZE);
                    ylabel('Magnitude [${\mu V^2}/{Hz}$]','interpreter','latex', 'FontSize', TEXT_SIZE)
 
                    ax.YAxis.Label.Visible = 'on';
                    ax2 = axes('Position',ax.Position,...
                      'XColor',[0 0 0],...
                      'YColor',[1 1 1],...
                      'Color','none',...
                      'XTick',[],...
                      'YTick',[]);
                    hold on
 
 
                     print(gcf,string(main_path + "figs\" + "F_dist_"+ db_name +".png"),'-dpng','-r400')
 
                end
                df_meta{1, k}=data.id;
                df_meta{2, k}=data.Age;
                df_meta{3, k}=data.Sex;
                df_start_time(k) = start_time;
                df_end_time(k) = end_time;
 
            end 
            end
       
         % save structs
        files=cellstr(ls(myfolder));
        myStruct.files=files;
      
        F_AA_tot = [F_AA]; 
        idx = any(F_AA_tot>0,2);
        F_AA_tot=F_AA_tot(idx,:);
        F_AA_tot_maj=mode(F_AA_tot, 2); % most dominant DAF by mode function
        F_AA_tot_included = [F_AA_tot F_AA_tot_maj];
        
        
        myStruct.F_AA=F_AA_tot_included;
        myStruct.df_meta = df_meta(:,idx);
        myStruct.df_mag =  df_mag(idx,:);
        myStruct.df_integral_in_bound = df_integral_in_bound(idx,:);
        myStruct.df_start_time =  df_start_time(idx,:);
        myStruct.df_end_time =df_end_time(idx,:);
        myStruct.df_a_pp_median =df_a_pp_median(idx,:);
        myStruct.df_a_pp_mean =df_a_pp_mean(idx,:);
 
 
 
        save(savefolder_mats + "\F_wave_features"+file_prefix+"_" +NUM_OF_PCA_COMP+"_CQ_"+CORRECT_QRS+"_ch_"+lead_num+".mat", 'myStruct');
 
 
 
    end
        end
 
fprintf('done')
 
 
 


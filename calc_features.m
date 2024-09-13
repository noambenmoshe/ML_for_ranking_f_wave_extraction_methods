function [daf, mag, in_bound, Pxx, F ,a_pp_mean, a_pp_median]= calc_features(extracted_fwaves, qrs,fs,  before_R_length, after_R_length,lower_fibFreqz, upper_fibFreqz, plot_)
% Function to calculate various features from extracted f-waves
% Inputs:
%   - extracted_fwaves: A vector of extracted f-wave data
%   - qrs: A vector containing QRS complex indices, index of R peak
%   - fs: Sampling frequency
%   - before_R_length: Length of data to consider as part of the QRS before R peak in samples
%   - after_R_length: Length of data to consider as part of the QRS after R peak in samples
%   - lower_fibFreqz: Lower bound of the frequency range for f-waves, default 3.95Hz
%   - upper_fibFreqz: Upper bound of the frequency range for f-waves, 12.05 Hz
%   - plot_: Boolean flag to control plotting (1 for plotting, 0 for no plotting)
%
% Outputs:
%   - daf: Dominant atrial frequency
%   - mag: Magnitude of the dominant atrial frequency
%   - in_bound: Integral of the power specturm within f-wave frequency range
%   - Pxx: Power spectral density estimate
%   - F: Frequency vector corresponding to Pxx
%   - a_pp_mean: mean of the minimum-to-maximum amplitude difference outside QRS
%   - a_pp_median: median of the minimum-to-maximum amplitude difference outside QRS
 
    [Pxx,F,~] = pwelch(extracted_fwaves,256,[],1024,fs);
    idx_fib = find(F>lower_fibFreqz & F<upper_fibFreqz);
    [mag_max,ind_max] = max(Pxx(idx_fib));
    daf= F(ind_max + idx_fib(1)-1);
    mag = mag_max;
    [a_pp_mean, a_pp_median] = calc_amp_diff_outside_qrs(extracted_fwaves, qrs, before_R_length, after_R_length, plot_,fs);
    in_bound = trapz(idx_fib-idx_fib(1), Pxx(idx_fib));
end
 
function [a_pp_mean, a_pp_median]  = calc_amp_diff_outside_qrs(extraced_fwaves, qrs, before_R_length, after_R_length, plot_, fs)
% Function to calculate the amplitude difference outside QRS complexes
% Inputs:
%   - extracted_fwaves: A vector of extracted f-wave data
%   - qrs: A vector containing QRS complex indices, index of R peak
%   - before_R_length: Length of data to consider before R peak in samples
%   - after_R_length: Length of data to consider after R peak in samples
%   - plot_: Boolean flag to control plotting (1 for plotting, 0 for no plotting)
%   - fs: Sampling frequency
% Outputs:
%   - a_pp_mean: mean of the minimum-to-maximum amplitude difference outside QRS
%   - a_pp_median: median of the minimum-to-maximum amplitude difference outside QRS
 
    start_qrs = qrs - before_R_length;
    end_qrs = qrs + after_R_length;
    %fix ends
    start_qrs(start_qrs < 1) = 1;
    end_qrs(end_qrs > length(extraced_fwaves)) = length(extraced_fwaves);
    extracted_fwaves_outside_qrs = extraced_fwaves;
    for i=1:length(start_qrs)
        extracted_fwaves_outside_qrs(start_qrs(i):end_qrs(i)) = NaN;
    end   
    
    reshaped_data = reshape(extracted_fwaves_outside_qrs, 2000, []);
    max_values = max(reshaped_data);
    min_values = min(reshaped_data);
    max_min_diff = max_values - min_values;
 
    a_pp_median =   prctile(max_min_diff,50);
    a_pp_mean = mean(max_min_diff);
        
    if plot_
        figure()
        nb_of_points = length(extraced_fwaves);
        tm = 1/fs:1/fs:nb_of_points/fs;
        figure()
        plot(tm, extraced_fwaves); hold on;
        plot(tm(qrs),extraced_fwaves(qrs),'+r'); hold on;
        plot(tm, extracted_fwaves_outside_qrs); hold on;
    end
end

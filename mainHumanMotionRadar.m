
% set parameters
npulse = 2000; % number of pluses, total time 3000 * 0.001 = 3.0 seconds
bw = 10e6; % bw for FMCW, 100 MHZ
fs = 1.25*bw; % sampling rate 125 MHZ
fc = 60e9; % carrier frequency 60GHz
tm = 10e-6; % 1 us
c = 3e8; % light speed
Tsamp = 2.5e-4; % duration of a frame

wav = phased.FMCWWaveform('SampleRate',fs,'SweepTime',tm,...
    'SweepBandwidth',bw); % transmit signal

tx_pos = [3;1.5;1]; % on the desk
tx_vel = [0;0;0]; % fixed
radar_tx = phased.Platform('InitialPosition',tx_pos,'Velocity',tx_vel,...
    'OrientationAxesOutputPort',true); % generate tx class
tx = phased.Transmitter('PeakPower',1,'Gain',25); % generate tx

tx_pos_2 = [0;1;1]; % on the desk
tx_vel_2 = [0;0;0]; % fixed
radar_tx_2 = phased.Platform('InitialPosition',tx_pos_2,'Velocity',tx_vel_2,...
    'OrientationAxesOutputPort',true); % generate tx class

% area of interest 
% yLocLimit = [-1,1];
% xLocLimit = [1,4];
% ped_pos = [xLocLimit(1) + (xLocLimit(2)-xLocLimit(1))*rand;
%             yLocLimit(1) + (yLocLimit(2)-yLocLimit(1))*rand;
%             0]; % initial location
ped_pos = [3.2;-1;0]; % the person is 3 meters away

% ped_vel = [0;1;0]; % the walking speed is 1m/s
ped_height = 1.8; % the person's height
ped_speed = ped_height/2; % speed in U[0,1.4*height] m/s
% ped_heading = -180 + 360*rand; % heading in U[-180,180] degrees
ped_heading = 0;
ped = phased.BackscatterPedestrian('InitialPosition',ped_pos,'InitialHeading',ped_heading,...
    'PropagationSpeed',c,'OperatingFrequency',fc,'Height',ped_height,'WalkingSpeed',ped_speed); % generate the person


chan_ped = phased.FreeSpace('PropagationSpeed',c,'OperatingFrequency',fc,...
    'TwoWayPropagation',true,'SampleRate',fs); % generate free space channel

tx = phased.Transmitter('PeakPower',1,'Gain',25); % generate tx
rx = phased.ReceiverPreamp('Gain',25,'NoiseFigure',10); % generate rx

xr = complex(zeros(round(fs*tm),npulse));
xr_ped_perfect = complex(zeros(round(fs*tm),npulse));


for m = 1:npulse

    [pos_tx, vel_tx, ax_ego] = radar_tx(Tsamp); % tx position, velocity, and angle
    [pos_tx_2, vel_tx_2, ax_ego_2] = radar_tx_2(Tsamp);
    
    [pos_ped, vel_ped, ax_ped] = move(ped,Tsamp,ped_heading); % the person moves  
    
    [~,angrt_ped] = rangeangle(pos_tx,pos_ped(:,1),ax_ped(:,:,1)); % compute the reflection angle
    angrt_ped = repmat(angrt_ped, [1,16]); % reshape
    x = tx(wav()); % generate the tx signal
    
    % person
    xt_ped = chan_ped(repmat(x,1,size(pos_ped,2)),pos_tx,pos_ped,vel_tx,vel_ped); % channel to the person
    xt_ped = reflect(ped,xt_ped,angrt_ped); % reflection from the person
    xr_ped_perfect(:,m) = rx(xt_ped); % perfect case without the environment
end


%% Spectrogram
xd_ped_perfect = conj(dechirp(xr_ped_perfect,x)); % perfect case
[SPed,T,F] = helperDopplerSignatures(xd_ped_perfect,Tsamp);
figure
imagesc(T,F,SPed(:,:,1))
% ylabel('Frequency (Hz)')
% title('Pedestrian')
axis square xy
axis off
set(gca,'Units','normalized','Position',[0,0,1,1]);

toc


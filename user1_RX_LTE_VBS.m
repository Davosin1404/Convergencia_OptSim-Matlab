%____________________________________________________________________
%
%                    Custom Component for MATLAB
%          Automatically generated from VBS template
%
% Name         : user1_RX_LTE
% Author       : LFT
% Cration Date : Thu Aug 20 19:37:20 2020
%
%____________________________________________________________________
%
%                  MATLAB base workspace variables
%
% - Simulation parameters
%
% sim_technique ::= 'VBS'
%   current simulation technique ('SPT'|'VBSp'|'VBS')
%
% runs :: double vector [runs_num 1]
%   run(s) of the current CCM instance execution
%
% lower_frequency :: double number
%   VBS lower bandwidth frequency expressed in THz
%
% center_frequency :: double number
%   VBS center bandwidth frequency expressed in THz
%
% upper_frequency :: double number
%   VBS upper bandwidth frequency expressed in THz
%
% is_opt_noise :: double number
%   flag indicating if the optical noise is simulated
%
% is_elt_noise :: double number
%   flag indicating if the electrical noise is simulated
%
% polarization_mode :: double number
%   polarization representation of the optical field
%   (1 = signal, 2 = double)
%
% start_valid_samples :: double number
%   instant when a measurement component should start measuring
%   expressed in ps
%
% stop_valid_samples :: double number
%   instant when a measurement component should stop measuring
%   expressed in ps
%
% delt_ps :: double number
%   time sampling step expressed in ps
%
% num_samples :: double number
%   number of signal samples in time domain
%
% time :: double vector [num_samples 1]
%   time sample values expressed in ps
%
% - Input signals
%
% IN_LTE :: double vector [num_samples 1]
%   electrical signal IN_LTE time domain samples
%
%
%
%
%____________________________________________________________________

% Write MATLAB code here

save parametrosLTE_rx.mat

%% Recepci�n OFDM en canal con y sin ruido

% clc;
% clear all;
cd
folder = cd('C:\Users\ALUMNO\Desktop\LTEE-20231003T194117Z-001\LTEE\xv_sim_senal_LTEE'); 

rx_data = IN_LTE;
% rx_data = (rx_data + 000002);
% n = 126000; % n�mero de bits126000
Tm = 1; % 1-->QAM, 2--->PSK, 3--->OOK
M = 4; % n�mero de niveles para OOK M=66

%% Datos generales de transmisi�n OFDM

Nda = 63;         % N�mero de portadoras de datos
PC = 0;           % 0--sin prefijo c�clico, 1-->con prefijo c�clico,
CP = 0.25;        % tama�o del prefijo c�clico-->25%=0.25
size_fft = 8192;

%% Receptor OFDM

% [simbolos_rx] = OFDMA_RX; % SINCRONIZACION Y ELIMINACION DEL PRBS

% rx_data = load('OFDM_4qam_tx.txt'); % *****CARGAR AQUI LA se�al OFDM a decodificar**** rx_data2
% load('filtro03125_0625.mat') %-- cargar aqui el filtro
% rx_data = filter(Hd, rx_data2);
% size(rx_data)
% Synchronization

ref_signal = zeros(length(rx_data), 1);

xprbs = PRBS([1 0 1 1 0 1 1], [7 6]);      % generador PRBS 7 para sincronismo
sync1 = [0 xprbs];                        % generacion de la trama de sincronizaci�n [0+PBRS] 
% sync1 = [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 0 0 0 0 1 1 1 1 0 0 0 0]
% % sync1 = 2*sync1 -1;
% sync = zeros(1,256);
% sync(1:length(sync1)) = sync1;
ref_signal(1:length(sync1)) = sync1';
rect_rx_data = rx_data - mean(rx_data);

Y1 = fft(rect_rx_data);
Y2 = fft(ref_signal);
Y = ifft(Y1.*conj(Y2));
[max1, nmax1] = max(abs(Y(1:(length(Y)/2))));       % elegimos el punto del sincronismo
% [max1, nmax1] = max(abs(Y(1:(length(Y)))));
% size(rx_data)
rx_data_sync = circshift(rx_data, [-nmax1+1 0]);    % ordenamos los datos tx para colocar PRBS+symOFDM
% rx_data_sync = rx_data_sync(1:2^17);
% Resize for decoding
PRBSrx = rx_data_sync(1:128);                         % PRBS recibido
data_OFDM1 = rx_data_sync(length(sync1)+1:length(rx_data_sync));% eliminacion del PRBS
% data_OFDM = data_OFDM1(1:length(data_OFDM1));     % elegimos un s�mbolo OFDM
data_OFDM = data_OFDM1(1:(8192000));                   % elegimos un s�mbolo OFDM%data_OFDM = data_OFDM1(1:128000);% elegimos un s�mbolo OFDM

rows = size_fft;
cols = floor(length(data_OFDM) / rows);
size(data_OFDM);
data_OFDM2 = data_OFDM(1:rows*cols, 1);
size(data_OFDM2);
data_OFDM3 = reshape(data_OFDM2, rows, cols);
size(data_OFDM3);                                   % 256 1000
% Decode with Fourier transform
data_dec = fft(data_OFDM3, size_fft);               % obtenemos los s�mbolos mediante la FFT
data_rec = data_dec(2:64, :);                          % elegimos solo los 127 s�mbolos que generamos ya que es OFDM herm�tica
sym_rx = reshape(data_rec, 1, 63000);                   % Cadena de s�mbolos de datos recibidos
% ruido para verificar si funciona el programa
% y = reshape(data_rec, 1, 63000); % Cadena de s�mbolos de datos recibidos
% sym_rx = awgn(y, 9, 'measured');

n = 32;                                               % n�mero de s�mbolos a usar para ecualizar
[sym_eq] = EQUALIZACION(sym_rx, n);                    % ecualizaci�n de s�mbolos

% Yp se�ales pilotos Ytra se�al tranning
[datarx] = demdigital(sym_eq, Tm, M);                 % DEMODULACION digital
fileID1 = fopen('datarx.txt', 'w');
fprintf(fileID1, '%6f\n', datarx);                    % 6f\r\n 
fclose(fileID1);
% load('filtro03125_0313.mat') %-- cargar aqui el filtro
% rx_dat = filter(Hd, datarx);
% % espectro receptor
% x = rx_dat; % se�al a graficar
% fs = 1.25e9; % frecuencia de muestreo
% R = 1; % impedancia de entrada
% [Spdx, f] = psd_signal(x, fs, R); % grafica la Power Spectrum Density (PSD87

%% Datos Receptor OFDM

load('datostx.txt');
% size datostx.txt;
load('datarx.txt');
% size datarx.txt;
Bittx = fscanf(fopen('datostx.txt', 'r'), '%f');    % bit  n�mero de errores
Bitrx = fscanf(fopen('datarx.txt', 'r'), '%f');     % bit transmitidos


%% C�lculo del error

% sin ruido
% BER
errores = xor(Bittx, Bitrx);
Nerror = sum(errores);
BER = Nerror / (length(Bittx));  %% bit  n�mero de errores/%% bit recibidos

fileID2 = fopen('BER_LTE.txt', 'w');
fprintf(fileID2, '%6f\n', BER);% 6f\r\n 
fclose(fileID2);

%% C�lculo EVM
BitsporSubportadora = 2; % N�mero de bits por subportadora, modulaci�n M-QAM. 2: 4QAM, 4: 16QAM, 6: 64QAM, 8: 256QAM 
EVM_RMS = comm.EVM; % Creaci�n del objeto comm.EVM
EVM_RMS.ReferenceSignalSource = "Estimated from reference constellation"; % Definici�n del diagrama de constelaci�n de referencia
EVM_RMS.ReferenceConstellation = qammod(0:2^BitsporSubportadora-1, 2^BitsporSubportadora, 'UnitAveragePower', true); % Diagrama de constelaci�n de referencia con 2^BitsporSubportadora estados
EVM1 = EVM_RMS(sym_eq'./abs(sym_eq')); % C�lculo del EVM de los s�mbolos de recepci�n
EVM_VALOR = num2str(EVM1);

save('%Ubicacion de la carpeta%\LTEE\user1_RX_LTE\datosRx.mat') % Registro del workspace

%____________________________________________________________________
%
% End of file
%____________________________________________________________________

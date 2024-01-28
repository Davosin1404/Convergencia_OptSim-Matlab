%____________________________________________________________________
%
%                    Custom Component for MATLAB
%          Automatically generated from VBS template
%
% Name         : user1_TX_LTE
% Author       : LFT
% Cration Date : Thu Aug 20 19:35:44 2020
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
%
% - Output signals
%
% OUT_LTE :: double vector [num_samples 1]
%   electrical signal OUT_LTE time domain samples
%
%
%
%____________________________________________________________________

% Write MATLAB code here

% % Generación de bits aleatorios
% [datos] = generarBits(n);    % Generador de bits aleatorios
% fileID1 = fopen('%ubicacion de la carpeta%\LTEE\xv_sim_senal_LTEE\datostx.txt', 'w'); % Abre un archivo para guardar los datos
% fprintf(fileID1, '%6f\n', datos);     % Escribe los bits en el archivo
% fclose(fileID1);                     % Cierra el archivo

n = 126000; % número de bits126000
Tm = 1; % 1-->QAM, 2--->PSK, 3--->OOK
M = 4; % número de niveles para OOK M=2
%------------------------------------------------------------------------
% Datos generales de transmisión OFDM
%------------------------------------------------------------------------
Nc = 128; % Número de puntos de la IFFT
Nda = 63; % Número de portadoras de datos%63
PC = 0; % 0--sin prefijo cíclico, 1-->con prefijo cíclico,
CP = 0.25; % tamaño del prefijo cíclico-->25%=0.25

%-------------------------------------------------------------------------
% Transmisor OFDM
%-------------------------------------------------------------------------
[datos] = generarBits(n); % generador de bits aleatorios
%-------------------------------------------------------------------------
[X] = moduladorDigital(datos, Tm, M); % modulador de símbolos (M-PSK,M-QAM) aleatorios % muestra el PBRS
fileID1 = fopen('simbolostx.txt', 'w');
fprintf(fileID1, '%6f\n', X); %6f\r\n 
fclose(fileID1);
% scatterplot(X); % gráfica de constelaciones
[y, NT, NsymT] = modemOFDM(X, Nc, Nda, CP, PC); % FILTRO generador de señal OFDM-->SEÑAL CON PBRS
% fileID2 = fopen('OFDM_4qam_tx.txt','w');
% fprintf(fileID2,'%6f\n',y);%6f\r\n 
% fclose(fileID2);
% load('filtro40Ghz_03125_03223.mat')%-- cargar aqui el filtro
% rx_data=filter(Hd,y);
% 
% 
% % figure(2)
% plot(rx_data)
% title('señal OFDM')
% xlabel('Tiempo (seg)')
% ylabel('Potencia (dBm)')
% hold on
% % 
% %espectro transmisors
% x=y;%señal a graficar
% fs=40e9;% frecuencia de muestreo
% R=1;% impedancia de entrada
% [Spdx,f] = psd_signal(x,fs,R); %grafica la Power Spectrum Density (PSD87
OUT_LTE = y';

save parametrosLTE_tx.mat

%____________________________________________________________________
%
% End of file
%____________________________________________________________________

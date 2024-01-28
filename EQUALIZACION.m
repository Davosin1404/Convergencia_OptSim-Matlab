%% EQUALIZACION OFDM

function [simbolos_eq] = EQUALIZACION(sym_rx,n)
%sym =  numero de simbolos  a ecualizar
%n=    numero de simbolos a usar para ecualizar
load ('simbolostx.mat');% simbolos que se transmitieron

simbolos_tx=X.';
symeq=simbolos_tx(1:63*n);       % simbolos transmitidos a usar para ecualizar
symeq2=reshape(symeq,63,n);     % formacion de los simbolos OFDM que se transmitieron (en columnas)
symeq3=sym_rx(1:63*n);          % simbolos recibidos a usar para ecualizar
symeq4=reshape(symeq3,63,n);    % formacion de los simbolos OFDM que se recibieron (en columnas)
heq=symeq4./symeq2;             % obtencion del canal H
simbolos_rx2 = reshape(sym_rx, 63, 1000);
heq3 = smooth(sum(heq,2)/n);    % promedia y suaviza cada uno de los ecualizadores por portadora
simbolos_eq = ((1./heq3) * ones(1,1000)) .* simbolos_rx2;   % multiplica a todos los simbolos recibidos
simbolos_eq = reshape(simbolos_eq, 1, 63*1000);             % grafica de los simbolos equalizados

end
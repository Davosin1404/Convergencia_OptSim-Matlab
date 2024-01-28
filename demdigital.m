%% Demodulador Digital OOK  M-PSK  M-QAM

%Tm=tipo de modulacion: 1-QAM y 2-PSK
%M=numero de niveles

function [datarx] = demdigital(Y,Tm,M)

%Casos para tipo de modulación
switch Tm
    case 1
    %Demodulacion QAM
    dem_data= qamdemod(Y,M);            %obtenemos los simbolos
    % bin=de2bi(dem_data','left-msb');    %obtemenos los bits de cada simbolo
    bin=int2bit(dem_data',log2(M),'left-msb');
    dataTrx=bin';                       %transpuesta obtenemos  los bits en cada columna
    datarx=reshape(dataTrx,1,size(dataTrx,1)*size(dataTrx,2));  %ordenamos los datos serialmente
    
    case 2
    %Demodulacion PSK
    dem_data= pskdemod(Y,M);            %obtenemos los simbolos
    bin=de2bi(dem_data','left-msb');    %obtemenos los bits de cada simbolo
    dataTrx=bin';                       %transpuesta obtenemos  los bits en cada columna
    datarx=reshape(dataTrx,1,size(dataTrx,1)*size(dataTrx,2));  %ordenamos los datos serialmente
    
    %demodulacion OOK
    otherwise
    datarx=Y;
end

end

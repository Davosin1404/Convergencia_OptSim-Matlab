%% Modulador OOK M-PSK y M-QAM 

%Tm=tipo de modulacion: 1-QAM y 2-PSK
%M=numero de niveles
function [X] = moddigital(datos,Tm,M)
nb=log2(M);                 %numero de bits del simbolo
nc=fix(size(datos,2)/nb);   %numero de columnas
xm= reshape(datos,nb,nc);   %matriz [nb x nc]

%Casos para tipo de modulación
switch Tm
    case 1
    %Modulacion QAM
    dec=bi2de(xm','left-msb');
    y = qammod(dec,M);
    X=y.';
    
    case 2
    %Modulacion PSK
    dec=bi2de(xm','left-msb');
    y = pskmod(dec,M);
    X=y.';

    %Modulacion OOK
    otherwise
    X=datos;
    figure
end

end

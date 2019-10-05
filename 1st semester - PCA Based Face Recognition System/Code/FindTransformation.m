function [A,b] = FindTransformation(Fin,Fref)
    
    Ain = [Fin, ones(5,1)];
    b1 = Fref(:,1);
    b2 = Fref(:,2);
    
%     xtrue1 = A\b1;
    [U,S,V] = svd(Ain);
    sv = find(S);

    c = U'*b1;
    for i = 1:length(sv)
        y(i) = c(i)/S(i,i);
    end
    y = y';
    x1 = V*y;
    
%     xtrue2 = A\b2;
    c2 = U'*b2;
    for i = 1:length(sv)
        y2(i) = c2(i)/S(i,i);
    end
    y2 = y2';
    x2 = V*y2;

    A = [x1(1),x1(2);x2(1),x2(2)];
    b = [x1(3);x2(3)];
    
end
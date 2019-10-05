 function faces = NormalizeFaces(data)
%%
    Finit = data.features(1);
    Favg = round(cell2mat(Finit));
    Fpre = [13,20;50,20;34,34;16,50;48,50];
    count = 0;
    while(1)
        [A,b] = FindTransformation(Favg,Fpre);
        Fout = ApplyTransfomration(A,b,Favg);
        Favg = Fout;
        for i = 1: length(data.features)
            Fi = data.features(i);
            Fi = round(cell2mat(Fi));
            [A,b] = FindTransformation(Fi,Favg);
            Fout = ApplyTransfomration(A,b,Fi);
            Fall(:,:,i) = Fout;
        end
        %%
        F = mean(Fall,3);
        e = abs(F - Favg);
        thresh = 0.9 * ones(size(F));
        if (e<thresh)
            break;
        end
        if count >= 10
            break;
        end
        Favg = F;
        count = count + 1;
    end
    %%
    Ismall = zeros(64,64,length(data.features));
    for k = 1:length(data.features)

        Fi = data.features(k);
        Ii = cell2mat(data.faces(k));
        Ii = rgb2gray(Ii);
        m = size(Ii,1);
        n = size(Ii,2);
        Fi = round(cell2mat(Fi));
        [A,b] = FindTransformation(Fi,F);
    %     Ismall = zeros(64,64);
        Ainv = inv(A);
        for i = 1:size(Ismall,1)
            for j = 1:size(Ismall,2)

                inxy = [j;i];
                outxy = Ainv * ( inxy - b);
                outxy = round(outxy);
                if (outxy(1) > 1 && outxy(1) <= n && outxy(2) > 1 && outxy(2) <= m)
                    Ismall(i,j,k) = Ii(outxy(2),outxy(1));
                end

            end
        end
    end
    
    %%
    % deleting unfixed outliers from dataset
%     Ismall(:,:,96) = []; % prem
%     data.faces(96) = [];
%     data.features(96) = [];
%     data.name(96) = [];
%     Ismall(:,:,116) = []; % keven
%     data.faces(116) = [];
%     data.features(116) = [];
%     data.name(116) = [];
%     Ismall(:,:,117) = []; % keven
%     data.faces(117) = [];
%     data.features(117) = [];
%     data.name(117) = [];
%     Ismall(:,:,157) = []; % zakia
%     data.faces(157) = [];
%     data.features(157) = [];
%     data.name(157) = [];
%     Ismall(:,:,158) = []; % zakia
%     data.faces(158) = [];
%     data.features(158) = [];
%     data.name(158) = [];
    % show the images
    for i = 1:size(Ismall,3)
        Ii = cell2mat(data.faces(i));
        Ii = rgb2gray(Ii);
        subplot(121),imshow(Ii,[])
        subplot(122),imshow(Ismall(:,:,i),[])
        drawnow;
    end
    % inspecting outliers
    Ir = cell2mat(data.faces(1));
    fr = cell2mat(data.features(1));
    Is = cell2mat(data.faces(96));
    fs = cell2mat(data.features(96));
    % figure,subplot(121),imshow(Ir)
    % subplot(122),imshow(Is)
    figure,imshow(Is,[])
    hold on
    plot(fs(:,1),fs(:,2),'*b')
    hold off
    figure,imshow(Ismall(:,:,96),[])
faces = Ismall;
end


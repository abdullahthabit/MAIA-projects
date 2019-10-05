function training = PCArecognition(trainData,k)

D = zeros(length(trainData.faces),64*64);
p = length(trainData.faces);
for i = 1:p
   
    face = trainData.faces{i};
    face = face';
    columnFace = face(:)';
    % creating the data matrix
    D(i,:) = columnFace;
    name = trainData.name{i};
    % creating a label matrix
    L{i} = name;
end
% calculating the mean
Dmean = mean(D);
Dc = zeros(size(D));
for i = 1:size(D,2)
   
    Dc(:,i) = D(:,i) - (Dmean(i)*ones(size(D,1),1));
end

Cov = (1/p-1)*(Dc * Dc');

[V,Dev] = eig(Cov);

Vsorted = V;

projM = Vsorted(:,1:k);
projMreduced = D' * projM;

for i=1:k
    projMreduced(:,i)=projMreduced(:,i)/norm(projMreduced(:,i));
end

Ft = D * projMreduced;

training.features = Ft;
training.lables = L;
training.projecM = projMreduced;


end
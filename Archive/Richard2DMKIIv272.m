function [  ] = Richard2DMKIIv272()
% 2D Richards equation with constant boundary condition 
% H based Richards equation
% 
% !!!!TODO. NOT FINISHED!!!!
%
% First edition: Weix 20/04/2017 
%
% point type N: normal (N is natural number)
%  		  	 0: Dirichlet BC
%		  	 -N: Neuman BC 
%
% Version IV: 
%
% Version 1.40 : Weix 12/04/2017 
% improve the flexibilities (for different BC and domain) by
% introducing the indexMatrix and use 0 to indicate D-BC.
% Version 1.50 : Weix 13/04/2017 
% Vectorization
% Version 2.70: 24/04/2017 
% add Updata Neumann boundary condition. Update the way points are
% accessed. (see Richard1Dv27 for more history)
% Version 2.72: 25/04/2017 improve organization
% Version 2.72 MKII: change the way node are accessed. (treat inner point
% and boundary seperately. BC are implemented in codes not input)

%%
tic
% Spatial setup
lengthZ=40;
deltaZ=2;
nZ=lengthZ/deltaZ+1;

lengthX=40;
deltaX=2;
nX=lengthX/deltaX+1;

% Temporal setup
lengthTime=300;
deltaTime=1;
nTime=lengthTime/deltaTime;

% Iteration setup
nMaxIteration=1000;
miniIteError=0.1;

% Mesh
[X,Z] = meshgrid(0:deltaX:lengthX,0:deltaZ:lengthZ);

% Permeability field
Ks=permeabilityField([Z(:),X(:)])*0.01;
Ks=reshape(Ks,nZ,nX);

%plot permeability field
% pcolor(X,Z,Ks)
% shading interp;
% colormap jet;

% Option 1       
% Make nodeIndex matrix. It indicate the sequence nodes are accessed and the type of node.  
%     nodeIndex=zeros(nZ,nX);
%     nodeIndex(2:end-1,2:end-1)=reshape(uint32(1:(nZ-2)*(nX-2)), (nZ-2), (nX-2));    
% 
%     nodeInFieldIndex=find(nodeIndex);
% 
%     %%% 
%     %initial state
%     H_init=zeros(nZ,nX);
%     H_init(2:end-1,2:end-1)=-61.5;
% 
%     %BC
%     % bcLeft=ones(nNodeZ,1)*-20.7;
%     % bcRight=ones(nNodeZ,1)*-61.5;
%     % bcTop=ones(nNodeX,1)*-20.7;
%     % bcBottom=ones(nNodeX,1)*-61.5;
% 
% 
%         % A more interesting setup
%         bcLeft=ones(nZ,1)*-20.7;
%         bcRight=ones(nZ,1)*-20.7;
%         bcTop=ones(nX,1)*-20.7;
%         bcBottom=ones(nX,1)*-24.7;
% 
% 
%     H_init(1,1:end)=bcTop;
%     H_init(end,1:end)=bcBottom;
% 
%     H_init(1:end,1)=bcLeft;
%     H_init(1:end,end)=bcRight;

% Option 2 Neumann BC on left and right 
    nodeIndex=zeros(nZ,nX);
    nodeIndex(2:end-1,1:end)=reshape(uint32(1:(nZ-2)*(nX)), (nZ-2), (nX));  
    
    nodeInFieldIndex=find(nodeIndex);

    nodeIndex(:,1)=-nodeIndex(:,1);
    nodeIndex(:,end)=-nodeIndex(:,end);
    
    H_init=ones(nZ,nX)*-61.5;
%     H_init(2:end-1,2:end-1)=-61.5;
    H_init(1,1:end)=ones(nX,1)*-20.7;
    H_init(end,1:end)=ones(nX,1)*-24.7;

%% MAIN
nNode=length(nodeIndex(nodeIndex~=0));

H=H_init;
for t=1:nTime
      
    H_PreviousTime= H;
    for k=1:nMaxIteration 
        
        H0=H;
        
        [A,B] = PicardFdm(H_PreviousTime);
        hFree=A\(-B);
                
%         H(find(nodeIndex))=hFree;       %pay extra attention to ordering
        H(nodeInFieldIndex)=hFree; 
        
        sseIte=sum((H(:)-H0(:)).^2);
        if sqrt(sseIte)<miniIteError 
            break 
        end
        
    end
    
    TheataRecord(:,:,t)=H;

end


toc
    
figure(1)
pcolor(X,Z,Ks)
shading interp;
colormap jet;

figure(2)
surf(X,Z,TheataRecord(:,:,end))
shading interp;
colormap jet;


figure(3)
surf(H_init);

for t=1:nTime
    surf(X,Z,TheataRecord(:,:,t))
%     shading interp;
    title(sprintf('time=%i',t))
    drawnow
    frame(t)=getframe;
    
end





% Ax+b=0 function Nest function to avoild passing many variables

    function [A,B] = PicardFdm(Value_PreviousTime)
        
        index=1;

        A=speye(length(nNode));
        B=zeros(length(nNode),1);
        
        C=theataDifFunc(H);
%         K=kFunc(H);
        K=kFieldFunc(H,Ks);

        % for all inner node (none-bc node) 
        % This part could be easily vectorize
        for iZ=2:nZ-1
            for iX=2:nX-1        
                
                indexCenter=nodeIndex(iZ,iX);                
                indexUp=nodeIndex(iZ-1,iX);
                indexDown=nodeIndex(iZ+1,iX);
                indexLeft=nodeIndex(iZ,iX-1);
                indexRight=nodeIndex(iZ,iX+1);

                hUp=H(iZ-1,iX);
                hDown=H(iZ+1,iX);
                hLeft=H(iZ,iX-1);
                hRight=H(iZ,iX+1);

                kHalfUp   =(K(iZ,iX)+K(iZ-1,iX))/2;
                kHalfDown =(K(iZ,iX)+K(iZ+1,iX))/2;
                kHalfLeft =(K(iZ,iX)+K(iZ,iX-1))/2;
                kHalfRight=(K(iZ,iX)+K(iZ,iX+1))/2;

                cCenter=C(iZ,1);   
                
                wUp   = -kHalfUp  ./deltaZ^2;
                wDown = -kHalfDown./deltaZ^2;
                wLeft = -kHalfLeft./deltaX^2;
                wRight= -kHalfRight./deltaX^2;

                wCenter=cCenter/deltaTime-wUp-wDown-wLeft-wRight;

                b=(kHalfDown-kHalfUp)/deltaZ-H_PreviousTime(iZ,iX)*cCenter/deltaTime;

                %modify if neighbours are DBC points           
                b=b + wUp * hUp * ~indexUp...
                    + +wDown * hDown * ~indexDown...
                    + +wLeft * hLeft * ~indexLeft...
                    + +wRight * hRight * ~indexRight;

                indexUp=abs(indexUp);
                indexDown=abs(indexDown);
                indexLeft=abs(indexLeft);
                indexRight=abs(indexRight);
                indexCenter=abs(indexCenter);

                if indexUp>0 A(indexCenter,indexUp)=wUp; end
                if indexDown>0 A(indexCenter,indexDown)=wDown; end
                if indexLeft>0 A(indexCenter,indexLeft)=wLeft; end
                if indexRight>0 A(indexCenter,indexRight)=wRight; end

                A(indexCenter,indexCenter)=wCenter;
                B(indexCenter,1)=b;
                   
            end
        end
        
        
        
        
        
        
        
        
        
        
        
    end

end 



function theata=theataFunc(H)
theataS=0.287;
theataR=0.075;
alpha=1.611e6;
beta=3.96;

result=alpha.*(theataS-theataR)/(alpha+abs(H).^beta)+theataR;
end

function theataDif=theataDifFunc(H)
theata_s=0.287;
theata_r=0.075;
alpha=1.611e6;
beta=3.96;

theataDif=-alpha.*(theata_s-theata_r).*-1.*(alpha+abs(H).^beta).^(-2).*abs(H).^(beta-1);

end

function result=kFunc(H)
rho=1.175e6;
r=4.74;
k_s=0.00944;

result=k_s.*rho./(rho+abs(H).^r);
end

function result=kFieldFunc(H,ks)
% H and k must be the same sizes
rho=1.175e6;
r=4.74;

result=ks.*rho./(rho+abs(H).^r);
end




function Ks=permeabilityField(X)
% pointCoordinate=[X(:),Z(:)];
lenscale=10; %larger number means less stochastic field. Thus less smooth.
[nX,dimX]=size(X);

%calculate distance matrix
distance = pdist(X);
distanceMatrix = squareform(distance);

%calculate covariance matrix
covMatrix=exp(-distanceMatrix./lenscale);    

% KL decomposition on covariance matrix via SVD/eigen decomposition
% [klBasis,klEigenValue] = eigs(covMatrix,nY*nX); 
[klBasis,klEigenValue,~] = svds(covMatrix,nX); 


% [nKlBasis,~]=sizes(klBasis);


%Generate independent normal samples 
seed=100;
rng(seed);
sample= randn(nX,1);

%make multivariate Gaussian distributions with samples. zero mean.
%Covariance specified though KL basis.
Ks=klBasis*sqrt(klEigenValue)*sample;
% Ks=reshape(Ks,nY,nX);

% a log (multi) normal permeability field
Ks=exp(Ks);

end


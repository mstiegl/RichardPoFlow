function [  ] = Solver2D_MKVI()
% 2D Richards equation with constant boundary condition 
% h based Richards equation
%
% Version VI: 
%
% Version 1.40 : Weix 12/04/2017 
% improve the flexibilities (for different BC and domain) by
% introducing the indexMatrix and use 0 to indicate D-BC.
% Version 1.50 : Weix 13/04/2017 
% Vectorization
% Version 1.60 : Weix 14/04/2017 
% Vectorization and use Nested functions
%%
tic
% nNode=10;
% nTime=100;

% Spatial setup
lengthZ=40;
deltaZ=2;
nNodeZ=lengthZ/deltaZ-1;

lengthX=40;
deltaX=4;
nNodeX=lengthX/deltaX-1;

% Temporal setup
lengthTime=300;
deltaTime=1;
nTime=lengthTime/deltaTime;

% Iteration setup
nMaxIteration=1000;
miniIteError=0.1;


% Mesh
[X,Z] = meshgrid(0:deltaX:lengthX,0:deltaZ:lengthZ);
Ks=permeabilityField(X,Z);


% integer shows unknowns and 0 shows DBC
nUnknown=nNodeZ*nNodeX;
indexMatrix=zeros(nNodeZ+2, nNodeX+2);
indexMatrix(2:end-1,2:end-1)=reshape(uint32(1:nUnknown), (nNodeZ), (nNodeX));

% indexUnknown = reshape(uint32(1:nUnknown), (nNodeZ-2), (nNodeX-2));

% indexMatrix=zeros(nNodeZ, nNodeX);
% indexMatrix(2:end-1,2:end-1)=indexUnknown;



H=zeros(nNodeZ,nNodeX);
% H_temp=zeros(nNode,nMaxIteration);

%%% 
%initial state
H_init=zeros(nNodeZ,nNodeX);
H_init(:)=-61.5;

%BC
bcLeft=ones(nNodeZ,1)*-20.7;
bcRight=ones(nNodeZ,1)*-61.5;
bcTop=ones(nNodeX,1)*-20.7;
bcBottom=ones(nNodeX,1)*-61.5;


    % A more interesting setup
    bcLeft=ones(nNodeZ,1)*-20.7;
    bcRight=ones(nNodeZ,1)*-20.7;
    bcTop=ones(nNodeX,1)*-20.7;
    bcBottom=ones(nNodeX,1)*-24.7;

    
    
H_all=zeros(nNodeZ+2,nNodeX+2);
H_all(1,2:end-1)=bcTop;
H_all(end,2:end-1)=bcBottom;

H_all(2:end-1,1)=bcLeft;
H_all(2:end-1,end)=bcRight;
H_all(2:end-1,2:end-1)=H_init;


% update BC to initial field
% H_init(:,1)=bcLeft;
% H_init(:,end)=bcRight;
% 
% H_init(end,:)=bcBottom;
% H_init(1,:)=bcTop;

%%
% indicate the BC points
temp=zeros(nNodeZ,nNodeX);
% temp(1,:)=1;
% ifTopDbc=temp(:);   %if top neighbour a constant B.C. 
temp(1,:)=bcTop;      %this structure might be convient but require storage
topDbcValue=temp(:);

temp=zeros(nNodeZ,nNodeX);
% temp(end,:)=1;
% ifBottomDbc=temp(:);   
temp(end,:)=bcBottom;
bottomDbcValue=temp(:);

temp=zeros(nNodeZ,nNodeX);
% temp(:,1)=1;
% ifLeftDbc=temp(:);  
temp(:,1)=bcLeft;
leftDbcValue=temp(:);

temp=zeros(nNodeZ,nNodeX);
% temp(:,end)=1;
% ifRightDbc=temp(:);   
temp(:,end)=bcRight;
rightDbcValue=temp(:);

%% Another way. We can just use self organize as this need only onces.
% TopDbcValue=[zeros(1, size(H_all,2)),H_all];




%% MAIN
TheataRecord(:,:,1)=H_init;
H=H_init;

% C=ones(nNodeZ,nNodeX)*1234567;

for t=1:nTime
    
    H_PreviousTime=H;
    for k=1:nMaxIteration 
            
        H0=H;
        [A,B]=axbPicard(H0,H_PreviousTime);
%         %% Assemble Ax+B=0 with New Vectorization 
%       
%         C_all=theataDifFunc(H_all);
%         C=C_all(2:end-1,2:end-1);
%         
%         K_all=kFunc(H_all);
%         K=K_all(2:end-1,2:end-1);
%         
%         zdiffK_all=diff(K_all,1,1);
%         xdiffK_all=diff(K_all,1,2);
%         
% %         zdiffC_all=diff(C_all,1,1);
% %         xdiffC_all=diff(C_all,1,2);
%         
%         
%         wUp   = -1./deltaZ^2 .* (K - zdiffK_all(1:end-1,2:end-1)./2);
%         wDown = -1./deltaZ^2 .* (K + zdiffK_all(2:end,  2:end-1)./2);
%         
%         wLeft = -1./deltaX^2 .* (K - xdiffK_all(2:end-1,1:end-1)./2);
%         wRight= -1./deltaX^2 .* (K + xdiffK_all(2:end-1,2:end)./2);
%         
%         wCenter=C./deltaTime-wUp-wDown-wLeft-wRight;
%         
%         b= (zdiffK_all(2:end, 2:end-1)+ zdiffK_all(1:end-1,2:end-1))./2 ./deltaZ ...
%            -H_PreviousTime .* C ./ deltaTime;
% 
%         %update BC neighbour                 
%         B= b(:) + wUp(:)   .*topDbcValue...
%                 + wDown(:) .*bottomDbcValue...
%                 + wLeft(:) .*leftDbcValue...
%                 + wRight(:).*rightDbcValue;    
%             
%         wUp    = wUp(:)   .* (topDbcValue==0); 
%         wDown  = wDown(:) .* (bottomDbcValue==0); 
%         wLeft  = wLeft(:) .* (leftDbcValue==0); 
%         wRight = wRight(:).* (rightDbcValue==0); 
%         wCenter=wCenter(:);
%         
%         A=  diag(wUp(2:end),1)+diag(wDown(1:end-1),-1)...
%             +diag(wLeft(nNodeZ+1:end),-nNodeZ)+diag(wRight(1:end-nNodeZ),nNodeZ)...       
%             +diag(wCenter,0);

        %% Solve linear equation
        h=A\(-B);         
        H=reshape(h,nNodeZ,nNodeX);

        %% Convergence
        sseIte=sum((H(:)-H0(:)).^2);
        if sqrt(sseIte)<miniIteError 
            break 
        end
        
    end

    TheataRecord(:,:,t)=H;
    
end
    
toc
    
figure(1)
surf(H_init);

for t=1:nTime
    surf(TheataRecord(:,:,t))
    title(sprintf('time=%i',t))
    drawnow
    frame(t)=getframe;
    
end
    

    
    function [A,B]=axbPicard(H,H_PreviousTime)
    %% Assemble Ax+B=0 with New Vectorization 
%         H0=H;
        H_all(2:end-1,2:end-1)=H;
        
        C_all=theataDifFunc(H_all);
        C=C_all(2:end-1,2:end-1);
        
        K_all=kFunc(H_all);       %Uniform approximated permeability
        K_all=kFieldFunc(H_all,Ks);
        
        K=K_all(2:end-1,2:end-1);
        
        zdiffK_all=diff(K_all,1,1);
        xdiffK_all=diff(K_all,1,2);
            
        wUp   = -1./deltaZ^2 .* (K - zdiffK_all(1:end-1,2:end-1)./2);
        wDown = -1./deltaZ^2 .* (K + zdiffK_all(2:end,  2:end-1)./2);
        
        wLeft = -1./deltaX^2 .* (K - xdiffK_all(2:end-1,1:end-1)./2);
        wRight= -1./deltaX^2 .* (K + xdiffK_all(2:end-1,2:end)./2);
        
        wCenter=C./deltaTime-wUp-wDown-wLeft-wRight;
        
        b= (zdiffK_all(2:end, 2:end-1)+ zdiffK_all(1:end-1,2:end-1))./2 ./deltaZ ...
           -H_PreviousTime .* C ./ deltaTime;

        %update BC neighbour influence to Ax+B=0              
        B= b(:) + wUp(:)   .*topDbcValue...
                + wDown(:) .*bottomDbcValue...
                + wLeft(:) .*leftDbcValue...
                + wRight(:).*rightDbcValue;    
            
        wUp    = wUp(:)   .* (topDbcValue==0); 
        wDown  = wDown(:) .* (bottomDbcValue==0); 
        wLeft  = wLeft(:) .* (leftDbcValue==0); 
        wRight = wRight(:).* (rightDbcValue==0); 
        wCenter=wCenter(:);
        
        %Way I. heavy time cost. Not sparse
%         A=  diag(wUp(2:end),1)+diag(wDown(1:end-1),-1)...
%             +diag(wLeft(nNodeZ+1:end),-nNodeZ)+diag(wRight(1:end-nNodeZ),nNodeZ)...       
%             +diag(wCenter,0);
%         A=sparse(A);
        
        %Way II.
        band=zeros(nNodeZ*nNodeX,5);
        band(1:end-nNodeZ,1)= wLeft(nNodeZ+1:end);
        band(1:end-1,2)= wDown(1:end-1);
        band(:,3)= wCenter;
        band(1+1:end,4)= wUp(1+1:end);
        band(1+nNodeZ:end,5)= wRight(1:end-nNodeZ);
        
        A = spdiags(band,[-nNodeZ,-1,0,1,nNodeZ],nNodeZ*nNodeX,nNodeZ*nNodeX);
%         %A=full(A);  %just to compare with Way I.
        
        
    end


end




function [k,j]=index2kj(index)
    
end


function theata=theataFunc(h)
theataS=0.287;
theataR=0.075;
alpha=1.611e6;
beta=3.96;

result=alpha.*(theataS-theataR)/(alpha+abs(h).^beta)+theataR;
end

function theataDif=theataDifFunc(h)
theata_s=0.287;
theata_r=0.075;
alpha=1.611e6;
beta=3.96;

theataDif=-alpha.*(theata_s-theata_r).*-1.*(alpha+abs(h).^beta).^(-2).*abs(h).^(beta-1);

end

function result=kFunc(h)
rho=1.175e6;
r=4.74;
k_s=0.00944;

result=k_s.*rho./(rho+abs(h).^r);
end


function result=kFieldFunc(h,k)
% h and k must be the same sizes
rho=1.175e6;
r=4.74;

result=k.*rho./(rho+abs(h).^r);
end


function Ks=permeabilityField(X,Z)
% pointCoordinate=[X(:),Z(:)];
lenscale=10;

[nY,nX]=size(X);

distance = pdist([X(:),Z(:)]);
distanceMatrix = squareform(distance);

covMatrix=exp(-distanceMatrix./lenscale);    

[klBasis,klEigenValue] = eigs(covMatrix,nY*nX); 

% [nKlBasis,~]=sizes(klBasis);

seed=100;
rng(seed);
sample= rand(nY*nX,1);


Ks=klBasis*sqrt(klEigenValue)*sample;
Ks=reshape(Ks,nY,nX);

end






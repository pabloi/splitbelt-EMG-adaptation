function [fh] = assessModel(model,trainingData,trainingU)

fh=figure('Name',model.name,'Units','Normalized','OuterPosition',[0 0 1 1]);
%Plot axes
M=11;
margin=1.1;
height=.97/(margin*4.2);
width=.97/(margin*M);

%Colormap:
ex1=[.85,0,.1];
ex2=[0,.1,.6];
map=[bsxfun(@plus,ex1,bsxfun(@times,1-ex1,[0:.01:1]'));bsxfun(@plus,ex2,bsxfun(@times,1-ex2,[1:-.01:0]'))].^.5;
colormap(flipud(map))
cl=1;

%
if size(trainingData,1)==2*size(model.C,1)
   bilatFlag=1;
   cl=.5;
else
    bilatFlag=0;
end
muscleList=fliplr({'TA','PER','MG','LG','SOL','SEMB','SEMT','BF','VM','VL','RF','HIP','ADM','TFL','GLU'});
%^This should be passed as an argument

if bilatFlag
   model.D=model.Da;
   model.C=model.Ca; %Could be Cp
   model.Ysim=model.YsimB;
   model.Yinf=zeros(size(model.D));
   muscleList=[strcat('F',muscleList) strcat('S',muscleList)];
end

%Plot model matrices C and D
postOffset=1099;
N=size(model.C,2);
[~,ind]=sort(diag(model.J),'ascend');
for i=1:N
   ax=axes();
   ax.Position=[(i+1)*margin*width+.03 margin*height*3+.05 width .8*height];
   imagesc(model.Xsim(ind(i),postOffset-1)*reshape(model.C(:,ind(i)),12,15*(bilatFlag+1))')
   %title(['C_' num2str(i) ', \tau = ' num2str(-1./log(model.J(ind(i),ind(i))),3)])
   caxis(cl*[-1 1])
   set(gca,'XTick','','YTick','')
   ax=axes();
   ax.Position=[(i+1)*margin*width+.03 margin*height*3.8+.05 width .25*height];
   plot(model.Xsim(ind(i),:)/model.Xsim(ind(i),postOffset-1),'LineWidth',3)
   axis tight
   set(gca,'XTick','','YTick','')
   text(400,.2,['\tau = ' num2str(round(-1./log(model.J(ind(i),ind(i)))*10)/10,3)],'FontWeight','bold')
end

%Add D:
ax=axes();
ax.Position=[margin*width+.03 margin*height*3+.05 width .8*height];
if ~all(model.D(:)==0)
    tit='D';
else %Models fitted to post-adapt data
    tit='D*';
    %model.D=nanmean((trainingData(:,trainingU~=0)-model.Ysim(:,trainingU~=0))./trainingU(trainingU~=0),2);
    adaptOffset=199;
    postOffset=1099;
    yA=trainingData(:,adaptOffset:postOffset-1);
    hatYA=model.Ysim(:,adaptOffset:postOffset-1);
    model.D=nanmean(yA-hatYA,2);
    model.Ysim=model.C*model.Xsim+model.D*trainingU;
end
imagesc(reshape(model.D,12,15*(bilatFlag+1))')
caxis(cl*[-1 1])
set(gca,'XTick','','YTick',1:length(muscleList),'YTickLabel',muscleList)
ax=axes();
ax.Position=[margin*width+.03 margin*height*3.8+.05 width .25*height];
plot(trainingU,'LineWidth',3)
hold on
text(400,.2,[tit ', \tau = 0'],'FontWeight','bold')
axis tight
set(gca,'XTick','','YTick','')

%Add Y_\infty
ax=axes();
ax.Position=[5*margin*width+.03 margin*height*3+.05 width .8*height];
imagesc(reshape(model.Yinf,12,15*(bilatFlag+1))')
title('Y_\infty ')
caxis(cl*[-1 1])
set(gca,'XTick','','YTick','')

%Add total change:
ax=axes();
ax.Position=[6*margin*width+.03 margin*height*3+.05 width .8*height];
imagesc(reshape(model.C * model.Xsim(:,postOffset-1),12,15*(bilatFlag+1))')
title('\Delta Y_{adapt}')
caxis(cl*[-1 1])
set(gca,'XTick','','YTick','')

%Add performance:
ax=axes();
ax.Position=[7*margin*width+.03 margin*height*3+.05 width+3*margin*width .8*height];
plot((model.Xsim./ model.Xsim(:,postOffset-1))','LineWidth',3)
hold on
set(ax,'ColorOrderIndex',1)
plot((trainingData-model.D*trainingU)'/(model.C' .* model.Xsim(:,postOffset-1)),'.')
%plot((model.Xproj./ model.Xsim(:,postOffset-1))','.')
%plot(sum((model.Ysim-trainingData).^2,1) ./nanmean(sum(trainingData.^2,1)),'k')
axis tight
set(gca,'XTick','','YTick','')

%Add data & simulation
auxStride=[1 4 10 85 40];
strideNo=[40 auxStride auxStride];
adaptOffset=199;
postOffset=1099;
MM=size(trainingData,2);
offset=[adaptOffset+[-45 0 1 5 15 855] postOffset+[0 1 5 15 (MM-postOffset)-44]];
normFactor=sqrt(nanmean(sum(trainingData(:,offset(1)+[0:strideNo(1)-1]).^2,1),2));
for i=1:length(strideNo)
    strides=offset(i)+[0:strideNo(i)-1];
    
    %Plot actual time-course
   ax=axes();
   ax.Position=[(i-1)*margin*width+.03 margin*height*2+.03 width height];
   imagesc(reshape(mean(trainingData(:,strides),2),12,15*(bilatFlag+1))')
   caxis(cl*[-1 1])
   set(gca,'XTick','')
   if i==1
       ylabel('Data')
   else
       set(gca,'YTick','')
   end
   switch i
       case 1
           title('baseline')
       case {2,3,4,5,6}
           title(['Adap ' num2str(strides(1)-adaptOffset+1) ':' num2str(strides(end)-adaptOffset+1) ])
       case {7,8,9,10,11}
           title(['Post ' num2str(strides(1)-postOffset+1) ':' num2str(strides(end)-postOffset +1)])
   end
   
   %Plot simulated time-course
   ax=axes();
   ax.Position=[(i-1)*margin*width+.03 margin*height+.03 width height];
   simData=model.Ysim;
   imagesc(reshape(mean(simData(:,strides),2),12,15*(bilatFlag+1))')
   caxis(cl*[-1 1])
   set(gca,'XTick','')
   if i==1
   ylabel(['Simulation'])
   else
       set(gca,'YTick','')
   end
   res=sqrt(nanmean(sum((simData(:,strides)-trainingData(:,strides)).^2,1),2));
   text(4,0,['e = ' num2str(round(100*res/normFactor)/100)],'FontSize',8,'Clipping','off','FontWeight','bold')
   
   %PLot residuals:
   ax=axes();
   ax.Position=[(i-1)*margin*width+.03 .03 width height];
   imagesc(reshape(mean(simData(:,strides)-trainingData(:,strides),2),12,15*(bilatFlag+1))')
   caxis(cl*[-1 1])
   if i==1
   ylabel(['residual'])
   else
       set(gca,'YTick','')
   end
end





end

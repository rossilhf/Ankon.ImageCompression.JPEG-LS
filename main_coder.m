% 第一种方式，比如240*240,先分6块，就是40*240,按4颜色分量，每块就是20*120
% 
% 
% 第二种是直接把240*240，分4颜色分量，就是120*120为一个最小单元来处理。
% 

% 第三种，就是把240*240，作为一个最小单元来处理。但是在每一行内部，会进行一些位置的调整，把相同颜色靠拢。在行与行之间，也会进行一些调整。
% 具体的调整，之前的任务安排中已经讲了
% bayer rgb,经过3的处理后，变成
% ggggrrrr
% ggggbbbb
% ggggrrrr
% ggggbbbb
% ggggrrrr
% ggggbbbb
% 经过4的处理后，缓存2行，是和3相同的。
% 缓存4行，结果如下：
% ggggrrrr
% ggggrrrr
% ggggbbbb
% ggggbbbb
% ggggrrrr
% ggggrrrr
% ggggbbbb
% ggggbbbb
% 把他们整体编码





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global bayerimage0 %这只是个用于计算PSNR的参数，实际使用时可以删除
totaloutput='';%总体图像的输出
A0=double(imread('sample3.bmp'));%载入图像，标准图像大小为x*y~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


% load codebook_step4%载入码本，压缩步长为2。王主管说医生要求图片尽量清晰，所以尽可能的不要降低图像质量
% step=4;%量化步长
x=240;%图像的行数
y=240;%图像的列数
xx=40;%处理单元的行数~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
yy=240;%处理单元的列数
z=0;%ROI起始行数
w=0;%ROI起始列数
q=0;%ROI结束行数
p=0;%ROI结束列数

%bayer彩色滤波阵列格式
%  B  G
%  G  R
filter(:,:,3)=[1 0;0 0];%bayer彩色滤波阵列b分量
filter(:,:,2)=[0 1;1 0];%bayer彩色滤波阵列g分量
filter(:,:,1)=[0 0;0 1];%bayer彩色滤波阵列r分量

%将普通GRB颜色照片转成BAYER格式照片
for i=1:x/2%行数，每个滤波阵列为2*2,图像有x行，所以需要循环120次
    for j=1:y/2%列数，循环160次
        A0(2*i-1:2*i,2*j-1:2*j,:)=A0(2*i-1:2*i,2*j-1:2*j,:).*filter;
    end
end
bayerimage0=A0;


temp=zeros(x,y,1);
temp=A0(:,:,1)+A0(:,:,2)+A0(:,:,3);
A0=temp;%A0变成转换好了的bayer照片，尺寸是x*y*1
clear temp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A0=round(A0/2);%对应于NEAR=1;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% A0=round(A0/4);%对应于NEAR=2;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%把bayer图像中个像素重新排列
temp1=zeros(1,y/2);
temp2=zeros(1,y/2);
for i=1:x%把每一行内的像素整理排列一下，绿色放左边，其他颜色颠倒顺序后放右边。颠倒顺序可以使不同颜色过渡那里平滑些。
    if mod(i,2)==1%如果是奇数行
        temp1=A0(i,1:2:y-1);%颜色B
        temp2=A0(i,2:2:y);%颜色G1
        A0(i,1:y/2)=temp2;%把G集中放在左边
        A0(i,(y/2)+1:end)=temp1(end:-1:1);%把其他颜色放右边。注意顺序倒过来，这样增加图片平滑性
    else
        temp1=A0(i,1:2:y-1);%颜色G2
        temp2=A0(i,2:2:y);%颜色R
        A0(i,1:y/2)=temp1;%把G集中放在左边
        A0(i,(y/2)+1:end)=temp2(end:-1:1);%把其他颜色放右边。注意顺序倒过来，这样增加图片平滑性
    end
end
clear temp1 temp2

% A=A0; 


for k=1:6 %把240*240的图像分成40*240的六块作为基本处理单元
    k
    A=A0(1+40*(k-1):40*k,:);
    
    for i=2:yy%对基本处理图像单元（20*120的颜色分量图）进行水平滤波
        A(:,i)=round((A(:,i-1)+A(:,i))/2);
    end

    for i=2:xx%对基本处理图像单元（20*120的颜色分量图）进行水平滤波
        A(i,:)=round((A(i-1,:)+A(i,:))/2);
    end

    [JPEGLS_coderoutput1,JPEGLS_coderoutput2]=JPEGLS_coder(A);
    totaloutput=strcat(totaloutput,JPEGLS_coderoutput1,JPEGLS_coderoutput2);
end

TotalCompressionRatio=x*y*8/length(totaloutput)%总体压缩率
clear A JPEGLS_coderoutput1 JPEGLS_coderoutput2 n A1 Errorquant i j m filter A0_color step;

       
        
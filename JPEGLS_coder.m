%本程序用于演示JPEG-LS压缩算法过程
%    C B D
%    A X         % X是要编码的像素
function [JPEGLS_coderoutput1,JPEGLS_coderoutput2]=JPEGLS_coder(image)

JPEGLS_coderoutput1=[];
JPEGLS_coderoutput2=[];

%P图像数值的精度
P=8;
%NEAR量化精度
NEAR=0;
%threshold value at which A, B, and N are halved 
RESET=64;
%maximum allowed value of C[1..365]
MAX_C=127;
%minimum allowed value of C[1..365]
MIN_C=-128;
%设置T1,T2,T3的初值
T1=18;
T2=67;
T3=276;
%根据P值，计算出理论上的最大值MAXVAL=2^P-1.
MAXVAL=2^P-1;
% RANGE=((MAXVAL+2*NEAR)/(2*NEAR+1))+1
RANGE=MAXVAL+1;%只考虑无损压缩时的值
%映射后误差值所需的位数
qbpp=ceil(log2(RANGE));
%MAXVAL所需的位数，最小为2
bpp=max(2,ceil(log2(MAXVAL+1)));
%LIMIT表示在常规模式下，对样本编码时的glimit值，就是Golomb编码时码子所允许的长度
LIMIT=2*(bpp+max(8,bpp));

%为图像image增加第一行，第一列，最后一列。image本来是6行40列
TEMP=zeros(length(image(:,1))+1,length(image(1,:))+2);
TEMP(2:end,2:(end-1))=image;
TEMP(1,:)=0;%第一行数据为零
TEMP(2:end,1)=TEMP(1:(end-1),2);%第一列各个元素等于第二列上一行元素
TEMP(:,length(image(1,:))+2)=TEMP(:,length(image(1,:))+1);%最后一列等于倒数第二列
image=TEMP;
clear TEMP

%N 上下文本出现的概率，0-364常规模式  365-366游程  初始化为1
%A 累计预测误差,0-364常规模式  365-366游程    初始化为tmp
%B 计算偏差,0-364常规模式  初始化为0
%C 预测修正值,0-364常规模式  初始化为0
%Nn  不知道。。。。
tmp=max(2,floor((RANGE+32)/64));
A(1,1:365)=tmp;
N(1,1:365)=1;
B(1,1:365)=0;
C(1,1:365)=0;
Nn(1,1:365)=0;%计数器，游程终止时，用来存放负预测误差值，初始化为0

A(365+1)=tmp;
A(366+1)=tmp;
N(365+1)=1;
N(366+1)=1;
      
RUNindex=1;
RUNindex_prev=1;%这行是自己加的。不加的话该变量没有初始值。需注意验证~~~~~~~~~~~~~~~~~~~~~~~~~~
Nn(365+1)=0;
Nn(366+1)=0;
J(1,1:32)=[0 0 0 0 1 1 1 1 2 2 2 2 3 3 3 3 4 4 5 5 6 6 7 7 8 9 10 11 12 13 14 15];


%对每个像素统计其上下文环境并进行编码
totalpixnumber=0;%像素编号，总共不超过图像像素总个数
x=0;%行号
y=0;%列号

while totalpixnumber<(length(image(:,1))-1)*(length(image(1,:))-2) %像素总个数
    totalpixnumber=totalpixnumber+1;%取下个像素
    x=1+ceil(totalpixnumber/(length(image(1,:))-2));%像素的行号
    y=1+totalpixnumber-(x-2)*(length(image(1,:))-2);%像素的列号
    %取出x,a,b,c,d的值  Ix为像素值    Ra,Rb,Rc,Rd为重建值，无损压缩正好等于像素值
    Ix=image(x,y);
    Ra=image(x,y-1);
    Rb=image(x-1,y);
    Rc=image(x-1,y-1);
    Rd=image(x-1,y+1);
    
    %计算局部梯度
    D(1) = Rd - Rb;
    D(2) = Rb - Rc;
    D(3) = Rc - Ra;
    
    %此处应根据不同梯度选择游程编码方式或者常规方式
    if (D(1)==0)& (D(2)==0) & (D(3)==0) %如果梯度为0，则采用游程编码模式%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        EOLine=(y==(length(image(1,:))-1)); %EOLine是行结束标志，1表示行结束
        RUNval=Ra;
        RUNcnt=0;
        while (abs(Ix-RUNval)<=NEAR)
            RUNcnt=RUNcnt+1;
            Rx=RUNval;
            if EOLine==1
                break;
            else
                totalpixnumber=totalpixnumber+1;%取下个像素
                x=1+ceil(totalpixnumber/(length(image(1,:))-2));%像素的行号
                y=1+totalpixnumber-(x-2)*(length(image(1,:))-2);%像素的列号
                Ix=image(x,y);    
                Ra=image(x,y-1);
                Rb=image(x-1,y);
                Rc=image(x-1,y-1);
                Rd=image(x-1,y+1);
                D(1) = Rd - Rb;
                D(2) = Rb - Rc;
                D(3) = Rc - Ra;
                EOLine=(y==length(image(1,:))-1);
                RUNval=Ra;
            end
        end

        %Encoding of run segments of length rm 
        while RUNcnt>=(2^J(RUNindex))
            JPEGLS_coderoutput1=strcat(JPEGLS_coderoutput1,'1');%写入1个'1'至编码中
            RUNcnt=RUNcnt-2^J(RUNindex);
            if RUNindex<32
                RUNindex_prev = RUNindex;
                RUNindex=RUNindex+1;
            end
        end
    
        %Encoding of run segments of length less than rm
        if Ra~=Ix
            JPEGLS_coderoutput1=strcat(JPEGLS_coderoutput1,'0');%写入1个'0'至编码中 
            
            %将二进制的RUNcnt写入编码流中，占用J(RUNindex)个bit
            if length(dec2bin(RUNcnt))<J(RUNindex)
                for i=1:J(RUNindex)-length(dec2bin(RUNcnt))
                    JPEGLS_coderoutput1=strcat(JPEGLS_coderoutput1,'0');%写入J(RUNindex)-length(dec2bin(RUNcnt))个'0'至编码中
                end
                JPEGLS_coderoutput1=strcat(JPEGLS_coderoutput1,dec2bin(RUNcnt));%写入二进制的RUNcnt至编码中
            else
                if length(dec2bin(RUNcnt))>=J(RUNindex)%从RUNcnt中取出低J(RUNindex)位，输出
                    temp=char();
                    temp=dec2bin(RUNcnt);
                    temp=temp(1+length(dec2bin(RUNcnt))-J(RUNindex):length(dec2bin(RUNcnt)));
                    JPEGLS_coderoutput1=strcat(JPEGLS_coderoutput1,temp);%写入二进制的RUNcnt至编码中
                    clear temp
                end
            end
            
            if(RUNindex>1)%如果和前一个像素相同，即一行结束
                 RUNindex_prev=RUNindex;
                RUNindex=RUNindex-1;
            end
        else 
            if(RUNcnt>0)
                JPEGLS_coderoutput1=strcat(JPEGLS_coderoutput1,'1');%写入1个'1'至编码中
            end
        end
           
        %接下来对游程中断后的像素进行编码，和常规编码有类似的地方
        if Ra~=Ix
            %Index computation
            if Ra==Rb
                RItype=1;
            else
                RItype=0;
            end
            %Prediction error for a run interruption sample
            if RItype==1
                Errval=Ix-Ra;
            else
                Errval=Ix-Rb;
            end
            encode.Errval_begin{totalpixnumber}=Errval;
            %Error computation for a run interruption sample
            if (RItype==0) && (Ra>Rb)
                Errval=-Errval;
                SIGN=-1;
            else
                SIGN=1;
            end
            
            Rx = Ix;
                       
            %Modulo reduction of the error
            if(Errval < 0)
                Errval = Errval + RANGE;
            end
            if(Errval >= floor((RANGE+1)/2))
                Errval = Errval - RANGE;
            end

            %Computation of auxiliary variable in Golomb parameter
            %只用到365,366两个参数位置，0-364为常规编码参数位置
            if RItype==0
                TEMP=A(365+1);
            else
                TEMP=A(366+1)+floor(N(366+1)/2);
            end
            q=RItype+365+1;
            k=ceil(log2(TEMP/N(q)));
            if k<0
                k=0;
            end
            
            %Computation of map for Errval mapping
            if (k==0)&&(Errval>0)&&(2*Nn(q)<N(q))
                map=1;
            else
                if (Errval<0)&&(2*Nn(q)>=N(q))
                    map=1;
                else
                    if (Errval<0)&&(k~=0)
                        map=1;
                    else
                        map=0;
                    end
                end
            end
            
            %Errval mapping for run interuption sample
            EMErrval=2*(abs(Errval))-RItype-map;
            
            %Mapped-error encoding
            %已经完成匹配的误差进行golomb编码
            glimit=LIMIT-J(RUNindex_prev)-1;            
            [JPEGLS_coderoutput1]=GolombCoding(JPEGLS_coderoutput1, EMErrval, k, glimit, qbpp);
            
            %update of parameters for run interruption sample更新参数
            if Errval<0
                Nn(q)=Nn(q)+1;
            end
            A(q)=A(q)+floor((EMErrval+1-RItype)/2);
            if(N(q)==RESET)
                A(q)=floor(A(q)/2);
                N(q)=floor(N(q)/2);
                Nn(q)=floor(Nn(q)/2);
            end
            N(q)=N(q)+1;
        end                 
    else %如果梯度不为0，则采用常规编码模式%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %局部梯度量化  由D计算出Q
        for i=1:3
            if D(i)<=-T3
                Q(i)=-4;
                elseif D(i)<=-T2
                    Q(i)=-3;
                elseif D(i)<=-T1
                    Q(i)=-2;
                elseif D(i)<-NEAR
                    Q(i)=-1;
                elseif D(i)<=NEAR
                    Q(i)=0;
                elseif D(i)<T1
                    Q(i)=1;
                elseif D(i)<T2
                    Q(i)=2;
                elseif D(i)<T3
                    Q(i)=3;
                else Q(i)=4;
            end
        end
            
        %量化梯度融合  由Q计算出Q和SIGN
        if Q(1)<0
            Q(1)=-Q(1);
            Q(2)=-Q(2);
            Q(3)=-Q(3);
            SIGN=-1;
            elseif Q(1)==0
                if Q(2)<0
                    Q(2)=-Q(2);
                    Q(3)=-Q(3);
                    SIGN=-1;
                    elseif (Q(2)==0) && (Q(3)<0)
                        Q(3)=-Q(3);
                        SIGN=-1;
                    else SIGN=1;
                end
            else SIGN=1;
        end
        
        %The Maping step to detrmin Q
        q=81*Q(1)+9*Q(2)+Q(3)+1;   
        
        %按照基本规则预测Px
        if Rc>=max(Ra,Rb)
            Px=min(Ra,Rb);
        else 
            if Rc<=min(Ra,Rb)
                Px=max(Ra,Rb);
            else
                Px=Ra+Rb-Rc;
            end
        end
              
        %预测值Px修正
        if SIGN==1
            Px=Px+C(q);
        else
            Px=Px-C(q);
        end
        if Px>MAXVAL
            Px=MAXVAL;
        else
            if Px<0
                Px=0;
            end
        end
        
        %预测误差计算
        Errval=Ix-Px;
        if SIGN==-1
            Errval=-Errval;
        end
        
        %无损压缩，重建值=样本值
        Rx=Ix;
        
        %预测误差限制范围
        if Errval<0
            Errval=Errval+RANGE;
        end
        if Errval>=(RANGE+1)/2
            Errval=Errval-RANGE;
        end
        
        %下面对预测误差进行编码
        %计算K值
        if A(q)/N(q)==0
            k=0;
        else
            k=floor(log2(A(q)/N(q)));
        end
        if k<0 
            k=0;
        end
        
        %把预测误差映射为非负整数
        if (NEAR==0) && (k==0) && (2*B(q)<=-N(q))
            if Errval>=0
                MErrval=2*Errval+1;
            else
                MErrval=-2*(Errval+1);
            end
        else
            if Errval>=0
                MErrval=2*Errval;
            else
                MErrval=-2*Errval-1;
            end
        end
        
        %开始golomb编码，生成的二进制数据存放在JPEGLS_coderoutput1中，JPEGLS_coderoutput2为空
        [JPEGLS_coderoutput1]=GolombCoding(JPEGLS_coderoutput1, MErrval, k, LIMIT, qbpp);


        %更新A,B,N参数
        B(q)=B(q)+Errval*(2*NEAR+1);
        A(q)=A(q)+abs(Errval);
        if N(q)==RESET
            A(q)=floor(A(q)/2);
            B(q)=floor(B(q)/2);
            N(q)=floor(N(q)/2);
        end
        N(q)=N(q)+1;
        
        %更新B,C参数
        if B(q)<=-N(q) 
            B(q)=B(q)+N(q);
            if C(q)>MIN_C
                C(q)=C(q)-1;
            end
            if B(q)<=-N(q)
                B(q)=-N(q)+1;
            end
        elseif B(q)>0
            B(q)=B(q)-N(q);
            if C(q)<MAX_C
                C(q)=C(q)+1;
            end
            if B(q)>0
                B(q)=0;
            end
        end
    end  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    

        
end




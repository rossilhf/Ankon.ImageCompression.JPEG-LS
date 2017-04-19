%本程序用于演示JPEG-LS解压缩算法过程
%    C B D
%    A X         % X是要编码的像素

function [Re_image,totaloutput]=losslessJPEG_decoder(totaloutput)
global bayerimage0

%为图像image设定保存空间，增加第一行，第一列，最后一列。
Re_image=zeros(40+1,240+2);%image本来是6行40列,这里先设定多出来的行列数据，最后返回时删去第一行第一列最后一列~~~~~~~~~~~~~~~~~~~~~~~~~~~
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

%N 上下文本出现的概率，0-364常规模式  365-366游程  初始化为1
%A 累计预测误差,0-364常规模式  365-366游程    初始化为tmp
%B 计算偏差,0-364常规模式  初始化为0
%C 预测修正值,0-364常规模式  初始化为0
%Nn  不知道。。。。
tmp=max(2,floor((RANGE+32)/64));
A(1,1:365)=tmp;%这里matlab和c数组开头编号不同，以后可能会在这里出问题！！！！！！！！！！！！！！！
N(1,1:365)=1;
B(1,1:365)=0;
C(1,1:365)=0;
Nn(1,1:365)=0;

A(365+1)=tmp;
A(366+1)=tmp;
N(365+1)=1;
N(366+1)=1;
      
RUNindex=1;%这个是什么？如果程序出错，这个指针可能得改成1！！！！！！！！！！！！！！！！！！！！
RUNindex_prev=1;%这行是自己加的。不加的话该变量没有初始值。需注意验证~~~~~~~~~~~~~~~~~~~~~~~~~~
Nn(365+1)=0;
Nn(366+1)=0;

J(1,1:32)=[0 0 0 0 1 1 1 1 2 2 2 2 3 3 3 3 4 4 5 5 6 6 7 7 8 9 10 11 12 13 14 15];
totalpixnumber=0;%像素编号，总共不超过图像像素总个数
x=2;%行号
y=1;%列号

%开始将一个一个像素恢复填充到Re_image中
while x*y<length(Re_image(:,1))*(length(Re_image(1,:))-1)
%     totalpixnumber=totalpixnumber+1;%取下个像素
%     decode.totalpixnumber(totalpixnumber)=totalpixnumber
%     totalpixnumber
%     x=1+ceil(totalpixnumber/(length(Re_image(1,:))-2));%像素的行号
%     y=1+totalpixnumber-(x-2)*(length(Re_image(1,:))-2);%像素的列号

    if y>=length(Re_image(1,:))-1%取下个像素
        x=x+1;
        y=2;
    else
        y=y+1;
    end
    %取出x,a,b,c,d的值  Ix为像素值    Ra,Rb,Rc,Rd为重建值，无损压缩正好等于像素值
    Ix=Re_image(x,y);
    Ra=Re_image(x,y-1);
    Rb=Re_image(x-1,y);
    Rc=Re_image(x-1,y-1);
    Rd=Re_image(x-1,y+1);
    
    %计算局部梯度
    D(1) = Rd - Rb;
    D(2) = Rb - Rc;
    D(3) = Rc - Ra;
    
    %此处应根据不同梯度选择游程编码方式或者常规方式
    if (D(1)==0)& (D(2)==0) & (D(3)==0) %如果梯度为0，则采用游程编码模式%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %初始化参数
        i=0;
        cnt=0;
        run_flag=0;
        glimit=0;
        
%         decodeoutput1{totalpixnumber}=totaloutput
        %Scanning
        while 1
            run_flag=0;
            R=totaloutput(1);
            totaloutput(1)=[];%从totaloutput中读取一个bit
            if R=='1'%取出bit为1
                if length(Re_image(1,:))-1-y+1>=2^J(RUNindex)%这里不等号前面的数值可能有1左右的误差，要调整~~~~~~~~~~~~~~~~~~~
                    for i=0:(2^J(RUNindex))-1
                        Re_image(x,y+i)=Ra;
                        %!!!!!!!!!!!!!!!!!!!!添加时间2010.6.27 17:12。图像新增出来的列中数据仍未赋值
                        if (y+i==2)&(x<length(Re_image(:,1)))
                            Re_image(x+1,1)=Ra;
                        end
                        if (y+i==(length(Re_image(1,:))-1))
                            Re_image(x,y+i+1)=Ra;
                        end
                        %!!!!!!!!!!!!!!!!!!!!
                    end
                    y=y+2^J(RUNindex); %像素列坐标增加
%                     totalpixnumber=totalpixnumber+2^J(RUNindex);%像素编号增加，这是自己加的，可能要改~~~~~~~~~~~~~~~~~~~~~~~~~~
%                     decode.totalpixnumber(totalpixnumber)=totalpixnumber
                    if RUNindex<32%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                        RUNindex_prev=RUNindex;
                        RUNindex=RUNindex+1;
                    end
                
                else
                    for i=y:(length(Re_image(1,:))-1)%这里与94行情况一样~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                        Re_image(x,i)=Ra;
                        %!!!!!!!!!!!!!!!!!!!!添加时间2010.6.27 17:12。图像新增出来的列中数据仍未赋值
                        if (i==2)&(x<length(Re_image(:,1)))
                            Re_image(x+1,1)=Ra;
                        end
                        if (i==(length(Re_image(1,:))-1))
                            Re_image(x,i+1)=Ra;
                        end
                        %!!!!!!!!!!!!!!!!!!!!
                    end
%                     totalpixnumber=totalpixnumber+length(Re_image(1,:))-1-y;%像素编号增加，这是自己加的，可能要改~~~~~~~~~~~~~~~~~~~~~~~~~~
%                     decode.totalpixnumber(totalpixnumber)=totalpixnumber
                    %这一行是新添的。上面y增加了，那么totalpixnumber也对应增加，这里应该也一样吧。2010.6.25 21.23%%%%
%                     totalpixnumber=totalpixnumber+length(Re_image(1,:))-1-y;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    y=length(Re_image(1,:))-1;%一行的最后一个像素
                    break
                end
            else %取出bit为0，说明游程中止不是行结束，而是像素不相等
                if J(RUNindex)~=0
                    for i=1:J(RUNindex)
                        temp=totaloutput(1);
                        totaloutput(1)=[];
                        cnt=cnt+(temp-'0')*(2^(J(RUNindex)-i));
                    end
                end
                if cnt>0
                    for i=0:cnt-1
                        Re_image(x,y+i)=Ra;
                        %!!!!!!!!!!!!!!!!!!!!添加时间2010.6.27 17:12。图像新增出来的列中数据仍未赋值
                        if (y+i==2)&(x<length(Re_image(:,1)))
                            Re_image(x+1,1)=Ra;
                        end
                        if (y+i==(length(Re_image(1,:))-1))
                            Re_image(x,y+i+1)=Ra;
                        end
                        %!!!!!!!!!!!!!!!!!!!!
                    end
                end
                y=y+cnt;
%                 totalpixnumber=totalpixnumber+cnt;%像素编号增加，这是自己加的，可能要改~~~~~~~~~~~~~~~~~~~~~~~~~~
%                 decode.totalpixnumber(totalpixnumber)=totalpixnumber
                
                if RUNindex>1%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                    RUNindex_prev=RUNindex;
                    RUNindex=RUNindex-1;
                end
                run_flag=1;  %取出了bit0,需要进行游程中断像素解码。
                break                
            end
            if y>length(Re_image(1,:))-1
                y=length(Re_image(1,:))-1;
                %这一行是新添的。上面y增加了，那么totalpixnumber也对应增加，这里应该也一样吧。2010.6.25 21.23%%%%
%                 totalpixnumber=totalpixnumber+length(Re_image(1,:))-1-y;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                break
            end
        end
        
%         '------------------------------------------'
%         RUNindex,run_flag,Ra
        
        if run_flag==1
            %Index computation
            y=y-1;
%             totalpixnumber=totalpixnumber-1;
            
            %SetSample()
%             totalpixnumber=totalpixnumber+1;%取下个像素
%             x=1+ceil(totalpixnumber/(length(Re_image(1,:))-2));%像素的行号
%             y=1+totalpixnumber-(x-2)*(length(Re_image(1,:))-2);%像素的列号
            if y>=length(Re_image(1,:))-1%取下个像素
                x=x+1;
                y=2;
            else
                y=y+1;
            end
            
            %取出x,a,b,c,d的值  Ix为像素值    Ra,Rb,Rc,Rd为重建值，无损压缩正好等于像素值
            Ix=Re_image(x,y);
            Ra=Re_image(x,y-1);
            Rb=Re_image(x-1,y);
            Rc=Re_image(x-1,y-1);
            Rd=Re_image(x-1,y+1);
            %计算局部梯度
            D(1)=Rd-Rb;
            D(2)=Rb-Rc;
            D(3)=Rc-Ra;
            if Ra==Rb
                RItype=1;
            else
                RItype=0;
            end
            
            %Computation of auxiliary variable in Golomb parameter
            if RItype==0
                TEMP=A(365+1);%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            else
                TEMP=A(366+1)+floor(N(366+1)/2);%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            end
            q=RItype+365+1;
            k=ceil(log2(TEMP/N(q)));
            if k<0
                k=0;
            end %此处留意，k是否可能为负，是否需要强制其大于等于零，与常规编码中处理一致~~~~~~~~~~~~
            
%             refork.q(totalpixnumber)=q
%             decode.RItype(totalpixnumber)=RItype
%             refork.TEMP(totalpixnumber)=TEMP
%             refork.Nq(totalpixnumber)=N(q)
%             refork.k(totalpixnumber)=k
            
            %进行golomb解码
            glimit=LIMIT-J(RUNindex_prev)-1;
            
%             decode.k(totalpixnumber)=k
%             decodeoutput2{totalpixnumber}=totaloutput
            
            [EMErrval,totaloutput]=GolombDecoding(totaloutput,k, glimit,qbpp);
            
%             RItype,q,k,EMErrval,glimit
%             
%             decode.EMErrval(totalpixnumber)=EMErrval
%             
%             decodeoutput3{totalpixnumber}=totaloutput
            
            if mod(EMErrval,2)==1
                if RItype==1
                    map=0;
                else
                    map=1;
                end
                Errval=floor((EMErrval+1)/2);
            else
                if RItype==1 
                    Errval=floor((EMErrval+2)/2);
                    map=1;
                else
                    Errval=floor(EMErrval/2);
                    map=0;
                end
            end
%             decode.map{totalpixnumber}=map
%             decode.Errval_begin{totalpixnumber}=Errval
            
            %correct the sign of the map fun. 
            if (k==0)&&(map==0)&&(2*Nn(q)<N(q))
                Errval=-Errval;
            elseif (map==1)&&(2*Nn(q)>=N(q))
                Errval=-Errval;
            elseif (map==1)&&(k~=0)
                Errval=-Errval;
            end
            
            %Error computation for a run interruption sample
            if (RItype==0)&&(Rb<Ra)
                Errval=-Errval;
            end
%             decode.Errval_end{totalpixnumber}=Errval
            
                        
            %Adding prediction error for a run interruption sample
            if RItype==1
                if Errval+Ra>=0%增加这个判断，完全是因为c和matlab中求模函数不一样~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                    Rx=mod((Errval+Ra),RANGE);
                else
                    Rx=-mod((-Errval-Ra),(RANGE*(2*NEAR+1)));
%                     Rx=mod((-Errval-Ra),RANGE);%此处有重要修改2010.6.14-15：15
                end
            else
                if Errval+Rb>=0%增加这个判断，完全是因为c和matlab中求模函数不一样~~~~~~~~~~~~~~~~~~~~~~~~
                    Rx=mod((Errval+Rb),RANGE);
                else
                    Rx=-mod((-Errval-Rb),(RANGE*(2*NEAR+1)));
%                     Rx=mod((-Errval-Rb),RANGE);%此处有重要修改2010.6.14-15：15
                end
            end
            
            if Rx<0
                Rx=Rx+RANGE;
            else
                if Rx>MAXVAL+NEAR
                    Rx=Rx-RANGE;
                end
            end
            
            if Rx<0
                Rx=0;
            else
                if Rx>MAXVAL
                    Rx=MAXVAL;
                end
            end
            
            Re_image(x,y)=Rx;
%             Errval,Rx
%             decode.Rx{totalpixnumber}=Rx
            
            %!!!!!!!!!!!!!!!!!!!!添加时间2010.6.22 14:54。每次转行就解码错误，是由于图像新增出来的列中数据仍未赋值，还是0
            if (y==2)&(x<length(Re_image(:,1)))
                Re_image(x+1,1)=Rx;
            end
            if (y==(length(Re_image(1,:))-1))
                Re_image(x,y+1)=Rx;
            end
            %!!!!!!!!!!!!!!!!!!!!
            
            %update of parameters for run interruption sample
            if Errval<0
                Nn(q)=Nn(q)+1;
            end
            A(q)=A(q)+floor((EMErrval+1-RItype)/2);
            if N(q)==RESET
                A(q)=floor(A(q)/2);
                N(q)=floor(N(q)/2);
                Nn(q)=floor(Nn(q)/2);
            end
            N(q)=N(q)+1;            
        end     
%      A(q),N(q),Nn(q)
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
        q=81*Q(1)+9*Q(2)+Q(3)+1;    %这里以前不+1的，但是matlab数组第一个序号不能为0
        
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

        %计算K值
        if A(q)/N(q)==0
            k=0;
        else
            k=floor(log2(A(q)/N(q)));
        end
        if k<0 
            k=0;
        end%~~~~~~~~~~~~~~~~~~~~~~~~~~~偶尔会有k<0出现，,增加该if
        
        
        %下面进行glomb解码
        [MErrval,totaloutput]=GolombDecoding(totaloutput,k, LIMIT,qbpp);

        %通过MErrval,计算Errval，和编码正好相反
        if (NEAR==0)&&(k==0)&&(2*B(q)<=-N(q)) 
            if mod(MErrval,2)~=0               %~~~~~~~~~~~~~~~~~~~~~~原本的计算是MErrval&1，看不懂
                Errval=floor((MErrval-1)/2);
            else
                Errval=-(floor(MErrval/2))-1;
            end
        else
            if mod(MErrval,2)==0            %~~~~~~~~~~~~~~~~~~~~~~~~~原本的计算是MErrval&1，看不懂
                Errval=floor(MErrval/2);
            else
                Errval=-floor((MErrval+1)/2);
            end
        end
        
        %更新A,B,N参数
        B(q)=B(q)+Errval*(2*NEAR+1);
        A(q)=A(q)+abs(Errval);
        if N(q)==RESET
            A(q)=floor(A(q)/2);
            B(q)=floor(B(q)/2);
            N(q)=floor(N(q)/2);
        end
        N(q)=N(q)+1;
        
        %下面对Errval进行一些修正
        if NEAR>0
            Errval=Errval*(2*NEAR+1);
        end
        if SIGN==-1
            Errval=-Errval;
        end
   
        %计算出重建值
        Rx=(Errval+Px);%(RANGE*(2*NEAR+1));
        
        %RX处理
        if Rx<-NEAR
            Rx=Rx+RANGE*(2*NEAR+1);
        else
            if Rx>(MAXVAL+NEAR)
                Rx=Rx-RANGE*(2*NEAR+1);
            end
        end
        
        %RX处理
        if Rx<0
            Rx=0;
        else 
            if Rx>MAXVAL
                Rx=MAXVAL;
            end
        end
        
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
        
        %写入输出缓存，以后的计算需要用到该值
        Re_image(x,y)=Rx;
        if (y==2)&(x<length(Re_image(:,1)))
                Re_image(x+1,1)=Rx;
            end
            if (y==(length(Re_image(1,:))-1))
                Re_image(x,y+1)=Rx;
            end
        %同时，恢复图像中计算上下文所额外扩充的边界行列中的数据也需要填充
        %编码时，直接把前后两列都填充好了，因此在边界条件时，a,b,c,d直接根据坐标取值就好了。
        %解码时，没有填充好两列数据，因此在边界条件时对abcd取值时要处理好
        if (x<length(Re_image(:,1)))&(y==2)
            Re_image(x+1,1)=Rx;%第一列数据等于前一行第二列数据
        end
        if y==(length(Re_image(1,:))-1)
            Re_image(x,y+1)=Rx;%第42列数据等于第41列数据
        end
        

    end
end

tmp=Re_image(2:end,2:end-1);
Re_image=tmp;%将计算用的临时多出来的第一行第一列最后一列删除

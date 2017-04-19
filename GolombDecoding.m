        function [MErrval,totaloutput]=GolombDecoding(totaloutput,k, LIMIT,qbpp)

        val1 = 0;
        val2 = 0;
        val3 = LIMIT-qbpp-1;
        
        %计算读到多少个0，此数量即为val1,为Merrval/2^K的商
        count=1;
        while totaloutput(count)~='1'
            val1=val1+1; 
            count=count+1;
        end
%         totaloutput(1:count-1)=[];%取走数据后，压缩数据流中相应元素删除~~~~~~~~~~~~~~~~~~~~~~~~原本计算中对于前半部分的一元编码，只取了0，没有删掉1
        totaloutput(1:count)=[];%取走数据后，压缩数据流中相应元素删除
        
        if(val1<val3)
            val2=val1*(2^k);  %val2等于val1放大2^k倍
            %读出k个bit，为MErravl/2^K的余数。累加到VAL2上后，VAL2即为MErravl
            %移位代码的理解可以参考编码
            if k~=0 %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~原本没有这个if，但是会出现k等于0的情况
%                 temp=char();
                for i=1:k
                    temp(i)=totaloutput(i);
                end
                val2=val2+bin2dec(temp(1:k));
                totaloutput(1:k)=[];%取走数据后，压缩数据流中相应元素删除
%                 clear temp
            end   %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        else
            %读出长度为qbpp，值为MErrval-1
%             temp=char();
            for i=1:qbpp
                temp(i)=totaloutput(i);
            end
            val2=bin2dec(temp(1:qbpp));
            val2=val2+1;%+1后，就计算出了MErrval
            totaloutput(1:qbpp)=[];%取走数据后，压缩数据流中相应元素删除
%             clear temp
        end
        MErrval=val2;
        
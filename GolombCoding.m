function [JPEGLS_coderoutput1]=GolombCoding(JPEGLS_coderoutput1, MErrval, k, LIMIT,qbpp)

val1 = floor(MErrval/(2^k)); %Merrval/2^K的商
        val2 = val1*(2^k);
        val3 = LIMIT-qbpp-1; 
        if val1<val3
            temp=char();
            for i=1:val1 
                temp(i)='0';
            end
            JPEGLS_coderoutput1=strcat(JPEGLS_coderoutput1,temp);%写入val1个0
            JPEGLS_coderoutput1=strcat(JPEGLS_coderoutput1,'1');%写入1个1
%             clear temp
            val4=MErrval-val2;%MErravl/2^K的余数
            if length(dec2bin(val4))<k
                count=k-length(dec2bin(val4));
                temp=char();
                for i=1:count
                    temp(i)='0';
                end
                JPEGLS_coderoutput1=strcat(JPEGLS_coderoutput1,temp);%空余位上补0
                JPEGLS_coderoutput1=strcat(JPEGLS_coderoutput1,dec2bin(val4));%写入长度为K的余数
%                 clear temp
            else
                if k~=0
                    JPEGLS_coderoutput1=strcat(JPEGLS_coderoutput1,dec2bin(val4));%直接写入长度为K的余数,如果k为0，则什么都不写
                end
            end
        else
            temp=char();
            for i=1:val3 
                temp(i)='0';
            end
            JPEGLS_coderoutput1=strcat(JPEGLS_coderoutput1,temp);%写入val3个0
            JPEGLS_coderoutput1=strcat(JPEGLS_coderoutput1,'1');%写入1个1
%             clear temp
            if length(dec2bin(MErrval-1))<qbpp
                count=qbpp-length(dec2bin(MErrval-1));
                temp=char();
                for i=1:count
                    temp(i)='0';
                end
                JPEGLS_coderoutput1=strcat(JPEGLS_coderoutput1,temp);%空余位上补0
                JPEGLS_coderoutput1=strcat(JPEGLS_coderoutput1,dec2bin(MErrval-1));%写入长度为qbpp的余数
            else
                JPEGLS_coderoutput1=strcat(JPEGLS_coderoutput1,dec2bin(MErrval-1));%直接写入长度为qbpp的余数
            end
        end
        
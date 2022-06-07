#!/bin/bash

cscore=cscore-1.0-SNAPSHOT
stuFName=stu
answerFName=answer

originalFName=original
formatSpecifierFName=fs
replacedFormatSpecifierFName=rfs
markedFName=marked

testcase_filename=testcase

package=com.longmao.run
encoder=EncoderRun
decoder=DecoderRun
getFormatScore=FormatScoreRun
getValueScore=ValueScoreRun

fs_mode=2 #格式打分模式, 两种选项, 1为格式部分按行求最长公共子序列即可, 2为格式部分完全相等
vs_model=1 #值打分模式, 两种选项, 1为值部分为标准答案的子串即可, 2为值部分完全相等

# 根据original.c生成$1fs.c, $1rfs.c和$1marked.c
function generateCFile(){
    path=$(pwd)
    java -cp ${cscore}.jar ${package}.${encoder} "${path}"
    status=$?
    if [[ $status -ne 0 ]]
    then
        echo "Cannot Compile ${encoder}.java(return $status)"
        exit 1
    fi
    
    gcc -o ./"$1"${formatSpecifierFName}.o ./${formatSpecifierFName}.c
    gcc -o ./"$1"${replacedFormatSpecifierFName}.o ./${replacedFormatSpecifierFName}.c
    gcc -o ./"$1"${markedFName}.o ./${markedFName}.c
}


cp ./${answerFName}.c ./${originalFName}.c
os=$(uname) # 判断操作系统为linux还是macOS, 二者的sed命令存在差异
# 在.c文件的scanf行尾插入printf语句, 加入换行符
if [ $os = 'Darwin' ]
then
    sed '/scanf/a\
printf("\\n");
    ' ./${originalFName}.c > ./${answerFName}.c
else
    sed '/scanf/aprintf("\\n");' ./${originalFName}.c > ./${answerFName}.c
fi
echo "Compiling ${answerFName}.c"
gcc -o ./${answerFName}.o ./${answerFName}.c
status=$?
if [[ $status -ne 0 ]]
then
    echo "Cannot compile ${answerFName}.c(return $status)"
    exit 1
fi
generateCFile "answer" # 生成answerfs.c, answerrfs.c和answermarked.c
mv ./${originalFName}.c ./${answerFName}.c


cp ./${stuFName}.c ./${originalFName}.c
if [ $os = 'Darwin' ]
then
    sed '/scanf/a\
printf("\\n");
    ' ./${originalFName}.c > ./${stuFName}.c
else
    sed '/scanf/aprintf("\\n");' ./${originalFName}.c > ./${stuFName}.c
fi
echo "Compiling ${stuFName}.c"
gcc -o ./${stuFName}.o ./${stuFName}.c
status=$?
if [ $status -ne 0 ]
then
    echo "Cannot compile ${stuFName}.c(return $status)"
    exit 1
fi
generateCFile "stu" # 生成stufs.c, sturfs.c和stumarked.c
mv ./${originalFName}.c ./${stuFName}.c


validScore=0 # 有效测试用例得分
invalidScore=0 # 无效测试用例得分
validCount=0 # 有效测试用例数
invalidCount=0 # 无效测试用例数


if [[ -f ./${testcase_filename}.txt ]]
then
    while read line
    do
        cp ./${stuFName}.c ./${originalFName}.c
        stuFormatSpecifier=$(echo "$line" | ./stu${formatSpecifierFName}.o)
        stuReplacedFormatSpecifier=$(echo "$line" | ./stu${replacedFormatSpecifierFName}.o)
        stuMarked=$(echo "$line" | ./stu${markedFName}.o)
        stuJson=$(java -cp ${cscore}.jar ${package}.${decoder} "${path}" "${stuFormatSpecifier}" "${stuReplacedFormatSpecifier}" "${stuMarked}")
        
        cp ./${answerFName}.c ./${originalFName}.c
        answerFormatSpecifier=$(echo "$line" | ./answer${formatSpecifierFName}.o)
        answerReplacedFormatSpecifier=$(echo "$line" | ./answer${replacedFormatSpecifierFName}.o)
        answerMarked=$(echo "$line" | ./answer${markedFName}.o)
        answerJson=$(java -cp ${cscore}.jar ${package}.${decoder} "${path}" "${answerFormatSpecifier}" "${answerReplacedFormatSpecifier}" "${answerMarked}")
        stuOut=$(echo "$line" | ./${stuFName}.o)
        answerOut=$(echo "$line" | ./${answerFName}.o)

        formatScore=$(java -cp ${cscore}.jar ${package}.${getFormatScore} "${stuOut}" "${answerOut}" "${fs_mode}")

        if [[ ${answerJson} = 'null' && ${stuJson} != 'null' ]] # 无效测试用例answer.o无格式结果输出时, stu.o有格式结果输出, 0分
        then
            invalidScore=$(( invalidScore ))
            (( invalidCount++ ))
        elif [[ $answerJson = 'null' && $stuJson = 'null' ]] # 无效测试用例answer.o无格式结果输出时, stu.o无格式结果输出, 满分
        then
            invalidScore=$(echo "$invalidScore+100"|bc)
            (( invalidCount++ ))
        elif [[ $answerJson != null && $stuJson = 'null' ]] # 有效测试用例answer.o有格式输出, stu.o无格式输出, 0分
        then
            validScore=$(( validScore ))
            (( validCount++ ))
        else
            valueScore=$(java -cp ${cscore}.jar ${package}.${getValueScore} "${stuJson}" "${answerJson}" "${vs_mode}")
            tmpScore=$(echo "${formatScore}*0.7+${valueScore}*0.3"|bc) # formatScore为格式分，valueScore为结果分
            validScore=$(echo "${validScore}+${tmpScore}"|bc)
            (( validCount++ ))
        fi
    done < ./${testcase_filename}.txt
fi

score=0
if [[ ${validCount} -ne 0 && ${invalidCount} -ne 0 ]]
then
    score=$(echo "${validScore}*0.8/${validCount}+${invalidScore}*0.2/${invalidCount}"|bc) #score1为无效测试用例得分, score2为有效测试用例得分
elif [[ ${validCount} -eq 0 && ${invalidCount} -ne 0 ]]
then
    score=$(echo "${validScore}/${validCount}"|bc)
fi
echo "{\"scores\": {\"Correctness\": $score}}"


rm -rf ./${originalFName}.c
rm -rf ./${stuFName}.o
rm -rf ./${answerFName}.o
rm -rf ./${formatSpecifierFName}.c
rm -rf ./${replacedFormatSpecifierFName}.c
rm -rf ./${markedFName}.c
rm -rf ./stu${formatSpecifierFName}.o
rm -rf ./stu${replacedFormatSpecifierFName}.o
rm -rf ./stu${markedFName}.o
rm -rf ./answer${formatSpecifierFName}.o
rm -rf ./answer${replacedFormatSpecifierFName}.o
rm -rf ./answer${markedFName}.o

#!/bin/bash
set -e

function empty_report_check {
    report_type=$1
    report_file_check=$(cat reports/${report_type}-vulnerabilities.txt | wc -m)
    if [ $report_file_check == 0 ];then
      echo "No Vulnerablity Found!" > reports/${report_type}-vulnerabilities.txt
    fi
}

empty_report_check "high"
empty_report_check "medium"
empty_report_check "critical"
empty_report_check "low"
empty_report_check "unknown"

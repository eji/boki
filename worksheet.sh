#!/bin/sh

SCRIPT_DIR=`dirname $0`

summary_account()
{
  local _account_type=$1
  local _total_debit=0
  local _total_creditor=0

  while read l; do
    _date=`echo ${l} | cut -d : -f 1`
    _t_debit=`echo ${l} | cut -d : -f 2`
    _v_debit=`echo ${l} | cut  -d : -f 3`
    _t_creditor=`echo ${l} | cut -d : -f 4`
    _v_creditor=`echo ${l} | cut -d : -f 5`

    if [ "${_account_type}" = "${_t_debit}" ]; then
      _total_debit=`expr ${_total_debit} + ${_v_debit}`
    fi

    if [ "${_account_type}" = "${_t_creditor}" ]; then
      _total_creditor=`expr ${_total_creditor} + ${_v_creditor}`
    fi

    echo $l
  done

  if [ $_total_debit -ne 0 -o $_total_creditor -ne 0 ]; then
    _diff=`expr ${_total_debit} - ${_total_creditor}`
    if [ $_diff -gt 0 ]; then
      echo "${_account_type}:${_diff}:${_total_debit}:${_total_creditor}:" >&2
    elif [ $_diff -lt 0 ]; then
      _diff=`expr $_diff \* -1`
      echo "${_account_type}::${_total_debit}:${_total_creditor}:${_diff}" >&2
    fi
  fi
}

convert_trial_balance()
{
  local _summary_cmd=
  for t in `cat ${SCRIPT_DIR}/account_types/*`; do
    if [ -n "$_summary_cmd" ]; then
      _summary_cmd="${_summary_cmd} | summary_account $t"
    else
      _summary_cmd="summary_account $t"
    fi
  done

  eval $_summary_cmd 2>&1  1>/dev/null
}

convert_worksheet()
{
  while read l; do
    _type=`echo $l | cut -d : -f 1`
    _debit_balance=`echo $l | cut -d : -f 2`
    _debit_summary=`echo $l | cut -d : -f 3`
    _credit_summary=`echo $l | cut -d : -f 4`
    _credit_balance=`echo $l | cut -d : -f 5`

    grep $_type ${SCRIPT_DIR}/account_types/assets_liabilities.txt > /dev/null
    if [ $? -eq 0 ]; then
      echo "${_type}:${_debit_balance}:${_credit_balance}:::${_debit_balance}:${_credit_balance}"
    else
      echo "${_type}:${_debit_summary}:${_credit_summary}:${_debit_summary}:${_credit_summary}::"
    fi
  done
}

convert_trial_balance | convert_worksheet

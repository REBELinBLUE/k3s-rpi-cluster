#!/bin/sh

kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}') | grep "token:" |  cut -d ':' -f2 | tr -d '[:space:]'

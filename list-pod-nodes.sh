#!/bin/bash
kubectl get pods -o jsonpath='POD NODE:{range.items[*]}{.metadata.name} {.spec.nodeName}:{end}' | tr ':' '\n' | column -t

# k8s-helpers.sh -- source me, don't execute me.
# kubectl conveniences. Every function no-ops with a message if kubectl is
# missing, so sourcing this file on a machine without a cluster is harmless.

# shellcheck shell=bash

_k8s_has() { command -v kubectl >/dev/null 2>&1; }
_k8s_require() {
    if ! _k8s_has; then
        echo "kubectl not found on PATH" >&2
        return 127
    fi
}

# klog <pod> [container] [--previous] -- follow logs, tail 50.
# Usage: klog my-pod-7f9c
#        klog my-pod-7f9c my-container
#        klog my-pod-7f9c --previous
klog() {
    _k8s_require || return $?
    local pod="${1:-}"
    [[ -z "$pod" ]] && { echo "usage: klog <pod> [container] [--previous]" >&2; return 2; }
    shift
    kubectl logs -f --tail=50 "$pod" "$@"
}

# kexec <pod> [container] -- shell into a pod. Tries bash, falls back to sh.
# Usage: kexec my-pod-7f9c
kexec() {
    _k8s_require || return $?
    local pod="${1:-}"
    [[ -z "$pod" ]] && { echo "usage: kexec <pod> [container]" >&2; return 2; }
    local container="${2:-}"
    if [[ -n "$container" ]]; then
        kubectl exec -it "$pod" -c "$container" -- sh -c 'command -v bash >/dev/null && exec bash || exec sh'
    else
        kubectl exec -it "$pod" -- sh -c 'command -v bash >/dev/null && exec bash || exec sh'
    fi
}

# kctx [context] -- switch kubectl context, or list them if no arg.
# Usage: kctx                 # list
#        kctx prod-us-east
kctx() {
    _k8s_require || return $?
    if [[ -z "${1:-}" ]]; then
        kubectl config get-contexts
        return
    fi
    kubectl config use-context "$1"
}

# kns [namespace] -- switch namespace for the current context, or list them.
# Usage: kns kube-system
kns() {
    _k8s_require || return $?
    if [[ -z "${1:-}" ]]; then
        kubectl get ns
        return
    fi
    kubectl config set-context --current --namespace="$1"
    echo "namespace set to $1"
}

# kimg <deployment> [namespace] -- show the image(s) a deployment runs.
# Usage: kimg my-api
kimg() {
    _k8s_require || return $?
    local d="${1:-}"
    [[ -z "$d" ]] && { echo "usage: kimg <deployment> [namespace]" >&2; return 2; }
    kubectl get deployment "$d" -n "${2:-default}" \
        -o jsonpath='{range .spec.template.spec.containers[*]}{.name}{"\t"}{.image}{"\n"}{end}'
}

# krestart <deployment> [namespace] -- rolling restart. Same as kubectl rollout.
# Usage: krestart my-api
krestart() {
    _k8s_require || return $?
    local d="${1:-}"
    [[ -z "$d" ]] && { echo "usage: krestart <deployment> [namespace]" >&2; return 2; }
    kubectl rollout restart "deployment/$d" -n "${2:-default}"
}

# kget <resource> [namespace] -- get with wide output and a namespace default.
# Usage: kget pods
#        kget pods kube-system
kget() {
    _k8s_require || return $?
    local res="${1:-pods}"
    kubectl get "$res" -n "${2:-default}" -o wide
}

# kfind <pattern> -- find pods matching a pattern across ALL namespaces.
# Usage: kfind uploader
kfind() {
    _k8s_require || return $?
    local pat="${1:-}"
    [[ -z "$pat" ]] && { echo "usage: kfind <pattern>" >&2; return 2; }
    kubectl get pods -A | grep -i -- "$pat"
}

# kevents [namespace] -- recent events, sorted by time. Great first step when
# something won't schedule.
kevents() {
    _k8s_require || return $?
    kubectl get events -n "${1:-default}" --sort-by=.lastTimestamp
}

# kwatch <pod> -- watch a pod's status change live. Ctrl-C to stop.
kwatch() {
    _k8s_require || return $?
    local pod="${1:-}"
    [[ -z "$pod" ]] && { echo "usage: kwatch <pod>" >&2; return 2; }
    kubectl get pod "$pod" -w
}

# kpf <pod> <local>:<remote> -- port-forward. Usage: kpf my-pod 5432:5432
kpf() {
    _k8s_require || return $?
    local pod="${1:-}" ports="${2:-}"
    [[ -z "$pod" || -z "$ports" ]] && { echo "usage: kpf <pod> <local>:<remote>" >&2; return 2; }
    kubectl port-forward "$pod" "$ports"
}

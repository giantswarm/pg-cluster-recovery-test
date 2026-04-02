#!/bin/bash

CLUSTER_NAME="$HOSTNAME" # Use the pod hostname as the cluster name
NAMESPACE="{{ .Values.pgCluster.namespace }}"
EXPECTED_POD_COUNT={{ .Values.pgCluster.instances }} # Define expected pod count

# Helper function to print executed commands
_run() {(
  set -x
  "$@"
)}

# Make sure that a posgresql cluster with the same name is not already running
if kubectl get clusters.postgresql.cnpg.io "${CLUSTER_NAME}" -n "${NAMESPACE}" > /dev/null 2>&1; then
  echo "### A PostgreSQL Cluster with the name ${CLUSTER_NAME} already exists in namespace ${NAMESPACE}. Please delete it before running the recovery test."
  exit 1
fi

# Create the recovery test cluster
echo "### Creating PostgreSQL Cluster ${CLUSTER_NAME} in namespace ${NAMESPACE}..."
# using kubectl patch in order to set the cluster name dynamically based on the pod hostname, and applying the manifest in one step
if ! kubectl patch --dry-run=client -f /etc/config/pg-recovery-cluster.yaml --type merge --patch '{"metadata":{"name":"'"$CLUSTER_NAME"'"}}' -oyaml | kubectl apply -f -; then

  echo "### Failed to apply PostgreSQL Cluster manifest for ${CLUSTER_NAME}. Exiting."
  exit 1
fi

# Define a cleanup function to delete the cluster and its PVCs after the test, regardless of the test outcome
cleanup() {
  echo
  echo
  echo "### Deleting the recovery test PostgreSQL Cluster ${CLUSTER_NAME}"

  # If the postgresql cluster's pods are ready, delete the cluster and end the test
  if ! _run kubectl delete clusters.postgresql.cnpg.io "${CLUSTER_NAME}" -n "${NAMESPACE}"; then
    echo "### Failed to delete PostgreSQL Cluster ${CLUSTER_NAME}. Please delete it manually."
    exit 1 # Exit with error if deletion fails
  fi
  echo "### PostgreSQL Cluster ${CLUSTER_NAME} deleted successfully."

  echo "### Deleting persistent volume claims for the ${CLUSTER_NAME} PostgreSQL Cluster"
  if ! _run kubectl delete pvc -l "cnpg.io/cluster=${CLUSTER_NAME}" -n "${NAMESPACE}"; then
    echo "### Failed to delete persistent volume claims for the ${CLUSTER_NAME} PostgreSQL Cluster. Please delete it manually."
    exit 1 # Exit with error if deletion fails
  fi
  echo "### Persistent volume claims for the ${CLUSTER_NAME} PostgreSQL Cluster deleted successfully."

  # The exit code is propagated from the main script, so if the cluster didn't become ready or the test failed, the script will exit with an error code after cleanup
}
trap cleanup EXIT

# Wait for the cluster to be created and report its status
echo "### Waiting for PostgreSQL Cluster to be ready..."
_run kubectl wait --for=condition=Ready "clusters.postgresql.cnpg.io/${CLUSTER_NAME}" -n "${NAMESPACE}" --timeout="${WAIT_TIMEOUT}"
wait_exit_code=$?

echo
echo "### Printing PostgreSQL Cluster resource:"
_run kubectl describe clusters.postgresql.cnpg.io "${CLUSTER_NAME}" -n "${NAMESPACE}"

echo
echo "### Printing CNPG full-recovery Job resource:"
_run kubectl describe job -l "cnpg.io/cluster=${CLUSTER_NAME}" -n "${NAMESPACE}"

# Get the name of the last created full-recovery pod for the cluster
last_full_recovery_pod_name="$(kubectl get po -l "cnpg.io/cluster=${CLUSTER_NAME}" -n "${NAMESPACE}" --sort-by='{.metadata.creationTimestamp}' -o jsonpath='{.items[-1:].metadata.name}')"

echo
echo "### Printing CNPG full-recovery Pod resource:"
_run kubectl describe pod "${last_full_recovery_pod_name}" -n "${NAMESPACE}"

echo
echo "### Printing CNPG full-recovery Pod Logs:"
_run kubectl logs "pod/${last_full_recovery_pod_name}" --all-containers -n "${NAMESPACE}"
echo
echo

if [[ $wait_exit_code -ne 0 ]]; then
  echo "### PostgreSQL Cluster ${CLUSTER_NAME} did not become ready in ${WAIT_TIMEOUT} seconds."
  echo "### Recovery test for ${CLUSTER_NAME} FAILED."
  exit 1 # Exit if cluster doesn't become ready
fi

echo "### PostgreSQL Cluster ${CLUSTER_NAME} is Ready."
echo "### Running recovery tests..."

# Execute tests until either those are successful or the timeout is reached
while [[ "$SECONDS" -lt "$TEST_TIMEOUT" ]]; do
  # Check if the postgresql cluster's pods are in 'Ready' state
  ready_pods_count="$(kubectl get pods -n "${NAMESPACE}" -l "cnpg.io/cluster=${CLUSTER_NAME}" -o jsonpath='{range .items[*]}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}' | grep -c True || true)"
  # The '|| true' ensures that if grep finds nothing (exit code 1), the script doesn't exit due to set -e (if it were set)

  if [[ "${ready_pods_count}" -eq "${EXPECTED_POD_COUNT}" ]]; then
    echo "### All ${EXPECTED_POD_COUNT} Pods for PostgreSQL Cluster ${CLUSTER_NAME} are in 'Ready' state. Recovery test successfully PASSED."
    exit 0
  else
    echo "### Found ${ready_pods_count} ready Pods out of ${EXPECTED_POD_COUNT} for PostgreSQL Cluster ${CLUSTER_NAME}. Waiting... ($SECONDS seconds elapsed)"
  fi

  sleep 60 # Check more frequently
done

# If the timeout is reached, end the test without deleting the cluster to allow further investigation
echo "### Timeout reached after $TEST_TIMEOUT seconds. Found ${ready_pods_count} ready Pods out of ${EXPECTED_POD_COUNT}."
echo "### Recovery test for ${CLUSTER_NAME} PostgreSQL Cluster FAILED."
exit 1 # Explicitly exit with an error code on timeout

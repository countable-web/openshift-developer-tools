#!/bin/bash

OCTOOLSBIN=$(dirname $0)

# ===================================================================================
usage() { #Usage function
  cat <<-EOF
  Tool to initialize a set of BC Government standard OpenShift projects.

  Usage: ${0} [ -h -x ]

  OPTIONS:
  ========
    -p <profile> load a specific settings profile; setting.<profile>.sh
    -P Use the default settings profile; settings.sh.  Use this flag to ignore all but the default 
       settings profile when there is more than one settings profile defined for a project.    
    -h prints the usage for the script
    -x run the script in debug mode to see what's happening

    Update settings.sh and settings.local.sh files to set defaults

EOF
exit 1
}
# ------------------------------------------------------------------------------

# Script-specific variables to be set
# In case you wanted to check what variables were passed
# echo "flags = $*"
while getopts p:Pxh FLAG; do
  case $FLAG in
    p ) export PROFILE=$OPTARG ;;
    P ) export IGNORE_PROFILES=1 ;;
    x ) export DEBUG=1 ;;
    h ) usage ;;
    \?) #unrecognized option - show help
      echo -e \\n"Invalid script option"\\n
      usage
      ;;
  esac
done

# Shift the parameters in case there any more to be used
shift $((OPTIND-1))
# echo Remaining arguments: $@

if [ -f ${OCTOOLSBIN}/settings.sh ]; then
  . ${OCTOOLSBIN}/settings.sh
fi

if [ -f ${OCTOOLSBIN}/ocFunctions.inc ]; then
  . ${OCTOOLSBIN}/ocFunctions.inc
fi

if [ ! -z "${DEBUG}" ]; then
  set -x
fi
# ===================================================================================

createGlusterfsClusterApp.sh \
  -p ${TOOLS}
exitOnError

# Iterate through Dev, Test and Prod projects granting permissions, etc.
for project in ${PROJECT_NAMESPACE}-${DEV} ${PROJECT_NAMESPACE}-${TEST} ${PROJECT_NAMESPACE}-${PROD}; do

  grantDeploymentPrivileges.sh \
    -p ${project} \
    -t ${TOOLS}
  exitOnError

	echo -e \\n"Granting ${JENKINS_SERVICE_ACCOUNT_ROLE} role to ${JENKINS_SERVICE_ACCOUNT_NAME} in ${project}"
  assignRole ${JENKINS_SERVICE_ACCOUNT_ROLE} ${JENKINS_SERVICE_ACCOUNT_NAME} ${project}
  exitOnError

  createGlusterfsClusterApp.sh \
    -p ${project}
  exitOnError
done

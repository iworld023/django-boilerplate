#!/bin/sh

HELP_TEXT="

Arguments:
	run_project: Default. Run the project server
	run_tests: Run unit tests
	setup_arches: Delete any existing Arches database and set up a fresh one
	-h or help: Display help text
"

display_help() {
	echo "${HELP_TEXT}"
}




wait_for_db() {
echo "Testing if database server is up..."
	while [[ ! ${return_code} == 0 ]]
	do
        psql --host=${PGHOST} --port=${PGPORT} --user=${PGUSERNAME} --dbname=postgres -c "select 1" >&/dev/null
		return_code=$?
		sleep 1
	done
	echo "Database server is up"
}





#### Run

run_migrations() {
	echo ""
	echo ""
	echo "----- RUNNING DATABASE MIGRATIONS -----"
	echo ""
	cd_app_folder
	python manage.py migrate
}

collect_static(){
	echo ""
	echo ""
	echo "----- COLLECTING DJANGO STATIC FILES -----"
	echo ""
	cd_app_folder
	python manage.py collectstatic --noinput
}


run_django_server() {
	echo ""
	echo ""
	echo "----- *** RUNNING DJANGO DEVELOPMENT SERVER *** -----"
	echo ""
	exec python manage.py runserver 0.0.0.0:8000
}


run_gunicorn_server() {
	echo ""
	echo ""
	echo "----- *** RUNNING GUNICORN PRODUCTION SERVER *** -----"
	echo ""
	cd_app_folder
	
	if [[ ! -z ${ARCHES_PROJECT} ]]; then
        gunicorn arches.wsgi:application \
            --config ${ARCHES_ROOT}/gunicorn_config.py \
            --pythonpath ${ARCHES_PROJECT}
	else
        gunicorn arches.wsgi:application \
            --config ${ARCHES_ROOT}/gunicorn_config.py
    fi
}



#### Main commands
run_project() {
	wait_for_db
	if [[ "${DJANGO_MODE}" == "DEV" ]]; then
		run_django_server
	elif [[ "${DJANGO_MODE}" == "PROD" ]]; then
		collect_static
		run_gunicorn_server
	fi
}

# Use -gt 1 to consume two arguments per pass in the loop (e.g. each
# argument has a corresponding value to go with it).
# Use -gt 0 to consume one or more arguments per pass in the loop (e.g.
# some arguments don't have a corresponding value to go with it, such as --help ).

# If no arguments are supplied, assume the server needs to be run
if [[ $#  -eq 0 ]]; then
	run_project
fi

# Else, process arguments
echo "Full command: $@"
while [[ $# -gt 0 ]]
do
	key="$1"
	echo "Command: ${key}"

	case ${key} in
		run_project)
			wait_for_db
			run_project
		;;
		run_migrations)
			wait_for_db
			run_migrations
		;;
		help|-h)
			display_help
		;;
		*)
            cd_app_folder
			"$@"
			exit 0
		;;
	esac
	shift # next argument or value
done



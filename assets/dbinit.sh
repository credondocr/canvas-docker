#!/bin/bash
set -e

export POSTGRES_BIN=/usr/lib/postgresql/$POSTGRES_VERSION/bin

export CANVAS_LMS_ADMIN_EMAIL="canvas@example.edu"
export CANVAS_LMS_ADMIN_PASSWORD="canvas"
export CANVAS_LMS_ACCOUNT_NAME="Canvas Docker"
export CANVAS_LMS_STATS_COLLECTION="opt_out"

cd /opt/canvas-lms \
    && bundle exec rake db:initial_setup

#!/usr/bin/env bash

load_app_store_connect_env() {
  local env_file="${APP_STORE_CONNECT_ENV_FILE:-}"

  if [ -z "$env_file" ]; then
    if [ -f "$HOME/.config/understood-suite/app-store-connect.env" ]; then
      env_file="$HOME/.config/understood-suite/app-store-connect.env"
    elif [ -f "$ROOT_DIR/.env.appstoreconnect" ]; then
      env_file="$ROOT_DIR/.env.appstoreconnect"
    fi
  fi

  if [ -n "$env_file" ] && [ -f "$env_file" ]; then
    set -a
    # shellcheck disable=SC1090
    . "$env_file"
    set +a
  fi
}

#!/usr/bin/env bash

set -euo pipefail

readonly DEFAULT_CONFIG_FILE="${HOME}/.config/power-monitor-mqtt/config"
readonly CONFIG_FILE="${POWER_MONITOR_MQTT_CONFIG:-$DEFAULT_CONFIG_FILE}"

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

cleanup() {
    local exit_code=$?
    exit "${exit_code}"
}

trap cleanup EXIT
trap 'exit 1' INT TERM HUP

log_info() {
    log -t "$LOG_SUBSYSTEM" -c "$LOG_CATEGORY" "$1"
}

log_error() {
    log -t "$LOG_SUBSYSTEM" -c "$LOG_CATEGORY" -l error "$1"
}

log_debug() {
    log -t "$LOG_SUBSYSTEM" -c "$LOG_CATEGORY" -l debug "$1"
}

check_dependencies() {
    local missing_deps=()
    
    if ! command -v mosquitto_pub >/dev/null 2>&1; then
        missing_deps+=("mosquitto_pub")
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        missing_deps+=("jq")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        echo "ERROR: Missing required dependencies: ${missing_deps[*]}" >&2
        echo "Please install them using: brew install mosquitto jq" >&2
        exit 1
    fi
}

get_power_data() {
    local json_output
    json_output=$("$POWER_MONITOR_PATH" --noGUI --JSON 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        log_error "Failed to get power data from Power Monitor"
        return 1
    fi
    
    log_debug "Power Monitor JSON output: $json_output"
    echo "$json_output"
    return 0
}

extract_json_value() {
    local json="$1"
    local key="$2"
    
    echo "$json" | jq -r ".$key // null"
}

publish_mqtt() {
    local topic="$1"
    local payload="$2"
    local max_retries=3
    local base_delay=1
    
    for attempt in $(seq 1 $max_retries); do
        log_debug "Publishing $payload to $topic (attempt $attempt/$max_retries)"
        
        local result
        result=$(mosquitto_pub -r -t "$topic" \
            -u "$MQTT_USERNAME" -P "$MQTT_PASSWORD" \
            -h "$MQTT_HOST" -p "$MQTT_PORT" \
            -m "$payload" 2>&1)
        
        local exit_code=$?
        if [ $exit_code -eq 0 ]; then
            log_info "Successfully published to $topic"
            return 0
        else
            log_error "Attempt $attempt failed: $result (exit code: $exit_code)"
            if [ $attempt -lt $max_retries ]; then
                local delay=$((base_delay * (2 ** ($attempt - 1))))
                log_info "Retrying in ${delay} seconds..."
                sleep $delay
            fi
        fi
    done
    
    log_error "Failed to publish to $topic after $max_retries attempts"
    return 1
}

process_power_data() {
    local json_data="$1"
    local timestamp=$(date -Iseconds)
    
    local current_power=$(extract_json_value "$json_data" "CurrentPower")
    local average_power=$(extract_json_value "$json_data" "AveragePower")
    local measurements=$(extract_json_value "$json_data" "MeasurementsCount")
    local country_code=$(extract_json_value "$json_data" "CountryCode")
    local precise_location=$(extract_json_value "$json_data" "PreciseLocation")
    local carbon_footprint=$(extract_json_value "$json_data" "CarbonFootprint")
    
    local payload="{\"value\":$current_power,\"unit\":\"W\",\"timestamp\":\"$timestamp\"}"
    publish_mqtt "$TOPIC_PREFIX/$DEVICE_NAME/power/current" "$payload"
    
    payload="{\"value\":$average_power,\"unit\":\"W\",\"timestamp\":\"$timestamp\"}"
    publish_mqtt "$TOPIC_PREFIX/$DEVICE_NAME/power/average" "$payload"
    
    payload="{\"measurements\":$measurements,\"country_code\":\"$country_code\",\"precise_location\":$precise_location,\"carbon_footprint\":\"$carbon_footprint\",\"timestamp\":\"$timestamp\"}"
    publish_mqtt "$TOPIC_PREFIX/$DEVICE_NAME/status" "$payload"
    
    log_info "Power data processed: Current=${current_power}W, Average=${average_power}W"
}

test_power_monitor() {
    log_info "Testing Power Monitor connection..."
    
    if [ ! -f "$POWER_MONITOR_PATH" ]; then
        log_error "Power Monitor app not found at $POWER_MONITOR_PATH"
        exit 1
    fi
    
    local json_data
    json_data=$(get_power_data)
    
    if [ $? -eq 0 ]; then
        log_info "Power Monitor test successful:"
        echo "$json_data"
        return 0
    else
        log_error "Power Monitor test failed"
        return 1
    fi
}

run_once() {
    log_info "Running power monitor once..."
    
    local json_data
    json_data=$(get_power_data)
    
    if [ $? -eq 0 ]; then
        process_power_data "$json_data"
        log_info "Power data published successfully"
        return 0
    else
        log_error "Failed to get power data"
        return 1
    fi
}

run_continuous() {
    log_info "Starting continuous power monitoring (interval: ${INTERVAL}s)"
    
    while true; do
        local json_data
        json_data=$(get_power_data)
        
        if [ $? -eq 0 ]; then
            process_power_data "$json_data"
        else
            log_error "Failed to get power data, retrying in next interval"
        fi
        
        sleep "$INTERVAL"
    done
}

show_config() {
    echo "Current configuration:"
    echo "  Config file: $CONFIG_FILE"
    echo "  Power Monitor path: $POWER_MONITOR_PATH"
    echo "  MQTT host: $MQTT_HOST"
    echo "  MQTT port: $MQTT_PORT"
    echo "  MQTT user: $MQTT_USER"
    echo "  Topic prefix: $TOPIC_PREFIX"
    echo "  Device name: $DEVICE_NAME"
    echo "  Interval: ${INTERVAL}s"
    echo "  Log subsystem: $LOG_SUBSYSTEM"
    echo "  Log category: $LOG_CATEGORY"
}

main() {
    check_dependencies
    
    case "${1:-}" in
        --test)
            test_power_monitor
            exit $?
            ;;
        --once)
            run_once
            exit $?
            ;;
        --config)
            show_config
            exit 0
            ;;
        --help)
            echo "Usage: $0 [--test|--once|--config|--help]"
            echo "  --test    Test power monitor connection and output"
            echo "  --once    Run once and exit"
            echo "  --config  Show current configuration"
            echo "  --help    Show this help"
            echo "  (no args) Run continuously"
            echo ""
            echo "Configuration:"
            echo "  Set POWER_MONITOR_MQTT_CONFIG environment variable to use custom config file"
            echo "  Default config file: $DEFAULT_CONFIG_FILE"
            exit 0
            ;;
        "")
            run_continuous
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
}

main "$@"

# Power Monitor MQTT Publisher for macOS

A script that retrieves power value (W) from the SAP Power Monitor app for macOS and publishes it to an MQTT broker.

## Features

- Power value (W) retrieval from SAP Power Monitor
- Automatic MQTT publishing
- Test mode, single-run mode, and continuous monitoring mode

## Requirements

- [SAP Power Monitor](https://github.com/SAP/power-monitoring-tool-for-macos)
- [Homebrew](https://brew.sh/)

## Installation

### Prerequisites

#### Install SAP Power Monitor:

1. Visit the [SAP Power Monitor releases page](https://github.com/SAP/power-monitoring-tool-for-macos/releases)
2. Download the latest `.pkg` file
3. Install the downloaded file

#### Install Homebrew

1. Visit the [Homebrew page](https://brew.sh/)
2. Copy the installation command and run it in your terminal

### Automatic Installation (Recommended)

1. Clone the repository:
```bash
git clone git@github.com:rewse/power-monitor-mqtt.git
cd power-monitor-mqtt
```

2. Install dependencies:
This will install `mosquitto` and `jq`.
```bash
make deps
```

3. Install the script:
The script will be installed to `~/.local/bin` and configuration files to `~/.config/power-monitor-mqtt`.
```bash
make install
```

4. Edit the configuration file:
```bash
vim ~/.config/power-monitor-mqtt/config
```

#### Makefile Commands

Available Makefile commands:

```bash
make help         # Show help message
make deps         # Install dependencies (mosquitto, jq)
make install      # Install script and config file
make test         # Run script in test mode
make clean        # Remove config file
make uninstall    # Remove installed script
```

### Manual Installation

**Note**: Make sure you have completed the Prerequisites section above before proceeding.

1. Clone the repository:
```bash
git clone git@github.com:rewse/power-monitor-mqtt.git
cd power-monitor-mqtt
```

2. Install dependencies manually:
```bash
brew install mosquitto jq
```

3. Create configuration file:
```bash
mkdir -p ~/.config/power-monitor-mqtt
cp config.example ~/.config/power-monitor-mqtt/config
```

4. Edit the configuration file:
```bash
vim ~/.config/power-monitor-mqtt/config
```

## Configuration

Configure the following items in the configuration file (`~/.config/power-monitor-mqtt/config`):

- `MQTT_HOST`: MQTT broker hostname
- `MQTT_PORT`: MQTT broker port (default: `1883`)
- `MQTT_USERNAME`: MQTT authentication username (default: `pub_client`)
- `MQTT_PASSWORD`: MQTT authentication password
- `TOPIC_PREFIX`: MQTT topic prefix (default: `power-monitor`)
- `DEVICE_NAME`: Device name (default: Mac's *hostname*)
- `INTERVAL`: Data transmission interval for continuous mode (default: `60` seconds)

## Usage

### Test Mode

Retrieves data from SAP Power Monitor only, without sending to MQTT broker.

```bash
./power-monitor-mqtt.sh --test
```

### Single Run

Sends power value to MQTT broker once. Use with helper tool like Keyboard Maestro, LaunchAgent, or cron for periodic execution.

```bash
./power-monitor-mqtt.sh --once
```

### Continuous Mode

Runs persistently at INTERVAL intervals.

```bash
./power-monitor-mqtt.sh
```

### Show Configuration
```bash
./power-monitor-mqtt.sh --config
```

## MQTT Topics

The script publishes data to the following topics:

- `{TOPIC_PREFIX}/{DEVICE_NAME}/power/current` - Power value (W)
- `{TOPIC_PREFIX}/{DEVICE_NAME}/power/average` - Average power value (W)
- `{TOPIC_PREFIX}/{DEVICE_NAME}/status` - Status information

### Data Format

#### Power value (current / average)
```json
{
  "value": 45.2,
  "unit": "W",
  "timestamp": "2024-12-16T16:30:00+09:00"
}
```

#### Status Information

```json
{
  "measurements": 150,
  "country_code": "unknown",
  "precise_location": false,
  "carbon_footprint": -1,
  "timestamp": "2024-12-16T16:30:00+09:00"
}
```
**Note**: As of now, `country_code`, `precise_location`, and `carbon_footprint` do not return correct values from SAP Power Monitor.

## Log Viewing

Logs are written to `~/Library/Logs/power-monitor-mqtt/power-monitor-mqtt.log` by default. The log file is automatically rotated when it reaches the maximum size.

## Periodic Execution Setup Example

### Using Keyboard Maestro

#### Import Pre-configured Macro

1. Download [Execute-power-monitor-mqtt.kmmacros](https://github.com/rewse/power-monitor-mqtt/blob/main/Execute-power-monitor-mqtt.kmmacros)
2. Open Keyboard Maestro
3. Import the macro:
   - Go to `File > Import > Import Macros Safely...`
   - Select the downloaded `.kmmacros` file
4. Review and adjust the interval if needed
#### Manual Setup

1. Open Keyboard Maestro
2. Create a new macro with a descriptive name (e.g., "Execute power-monitor-mqtt")
3. Set the trigger:
   - Type: "Periodically while logged in"
   - Interval: "Repeating every 1 Minutes" (adjust as needed)
4. Add an action:
   - Type: "Execute a Shell Script"
   - Script content: `PATH=/opt/homebrew/bin:$PATH ~/.local/bin/power-monitor-mqtt.sh --once`
5. Save the macro

![Keyboard Meastro Configuration](https://github.com/rewse/power-monitor-mqtt/blob/main/docs/keyboard-maestro.png)

**Note**: The `PATH` environment variable must include `/opt/homebrew/bin` (or `/usr/local/bin` for Intel Macs) to ensure `mosquitto_pub` and `jq` commands are accessible.

## Home Assistant Integration

Example configuration for Home Assistant:

### MQTT Sensor Configuration
```yaml
mqtt:
  sensor:
    - name: "My Mac Power Current"
      state_topic: "power-monitor/my-mac/power/current"
      value_template: "{{ value_json.value }}"
      unit_of_measurement: "W"
      device_class: power
      
    - name: "My Mac Power Average"
      state_topic: "power-monitor/my-mac/power/average"
      value_template: "{{ value_json.value }}"
      unit_of_measurement: "W"
      device_class: power
```

### Power Measurement Accuracy Note

**Important**: The power values reported by macOS internal sensors are typically 15-25% lower than actual AC power consumption measured by external devices (smart plugs, power meters). This difference is due to:

- **AC-DC conversion efficiency**: Power adapter losses (10-20%)
- **Internal power conversion**: Motherboard and component efficiency losses
- **Measurement scope**: Internal sensors may not account for all components and external devices
- **Measurement methodology**: Internal values are often estimates based on component usage

For more accurate power consumption calculations (e.g., electricity cost estimation), consider using a correction factor.

### Corrected Power Sensor (20% Increase)
```yaml
sensor:
  - name: "My Mac Power Current Corrected"
    unit_of_measurement: "W"
    device_class: power
    state: "{{ (states('sensor.my_mac_power_current') | float * 1.2) | round(1) }}"
    
  - name: "My Mac Power Average Corrected"
    unit_of_measurement: "W"
    device_class: power
    state: "{{ (states('sensor.my_mac_power_average') | float * 1.2) | round(1) }}"
```

### Power Consumption (kWh) Calculation with [Integral Sensor](https://www.home-assistant.io/integrations/integration/)
```yaml
sensor:
  # Using raw internal sensor values
  - platform: integration
    source: sensor.my_mac_power_current
    name: My Mac Energy Total Internal
    unit_prefix: k
    round: 6
    method: trapezoidal
    max_sub_interval:
      minutes: 5
      
  # Using corrected values for more accurate consumption
  - platform: integration
    source: sensor.my_mac_power_current_corrected
    name: My Mac Energy Total Corrected
    unit_prefix: k
    round: 6
    method: trapezoidal
    max_sub_interval:
      minutes: 5
```

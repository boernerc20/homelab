# Home Assistant Integration Guide

## Overview

This guide covers integrating your local AI workstation with Home Assistant for:
- Local voice assistant (speech-to-text and text-to-speech)
- Conversation AI using local LLMs
- Home automation with natural language
- Image generation integration
- Custom automations and scripts

## Architecture

```
Home Assistant
     │
     ├─► Whisper (Speech-to-Text) ──┐
     ├─► Piper (Text-to-Speech)      │
     ├─► Ollama (LLM Conversation)   ├─► AI Workstation
     └─► ComfyUI (Image Generation)  │
                                      │
     Voice Command ──► Text ──► LLM ──► Action
```

## Prerequisites

1. Home Assistant installed (2023.5 or later recommended)
2. AI Workstation running with Docker containers
3. Network connectivity between HA and AI workstation
4. HACS (Home Assistant Community Store) installed

## Step 1: Install Required Integrations

### A. Wyoming Protocol Integration (Built-in)

Home Assistant 2023.5+ includes native support for Wyoming protocol used by Whisper and Piper.

**Configuration:**

1. Go to **Settings** → **Devices & Services** → **Add Integration**
2. Search for "Wyoming Protocol"
3. Add Whisper ASR:
   - Host: `ai-workstation-ip`
   - Port: `9000`

4. Add Piper TTS:
   - Host: `ai-workstation-ip`
   - Port: `10200`

### B. Ollama/LLM Integration

#### Option 1: Extended OpenAI Conversation (Recommended)

```bash
# Install via HACS
# 1. Go to HACS → Integrations
# 2. Search for "Extended OpenAI Conversation"
# 3. Install and restart HA
```

**Configuration (configuration.yaml):**

```yaml
# Configure Ollama as OpenAI-compatible endpoint
conversation:
  extended_openai_conversation:
    - name: "Local Ollama"
      api_key: "not-needed"
      base_url: "http://ai-workstation-ip:11434/v1"
      model: "llama3.1:8b"
      context_threshold: 20000
      max_tokens: 2000
      temperature: 0.7
      top_p: 0.9
```

#### Option 2: Local LLM Conversation (Custom)

Create a custom integration using REST API.

**configuration.yaml:**

```yaml
rest_command:
  ollama_chat:
    url: "http://ai-workstation-ip:11434/api/generate"
    method: POST
    headers:
      Content-Type: "application/json"
    payload: >
      {
        "model": "{{ model }}",
        "prompt": "{{ prompt }}",
        "stream": false
      }
    content_type: "application/json"
```

## Step 2: Configure Voice Assistant

### Create Voice Assistant Pipeline

1. Go to **Settings** → **Voice Assistants**
2. Click **Add Assistant**
3. Configure:
   - **Name**: "Local AI Assistant"
   - **Conversation Agent**: "Extended OpenAI Conversation (Local Ollama)"
   - **Speech-to-Text**: "Whisper"
   - **Text-to-Speech**: "Piper"
   - **Wake Word**: (optional, if using wake word detection)

### Test Voice Assistant

Use Home Assistant mobile app or ESPHome voice assistant hardware to test.

## Step 3: Create Conversation Intents

### Custom Intents (configuration.yaml)

```yaml
conversation:
  intents:
    TurnOnLights:
      - "turn on the [lights] in the [room]"
      - "turn [room] lights on"

    TurnOffLights:
      - "turn off the [lights] in the [room]"
      - "turn [room] lights off"

    SetTemperature:
      - "set [room] temperature to [degrees]"
      - "make it [temperature_description]"

    GenerateImage:
      - "generate an image of [description]"
      - "create a picture of [description]"

intent_script:
  TurnOnLights:
    speech:
      text: "Turning on {{ room }} lights"
    action:
      service: light.turn_on
      target:
        entity_id: "light.{{ room }}"

  TurnOffLights:
    speech:
      text: "Turning off {{ room }} lights"
    action:
      service: light.turn_off
      target:
        entity_id: "light.{{ room }}"

  GenerateImage:
    speech:
      text: "Generating image, this will take a moment"
    action:
      service: rest_command.comfyui_generate
      data:
        prompt: "{{ description }}"
```

## Step 4: ComfyUI Integration

### REST Command for Image Generation

**configuration.yaml:**

```yaml
rest_command:
  comfyui_generate:
    url: "http://ai-workstation-ip:8188/prompt"
    method: POST
    headers:
      Content-Type: "application/json"
    payload: >
      {
        "prompt": {
          "3": {
            "class_type": "KSampler",
            "inputs": {
              "seed": {{ range(1, 1000000) | random }},
              "steps": 20,
              "cfg": 7,
              "sampler_name": "euler",
              "scheduler": "normal",
              "denoise": 1,
              "model": ["4", 0],
              "positive": ["6", 0],
              "negative": ["7", 0],
              "latent_image": ["5", 0]
            }
          },
          "6": {
            "class_type": "CLIPTextEncode",
            "inputs": {
              "text": "{{ prompt }}",
              "clip": ["4", 1]
            }
          }
        }
      }
```

### Notification with Generated Image

```yaml
automation:
  - alias: "Send Generated Image"
    trigger:
      platform: state
      entity_id: sensor.comfyui_status
      to: "completed"
    action:
      - service: notify.mobile_app
        data:
          title: "Image Generated"
          message: "Your image is ready"
          data:
            image: "http://ai-workstation-ip:8188/view?filename={{ states('sensor.comfyui_last_image') }}"
```

## Step 5: Advanced LLM Integration

### Context-Aware Home Control

Create an automation that provides home state context to the LLM:

```yaml
automation:
  - alias: "LLM Context Update"
    trigger:
      - platform: time_pattern
        minutes: "/5"  # Update every 5 minutes
    action:
      - service: input_text.set_value
        target:
          entity_id: input_text.home_context
        data:
          value: >
            Current home status:
            - Temperature: {{ states('sensor.living_room_temperature') }}°F
            - Humidity: {{ states('sensor.living_room_humidity') }}%
            - Lights on: {{ states.light | selectattr('state', 'eq', 'on') | list | count }}
            - Doors open: {{ states.binary_sensor | selectattr('attributes.device_class', 'eq', 'door') | selectattr('state', 'eq', 'on') | list | count }}
            - Current time: {{ now().strftime('%I:%M %p') }}
            - Active automations: {{ states.automation | selectattr('state', 'eq', 'on') | list | count }}
```

### LLM-Powered Automation Suggestions

```yaml
automation:
  - alias: "Daily Automation Suggestion"
    trigger:
      - platform: time
        at: "09:00:00"
    action:
      - service: rest_command.ollama_chat
        data:
          model: "llama3.1:8b"
          prompt: >
            Based on my home data from the last 24 hours:
            {{ state_attr('sensor.home_statistics', 'summary') }}

            Suggest 3 useful automations I could create.
        response_variable: llm_response

      - service: notify.persistent_notification
        data:
          title: "AI Automation Suggestions"
          message: "{{ llm_response.response }}"
```

## Step 6: ESPHome Voice Assistant Hardware

### Create Voice Assistant Device

**Example ESPHome Configuration (esp32-s3-box or atom-echo):**

```yaml
esphome:
  name: voice-assistant
  friendly_name: Voice Assistant

esp32:
  board: esp32-s3-box
  framework:
    type: arduino

# Enable voice assistant
voice_assistant:
  microphone: mic
  speaker: speaker
  use_wake_word: true

  on_listening:
    - light.turn_on:
        id: led
        blue: 100%
        red: 0%
        green: 0%
        brightness: 50%

  on_stt_end:
    - light.turn_off: led

  on_tts_start:
    - light.turn_on:
        id: led
        blue: 0%
        red: 0%
        green: 100%
        brightness: 50%

  on_end:
    - light.turn_off: led

# Configure I2S microphone
microphone:
  - platform: i2s_audio
    id: mic
    adc_type: external
    i2s_din_pin: GPIO16
    pdm: false

# Configure I2S speaker
speaker:
  - platform: i2s_audio
    id: speaker
    dac_type: external
    i2s_dout_pin: GPIO17

# LED indicator
light:
  - platform: neopixelbus
    id: led
    type: GRB
    pin: GPIO21
    num_leds: 1
```

## Step 7: Web Search Integration

### Toggle Web Search Based on Query

```yaml
script:
  smart_assistant_query:
    sequence:
      # Analyze if query needs internet
      - service: rest_command.ollama_chat
        data:
          model: "llama3.1:8b"
          prompt: >
            Does this query require current internet information? Answer only YES or NO.
            Query: {{ query }}
        response_variable: needs_internet

      # Route to appropriate endpoint
      - choose:
          # If needs internet, use Open-WebUI with search enabled
          - conditions:
              - condition: template
                value_template: "{{ 'YES' in needs_internet.response }}"
            sequence:
              - service: rest_command.open_webui_query
                data:
                  prompt: "{{ query }}"
                  use_web_search: true

        # Otherwise use local Ollama
        default:
          - service: rest_command.ollama_chat
            data:
              model: "llama3.1:8b"
              prompt: "{{ query }}"
```

## Step 8: Automation Examples

### 1. Morning Briefing with AI

```yaml
automation:
  - alias: "AI Morning Briefing"
    trigger:
      - platform: time
        at: "07:00:00"
    condition:
      - condition: state
        entity_id: binary_sensor.workday
        state: "on"
    action:
      # Gather context
      - service: rest_command.ollama_chat
        data:
          model: "llama3.1:8b"
          prompt: >
            Create a brief morning summary based on this data:
            - Weather: {{ states('weather.home') }}
            - Temperature: {{ states('sensor.outdoor_temperature') }}°F
            - Calendar events today: {{ state_attr('calendar.personal', 'message') }}
            - Commute time: {{ states('sensor.waze_travel_time') }} minutes

            Format as a friendly 30-second spoken briefing.
        response_variable: briefing

      # Speak briefing
      - service: tts.speak
        target:
          entity_id: tts.piper
        data:
          message: "{{ briefing.response }}"
          media_player_entity_id: media_player.bedroom_speaker
```

### 2. Energy Usage Analysis

```yaml
automation:
  - alias: "Weekly Energy Analysis"
    trigger:
      - platform: time
        at: "18:00:00"
      - condition: template
        value_template: "{{ now().weekday() == 6 }}"  # Sunday
    action:
      - service: rest_command.ollama_chat
        data:
          model: "llama3.1:8b"
          prompt: >
            Analyze this week's energy usage and provide insights:
            {{ states('sensor.weekly_energy_kwh') }} kWh used
            Peak usage: {{ state_attr('sensor.energy_usage', 'peak_time') }}
            Compare to last week: {{ states('sensor.last_week_energy_kwh') }} kWh

            Provide 3 specific tips to reduce energy consumption.
        response_variable: analysis

      - service: notify.mobile_app
        data:
          title: "Weekly Energy Report"
          message: "{{ analysis.response }}"
```

### 3. Contextual Lighting with AI

```yaml
automation:
  - alias: "AI Lighting Suggestions"
    trigger:
      - platform: sun
        event: sunset
    action:
      - service: rest_command.ollama_chat
        data:
          model: "llama3.1:8b"
          prompt: >
            Current situation:
            - Time: {{ now().strftime('%I:%M %p') }}
            - Weather: {{ states('weather.home') }}
            - People home: {{ states('sensor.people_home') }}
            - Activity: {{ states('sensor.current_activity') }}

            Suggest optimal lighting scene and explain why.
        response_variable: suggestion

      - service: notify.persistent_notification
        data:
          message: "{{ suggestion.response }}"
```

## Step 9: Security & Performance

### Rate Limiting

```yaml
# Prevent API abuse
input_boolean:
  llm_rate_limit:
    name: "LLM Rate Limit Active"
    initial: false

automation:
  - alias: "LLM Rate Limit Reset"
    trigger:
      - platform: state
        entity_id: input_boolean.llm_rate_limit
        to: "on"
    action:
      - delay: "00:01:00"  # 1 minute cooldown
      - service: input_boolean.turn_off
        entity_id: input_boolean.llm_rate_limit
```

### Monitor AI Services

```yaml
# Check service health
rest:
  - resource: "http://ai-workstation-ip:11434/api/tags"
    scan_interval: 60
    sensor:
      - name: "Ollama Status"
        value_template: >
          {% if value_json.models is defined %}
            Online - {{ value_json.models | length }} models
          {% else %}
            Offline
          {% endif %}
```

## Troubleshooting

### Common Issues

1. **Voice assistant not responding**
   - Check Wyoming service logs
   - Verify network connectivity
   - Test microphone with ESPHome logs

2. **LLM responses slow**
   - Check GPU utilization on AI workstation
   - Consider smaller/faster models
   - Implement request queuing

3. **Context too large errors**
   - Reduce conversation history
   - Summarize previous context with LLM
   - Use smaller context window models

### Useful Commands

```bash
# Check Ollama logs
docker logs ollama -f

# Test Ollama API
curl http://ai-workstation-ip:11434/api/generate -d '{
  "model": "llama3.1:8b",
  "prompt": "Hello"
}'

# Check Whisper service
curl http://ai-workstation-ip:9000/health

# Monitor GPU usage
nvidia-smi -l 1
```

## Next Steps

1. Test basic voice commands
2. Create custom intents for your specific needs
3. Train wake word (if using)
4. Create useful automations
5. Monitor performance and adjust models as needed
6. Explore RAG (Retrieval Augmented Generation) for home documentation

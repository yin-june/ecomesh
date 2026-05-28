import paho.mqtt.client as mqtt
import logging
import json
from services.influx_service import influx_service

logger = logging.getLogger(__name__)

class IoTGatewayBridge:
    """Manages MQTT connections for bidirectional communication with the ESP32 Hub."""
    def __init__(self):
        self.broker = "broker.hivemq.com" # Public broker for hackathon prototype
        self.port = 1883
        self.client = mqtt.Client(client_id="EcoMesh_Backend_Main")
        self.client.on_connect = self.on_connect
        self.client.on_message = self.on_message
        
    def on_connect(self, client, userdata, flags, rc):
        logger.info(f"Connected to MQTT Broker with result code {rc}")
        # Subscribe to all telemetry topics
        self.client.subscribe("ecomesh/zones/+/telemetry")
        
    def on_message(self, client, userdata, msg):
        try:
            # Topic format: ecomesh/zones/{zone_id}/telemetry
            parts = msg.topic.split("/")
            if len(parts) >= 4:
                zone_id = parts[2]
                payload = json.loads(msg.payload.decode())
                
                if payload.get("type") == "occupancy":
                    influx_service.write_occupancy(zone_id, payload)
                elif payload.get("type") == "power":
                    influx_service.write_power(zone_id, payload)
        except Exception as e:
            logger.error(f"Error processing MQTT message: {e}")

    def connect(self):
        try:
            self.client.connect(self.broker, self.port, 60)
            self.client.loop_start()
        except Exception as e:
            logger.error(f"MQTT Connection Failed: {e}")

    def disconnect(self):
        self.client.loop_stop()
        self.client.disconnect()

    def override_zone_ac(self, zone_id: str, target_temp: int, mode: str):
        """Sends the predictive AI's AC command to the physical ESP32."""
        topic = f"ecomesh/zones/{zone_id}/command"
        payload = json.dumps({"device": "AC", "temp": target_temp, "mode": mode})
        
        self.client.publish(topic, payload)
        logger.info(f"Dispatched IoT Command -> {topic}: {payload}")

mqtt_bridge = IoTGatewayBridge()
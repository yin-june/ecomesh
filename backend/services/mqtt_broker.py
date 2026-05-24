import paho.mqtt.client as mqtt
import logging
import json

logger = logging.getLogger(__name__)

class IoTGatewayBridge:
    """Manages MQTT connections to send downstream commands to the ESP32 Hub."""
    def __init__(self):
        self.broker = "broker.hivemq.com" # Public broker for hackathon prototype
        self.port = 1883
        self.client = mqtt.Client(client_id="EcoMesh_Backend_Main")
        
    def connect(self):
        try:
            self.client.connect(self.broker, self.port, 60)
            self.client.loop_start()
            logger.info(f"Connected to MQTT Broker at {self.broker}")
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
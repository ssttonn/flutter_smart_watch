enum ConnectionState { connected, disconnected }

enum WearEnginePermission {
  deviceManager,
  notify,
  sensor,
  motionSensor,
  wearUserStatus
}

enum DeviceCapabilityStatus { supported, unsupported, unknown }

enum MonitorItem {
  connection,
  wear,
  sleep,
  lowPower,
  sport,
  powerStatus,
  chargeStatus,
  heartRateAlarm,
  availableKBytes
}

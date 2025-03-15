{ lib, ... }:

let
  users = [
    {
      name = "Steven Seagal";
      topic = "StevenSeagal";
    }
    {
      name = "Ophelia Moore";
      topic = "OpheliaMoore";
    }
  ];

  generateBinarySensors = user: [
    {
      name = "FFXIV | ${user.name} | Online";
      state_topic = "ffxiv/${user.topic}/Event/Login";
      value_template = "{{ value_json.LoggedIn }}";
      icon = "mdi:account-badge";
      payload_on = true;
      payload_off = false;
      device_class = "connectivity";
    }
    {
      name = "FFXIV | ${user.name} | In Combat";
      state_topic = "ffxiv/${user.topic}/Player/Conditions/InCombat";
      value_template = "{{ value_json.Active }}";
      icon = "mdi:sword-cross";
      payload_on = true;
      payload_off = false;
      device_class = "safety";
    }
  ];

  generateSensors = user: [
    {
      name = "FFXIV | ${user.name} | Character";
      state_topic = "ffxiv/${user.topic}/Event/Login";
      value_template = "{{ value_json.Character }}";
      icon = "mdi:account-badge";
    }
    {
      name = "FFXIV | ${user.name} | HP";
      state_topic = "ffxiv/${user.topic}/Player/Combat/Stats";
      value_template = "{{ value_json.HP }}";
      unit_of_measurement = "HP";
      icon = "mdi:heart";
    }
    {
      name = "FFXIV | ${user.name} | MP";
      state_topic = "ffxiv/${user.topic}/Player/Combat/Stats";
      value_template = "{{ value_json.MP }}";
      unit_of_measurement = "MP";
      icon = "mdi:water";
    }
    {
      name = "FFXIV | ${user.name} | Current Zone";
      state_topic = "ffxiv/${user.topic}/Event/TerritoryChanged";
      value_template = "{{ value_json.Name }} ({{ value_json.Region }})";
      icon = "mdi:map-marker";
    }
  ];
in {
  services.home-assistant.config.mqtt = {
    binary_sensor = lib.concatMap generateBinarySensors users;
    sensor = lib.concatMap generateSensors users;
  };
}

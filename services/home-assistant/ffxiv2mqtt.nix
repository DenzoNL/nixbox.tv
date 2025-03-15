{ lib, ... }:

let
  users = [
    {
      name = "Steven Seagal";
      topic = "StevenSeagal";
      slug = "steven_seagal";
    }
    {
      name = "Ophelia Moore";
      topic = "OpheliaMoore";
      slug = "ophelia_moore";
    }
  ];


  generateMqttBinarySensors = user: [
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

  generateMqttSensors = user: [
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
    {
      name = "FFXIV | ${user.name} | Max HP";
      state_topic = "ffxiv/${user.topic}/Player/Info";
      value_template = "{{ value_json.MaxHP }}";
      unit_of_measurement = "HP";
      icon = "mdi:heart";
    }
    {
      name = "FFXIV | ${user.name} | Level";
      state_topic = "ffxiv/${user.topic}/Player/Info";
      value_template = "{{ value_json.Level }}";
      icon = "mdi:sword";
    }
    {
      name = "FFXIV | ${user.name} | Job";
      state_topic = "ffxiv/${user.topic}/Player/Info";
      value_template = ''{{ value_json.Class }}'';
      icon = "mdi:sword";
    }
    {
      name = "FFXIV | ${user.name} | Role";
      state_topic = "ffxiv/${user.topic}/Player/Info";
      value_template = ''
        {{ 
          {"PLD": "Tank", "WAR": "Tank", "DRK": "Tank", "GNB": "Tank",
          "WHM": "Healer", "SCH": "Healer", "AST": "Healer", "SGE": "Healer",
          "MNK": "DPS", "DRG": "DPS", "NIN": "DPS", "SAM": "DPS", "VPR": "DPS",
          "BRD": "DPS", "MCH": "DPS", "DNC": "DPS",
          "BLM": "DPS", "SMN": "DPS", "RDM": "DPS", "BLU": "DPS", "PIC": "DPS"
          }.get(value_json.Class, "Unknown") 
        }}
      '';
      icon = "mdi:sword";
    }
  ];

  generateTemplateSensors = user: [
    {
      name = "FFXIV | ${user.name} | HP Percentage";
      unit_of_measurement = "%";
      state = ''
        {% set hp = states('sensor.ffxiv_${user.slug}_hp') | float(0) %}
        {% set max_hp = states('sensor.ffxiv_${user.slug}_max_hp') | float(1) %}
        {% if max_hp > 0 %}
          {{ (hp / max_hp * 100) | round(1) }}
        {% else %}
          0
        {% endif %}
      '';
      icon = ''
        {{ 
          "mdi:heart" if (states('sensor.ffxiv_${user.slug}_hp') | float(0)) > 0 
          else "mdi:heart-off" 
        }}
      '';
    }
  ];
in {
  services.home-assistant.config = {
    mqtt = {
      binary_sensor = lib.concatMap generateMqttBinarySensors users;
      sensor = lib.concatMap generateMqttSensors users;
    };
    template = {
      sensor = lib.concatMap generateTemplateSensors users;
    };
  };
}

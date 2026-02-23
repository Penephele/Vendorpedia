This is a brief description of Vendorpedia.

It is a World of Warcraft add-on designed to help users find items sold by vendors, such as reagents for professions or ingredients for cooking.
The user enters search terms either by typing manually or shift-clicking an item from a bag or other frame.
The results pane displays matches along with distance to the closest vendor and the expected price.
Clicking a search result item brings up a details pane with vendor name, zone, etc. If the user has TomTom installed and enabled, a button can be clicked to get a waypoint.

A quick explanation of each file:

ui.lua = all the main code, creates the UI, and all the necessary functions

data.lua = holds some test data from scanning NPCs; this will eventually hold all the real data

factions.lua = faction IDs for easier lookups when calculating prices

(It is worth noting that we gather faction standings to calculate the base (neutral) price, and then use that value to calculate what the user will pay.)

A separate scanning add-on already exists for collecting vendor and item data. Sample vendor table:

VPAMerchants = {
  [1213] = {
    ["map"] = {
      ["y"] = -8898,
      ["x"] = -119,
      ["areaName"] = "Northshire Valley",
      ["zoneName"] = "Northshire",
      ["continentID"] = 0,
      ["zoneMapID"] = 425,
    },
    ["notes"] = "",
    ["name"] = "Godric Rothgar",
    ["repair"] = true,
    ["items"] = {
      [2385] = true,
      [2379] = true,
      [2380] = true,
      [2381] = true,
      [2384] = true,
      [2383] = true,
      [17184] = true,
      [2129] = true,
    },
    ["factionID"] = 72,
  }
}

Sample item table:

VPAItems = {
  [2379] = {
    ["stackSize"] = 1,
    ["name"] = "Tarnished Chain Vest",
    ["link"] = "|cnIQ1:|Hitem:2379::::::::80:270::14::1:28:73:::::|h[Tarnished Chain Vest]|h|r",
    ["price"] = {
      ["copper"] = 24,
    },
    ["vendors"] = {
      [1213] = true,
    },
    ["icon"] = 132624,
    ["available"] = -1,
  }
}

When responding or giving feedback, please keep information to a minimum. No need to over-explain things. This is mainly to keep chat sessions going as long as possible before the browser gets laggy and a new session must be started.
